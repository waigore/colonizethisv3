/// Per-category order validation pipeline for [OrderEngine].
///
/// Promoted from a `part of 'order_engine.dart'` fragment to a standalone
/// library with explicit imports (Refs #3543 — de-part-file orders; the
/// extraction-shape policy in `SPEC/program/dart-file-non-comment-line-size.md`
/// § Extraction shape requires standalone libraries rather than part
/// fragments). The engine now imports this library and calls
/// [runOrderValidationPhases]; nothing here imports `order_engine.dart`, so the
/// orders `lib/` import graph stays acyclic.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';

import 'order_effects_projector.dart';
import 'order_resolution_context.dart';
import 'order_validator_factory.dart';
import 'validator_bundle.dart';

/// Appends one [OrderValidationResult] per order; short-circuits when [rejected].
/// Returns the new rejected flag (true if any result was rejected).
bool _appendValidationResults<T>(
  List<OrderValidationResult> results,
  List<T> orders,
  bool rejected,
  OrderValidationResult Function(T order, bool previousRejected) validate,
) {
  var r = rejected;
  for (final o in orders) {
    final res = validate(o, r);
    results.add(res);
    if (!res.isAccepted) r = true;
  }
  return r;
}

/// Like [_appendValidationResults] for validators that also return updated state (e.g. treasury).
/// Appends each result to [results], propagates [rejected], and returns (rejected, finalState).
({bool rejected, S state}) _appendValidationResultsWithState<T, S>(
  List<OrderValidationResult> results,
  List<T> orders,
  bool rejected,
  S initialState,
  ({OrderValidationResult result, S state}) Function(
    T order,
    bool previousRejected,
  )
  validate,
) {
  var r = rejected;
  var s = initialState;
  for (final o in orders) {
    final res = validate(o, r);
    results.add(res.result);
    if (!res.result.isAccepted) r = true;
    s = res.state;
  }
  return (rejected: r, state: s);
}

/// Canonical, declarative per-category validation phase plan: the phase [name]
/// plus whether the validator bundle is rebuilt **before** the phase runs.
///
/// The plan is static and input-independent so the phase ordering and
/// bundle-refresh contract (Refs #2391 AC7; SPEC/program/order-engine.md
/// § Validation pipeline) is unit-testable on its own.
/// [runOrderValidationPhases] pairs each entry, in order, with the closure that
/// runs it; the move + army-move phases share the initial bundle (no refresh),
/// every resource/diplomatic/naval phase refreshes so incremental
/// stockpile/treasury/diplomatic state matches resolution ordering, and the
/// trade phase runs last against the already-advanced bundle.
const List<({String name, bool refreshBundleBefore})> orderValidationPhasePlan =
    <({String name, bool refreshBundleBefore})>[
      (name: 'move', refreshBundleBefore: false),
      (name: 'army-move', refreshBundleBefore: false),
      (name: 'recruit-worker', refreshBundleBefore: true),
      (name: 'build', refreshBundleBefore: true),
      (name: 'work', refreshBundleBefore: true),
      (name: 'diplomatic', refreshBundleBefore: true),
      (name: 'naval', refreshBundleBefore: true),
      (name: 'trade', refreshBundleBefore: false),
    ];

/// Runs one resource-ledger phase: appends one [OrderValidationResult] per
/// order from [validate], then carries the worker pool / stockpile / treasury
/// the validator advanced back into [state] via [carryForwardLedgers].
///
/// Collapses the structurally identical recruit-worker / build / work phases,
/// which differ only in which validator runs and which ledgers it carries
/// forward (recruit & build advance the worker pool; work does not). Behaviour
/// is unchanged: it is the former `_runRecruitWorkerPhase` / `_runBuildPhase` /
/// `_runWorkPhase` template parameterised by the validator and pull-back.
void _runResourceLedgerPhase<T>(
  OrderValidators v,
  OrderValidationRunState state,
  List<T> orders,
  OrderValidationResult Function(
    OrderValidators v,
    T order,
    bool previousRejected,
  )
  validate,
  void Function(OrderValidators v, OrderValidationRunState state)
  carryForwardLedgers,
) {
  state.rejected = _appendValidationResults(
    state.results,
    orders,
    state.rejected,
    (o, prev) => validate(v, o, prev),
  );
  carryForwardLedgers(v, state);
}

/// Mutable state threaded through [runOrderValidationPhases].
/// Holds the running rejected flag, treasury, stockpile, worker pool, and
/// the accumulated [OrderValidationResult] list. Existing only inside
/// [OrderEngine.validatePlayerOrdersWithContext]'s call stack.
class OrderValidationRunState {
  OrderValidationRunState({
    required this.results,
    required this.stockpile,
    required this.treasury,
    required this.workerPool,
  });

  final List<OrderValidationResult> results;
  bool rejected = false;
  Stockpile stockpile;
  int treasury;
  WorkerPool workerPool;
}

