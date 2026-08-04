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
import 'order_validation_result_append.dart';
import 'order_validator_factory.dart';
import 'order_engine_validation_phases.dart';
import 'order_engine_validation_state.dart';

export 'order_engine_validation_state.dart';

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
  state.rejected = appendValidationResults(
    state.results,
    orders,
    state.rejected,
    (o, prev) => validate(v, o, prev),
  );
  carryForwardLedgers(v, state);
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
    (v) => runMoveValidationPhase(
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
    (v) => runArmyMoveValidationPhase(
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
    (v) => runDiplomaticValidationPhase(v, state, diplomatic),
    (v) => runNavalValidationPhase(v, state, navals, missions),
    (v) => runTradeOrderValidationPhase(
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