/// Build and run the per-category validation phases for one player.
/// Mutates [state] (results / rejected / stockpile / treasury / workerPool)
/// in submission order: move, army-move, recruit-worker, build, work,
/// diplomatic, naval, naval-mission, trade.
///
/// [resolution] is the per-pass [OrderResolutionContext] snapshot built
/// once in [OrderEngine.validatePlayerOrdersWithContext] (view + unitsById +
/// provinceById); both the per-bundle validator factory and the per-move
/// validator share this exact record so probes do not rebuild equivalent
/// maps (Refs #2836 AC 3; SPEC/program/logic-validator-units-params.md).
///
/// [stagedOrdersSnapshot] is the engine's deep-copied order snapshot used by
/// the trade-order phase's projector dry-run. The caller (the engine) builds it
/// via its generated `copyOrdersSnapshotForEngine`; passing the copy in keeps
/// this library independent of the generated `order_engine.g.dart` part and the
/// orders import graph acyclic.
void runOrderValidationPhases({
  required OrderValidatorFactory validatorFactory,
  required OrderEffectsProjector? projector,
  required Orders stagedOrdersSnapshot,
  required OrderValidationRunState state,
  required Game game,
  required Player player,
  required String playerId,
  required OrderResolutionContext resolution,
  required MapTopology topology,
  required Map<String, TileMapResult>? tileMapByRegion,
  required List<DiplomaticOrder> diplomatic,
  required Set<String> civilianDraftMoveUnitIds,
  required Set<String> devExclusiveTiles,
  required DiplomacyFactionMembership factionMembership,
  required Map<String, Army> armiesById,
  required List<MoveOrder> moves,
  required List<ArmyMoveOrder> armyMoves,
  required List<RecruitWorkerOrder> recruitWorkers,
  required List<BuildUnitOrder> builds,
  required List<WorkOrder> works,
  required List<NavalMoveOrder> navals,
  required List<NavalMissionOrder> missions,
  required List<TradeOrder> tradeOrders,
}) {
  OrderValidators newValidatorBundle() => validatorFactory(
    game,
    player,
    playerId,
    resolution,
    topology,
    diplomatic,
    tileMapByRegion,
    civilianDraftMoveUnitIds,
    devExclusiveTiles,
    state.stockpile,
    state.treasury,
    factionMembership,
    state.workerPool,
  );

  // Run closures paired positionally with [orderValidationPhasePlan] (which
  // owns the declarative name + bundle-refresh contract). move + army share the
  // initial bundle; each later category refreshes validators so
  // stockpile/treasury/diplomatic state matches incremental validation ordering
  // (Refs #2391 AC7, SPEC/program/order-engine.md). Worker-pool orders (recruit
  // / train) come before unit builds in both validation and resolution so the
  // peasant reservation ledger reflects accepted recruit consumes before
  // military / naval builds check their own peasant requirement
  // (SPEC/game/workers-and-population.md § Peasant reservation;
  // SPEC/program/turn-resolution-phase-details.md § Build / work).
  final phaseRuns = <void Function(OrderValidators v)>[
    (v) => _runMovePhase(
      v,
      state,
      moves,
      game,
      playerId,
      resolution,
      diplomatic,
      topology,
      factionMembership,
    ),
    (v) => _runArmyMovePhase(
      v,
      state,
      armyMoves,
      game,
      playerId,
      diplomatic,
      resolution.view,
      topology,
      armiesById,
      factionMembership,
    ),
    (v) => _runResourceLedgerPhase(
      v,
      state,
      recruitWorkers,
      (vv, o, prev) =>
          vv.recruitWorkerValidator.validate(o, previousRejected: prev),
      (vv, st) {
        st.workerPool = vv.recruitWorkerValidator.workers;
        st.stockpile = vv.recruitWorkerValidator.stockpile;
        st.treasury = vv.recruitWorkerValidator.treasury;
      },
    ),
    (v) => _runResourceLedgerPhase(
      v,
      state,
      builds,
      (vv, o, prev) => vv.buildValidator.validate(o, previousRejected: prev),
      (vv, st) {
        st.workerPool = vv.buildValidator.workers;
        st.stockpile = vv.buildValidator.stockpile;
        st.treasury = vv.buildValidator.treasury;
      },
    ),
    (v) => _runResourceLedgerPhase(
      v,
      state,
      works,
      (vv, o, prev) => vv.workValidator.validate(o, previousRejected: prev),
      (vv, st) {
        st.stockpile = vv.workValidator.stockpile;
        st.treasury = vv.workValidator.treasury;
      },
    ),
    (v) => _runDiplomaticPhase(v, state, diplomatic),
    (v) => _runNavalPhase(v, state, navals, missions),
    (v) => _runTradeOrderPhase(
      state,
      game,
      playerId,
      tradeOrders,
      topology,
      stagedOrdersSnapshot,
      tileMapByRegion,
      projector,
    ),
  ];

  assert(
    phaseRuns.length == orderValidationPhasePlan.length,
    'phaseRuns must stay positionally aligned with orderValidationPhasePlan',
  );

  var validators = newValidatorBundle();
  for (var i = 0; i < orderValidationPhasePlan.length; i++) {
    if (orderValidationPhasePlan[i].refreshBundleBefore) {
      validators = newValidatorBundle();
    }
    phaseRuns[i](validators);
  }
}

void _runMovePhase(
  OrderValidators v,
  OrderValidationRunState state,
  List<MoveOrder> moves,
  Game game,
  String playerId,
  OrderResolutionContext resolution,
  List<DiplomaticOrder> diplomatic,
  MapTopology topology,
  DiplomacyFactionMembership factionMembership,
) {
  // [resolution] is the per-pass snapshot built once in
  // [validatePlayerOrdersWithContext]; the per-move
  // [MoveValidator.validate] call reuses it directly so probes do not
  // rebuild equivalent `view` / `unitsById` maps (Refs #2836 AC 3;
  // SPEC/program/logic-validator-units-params.md).
  state.rejected = _appendValidationResults(
    state.results,
    moves,
    state.rejected,
    (o, prev) => v.moveValidator.validate(
      o,
      game,
      playerId,
      resolution,
      diplomatic,
      topology,
      previousRejected: prev,
      factionMembership: factionMembership,
    ),
  );
}

void _runArmyMovePhase(
  OrderValidators v,
  OrderValidationRunState state,
  List<ArmyMoveOrder> armyMoves,
  Game game,
  String playerId,
  List<DiplomaticOrder> diplomatic,
  PlayerView view,
  MapTopology topology,
  Map<String, Army> armiesById,
  DiplomacyFactionMembership factionMembership,
) {
  state.rejected = _appendValidationResults(
    state.results,
    armyMoves,
    state.rejected,
    (o, prev) => v.armyMoveValidator.validate(
      o,
      game,
      playerId,
      diplomatic,
      view,
      topology,
      previousRejected: prev,
      armiesById: armiesById,
      factionMembership: factionMembership,
    ),
  );
}

void _runDiplomaticPhase(
  OrderValidators v,
  OrderValidationRunState state,
  List<DiplomaticOrder> diplomatic,
) {
  final afterDiplomatic =
      _appendValidationResultsWithState<DiplomaticOrder, int>(
        state.results,
        diplomatic,
        state.rejected,
        state.treasury,
        (o, prev) {
          final r = v.diplomaticValidator.validate(o, previousRejected: prev);
          return (result: r.result, state: r.treasury);
        },
      );
  state.rejected = afterDiplomatic.rejected;
  state.treasury = afterDiplomatic.state;
}

void _runNavalPhase(
  OrderValidators v,
  OrderValidationRunState state,
  List<NavalMoveOrder> navals,
  List<NavalMissionOrder> missions,
) {
  state.rejected = _appendValidationResults(
    state.results,
    navals,
    state.rejected,
    (o, prev) => v.navalValidator.validateNavalMove(o, previousRejected: prev),
  );
  state.rejected = _appendValidationResults(
    state.results,
    missions,
    state.rejected,
    (o, prev) =>
        v.navalValidator.validateNavalMission(o, previousRejected: prev),
  );
}

void _runTradeOrderPhase(
  OrderValidationRunState state,
  Game game,
  String playerId,
  List<TradeOrder> tradeOrders,
  MapTopology topology,
  Orders stagedOrders,
  Map<String, TileMapResult>? tileMapByRegion,
  OrderEffectsProjector? projector,
) {
  if (tradeOrders.isEmpty) return;
  if (state.rejected) {
    for (var i = 0; i < tradeOrders.length; i++) {
      state.results.add(previousInvalidOrderResult);
    }
    return;
  }
  // The projected non-bid treasury delta is a turn-layer dry-run
  // (`projectOrderEffects` calls `resolveTurnForGame`) that lives in the neutral
  // `lib/src/projections/` core module — above the `orders` domain. The engine
  // therefore receives it as an injected [OrderEffectsProjector] (Refs #3290
  // C2) and hands the resulting delta to the (economy-local) context builder,
  // keeping both `orders` free of any `projections`/`turn` import and `economy`
  // free of any `orders`/`turn` import per
  // `SPEC/program/logic-package-split-phase0.md`.
  if (projector == null) {
    throw StateError(
      'OrderEngine trade-order validation requires an injected '
      'OrderEffectsProjector; construct OrderEngine(projector: '
      'projectOrderEffects).',
    );
  }
  final projected = projector(
    game: game,
    orders: stagedOrders,
    topology: topology,
    tileMapByRegion: tileMapByRegion ?? const {},
    playerId: playerId,
  );
  final context = tradeOrderValidationContextFromGame(
    game,
    playerId,
    stagedOrders: stagedOrders,
    projectedTreasuryDelta: projected.treasuryDelta ?? 0,
  );
  final tradeResults = TradeOrderValidator.validate(
    context: context,
    proposedOrders: tradeOrders,
  );
  state.results.addAll(tradeResults);
  if (tradeResults.any((r) => !r.isAccepted)) {
    state.rejected = true;
  }
}
