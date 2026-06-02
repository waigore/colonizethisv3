import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_projections.dart';
import '../diplomacy/diplomacy_resolver.dart';
import '../world/player_view.dart';
import '../world/unit_lookup.dart';
import '../constants.dart';
import 'order_resolution_context.dart';
import 'projected_effects.dart';
import 'order_validation_result.dart';
export 'order_validation_result.dart';
import '../economy/world_market/trade_order_validator.dart';
import 'unit_type_helpers.dart';
export 'validator_bundle.dart'
    show
        OrderValidators,
        buildWorkOrderValidationContext,
        createOrderValidators,
        createWorkOrderValidator;
import 'validator_bundle.dart';

part 'order_engine.g.dart';

// --- Test-only instrumentation (Refs #2237 AC2) ---
bool _trackValidatePlayerOrdersWithContextInvocationsForTests = false;
int _validatePlayerOrdersWithContextInvocationCountForTests = 0;

/// Test hook: when enabled, counts every call to [OrderEngine.validatePlayerOrdersWithContext].
void setOrderEngineValidatePlayerOrdersWithContextTrackingForTests(
  bool enabled,
) {
  _trackValidatePlayerOrdersWithContextInvocationsForTests = enabled;
  _validatePlayerOrdersWithContextInvocationCountForTests = 0;
}

/// Test hook: invocations counted while tracking is enabled (Refs #2237).
int get orderEngineValidatePlayerOrdersWithContextInvocationCountForTests =>
    _validatePlayerOrdersWithContextInvocationCountForTests;

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

/// Deep-copy of order maps: new map and new list per player. Used by generated copy helpers.
Map<String, List<T>> _copyMapOfOrderLists<T>(Map<String, List<T>> map) =>
    Map.from(map)..updateAll((_, v) => List<T>.from(v));

class _OrderSlot<T> {
  const _OrderSlot({
    required this.getter,
    required this.updater,
    required this.label,
  });

  final Map<String, List<T>> Function(Orders) getter;
  final Orders Function(Orders, Map<String, List<T>>) updater;
  final String label;
}

/// Mutable state threaded through [OrderEngine._runOrderValidationPhases].
/// Holds the running rejected flag, treasury, stockpile, worker pool, and
/// the accumulated [OrderValidationResult] list. Existing only inside
/// [OrderEngine.validatePlayerOrdersWithContext]'s call stack.
class _OrderValidationRunState {
  _OrderValidationRunState({
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

/// Builds the per-bundle [OrderValidators] for one validation slice.
///
/// [resolution] threads the canonical [OrderResolutionContext] record
/// (`view` + `unitsById` + `provinceById`) so factories reuse the
/// per-pass snapshot the engine entry-point already built instead of
/// rebuilding the player view or unit-by-id map (Refs #2836 AC 3;
/// SPEC/program/logic-validator-units-params.md).
typedef OrderValidatorFactory =
    OrderValidators Function(
      Game game,
      Player player,
      String playerId,
      OrderResolutionContext resolution,
      MapTopology topology,
      List<DiplomaticOrder> diplomaticOrders,
      Map<String, TileMapResult>? tileMapByRegion,
      Set<String> civilianDraftMoveUnitIds,
      Set<String> devExclusiveTiles,
      Stockpile stockpile,
      int treasury,
      DiplomacyFactionMembership factionMembership,
      WorkerPool workerPool,
    );

/// One post–move/army validation round: caller constructs a fresh [OrderValidators]
/// bundle, then invokes this to append results and propagate economy state.
/// Order engine: holds per-player orders, validates in submission order,
/// exposes projected effects. SPEC/program/order-engine.md.
/// Slot table and public add/remove/withContext methods are generated from
/// [order_engine_manifest.yaml] → [order_engine.g.dart].
class OrderEngine with _OrderEngineGeneratedOrderMethods {
  OrderEngine({
    Orders initialOrders = const Orders(),
    OrderValidatorFactory? validatorFactory,
  }) : _orders = copyInitialOrdersForEngine(initialOrders),
       _validatorFactory = validatorFactory ?? _defaultOrderValidatorFactory;

  Orders _orders;
  final OrderValidatorFactory _validatorFactory;

  Orders get orders => copyOrdersSnapshotForEngine(_orders);

  // -- Generic helpers for add/remove --

  void _appendOrder<T>(
    String playerId,
    T order,
    Map<String, List<T>> Function(Orders) getter,
    Orders Function(Orders, Map<String, List<T>>) updater,
  ) {
    final list = getter(_orders)[playerId] ?? [];
    _orders = updater(_orders, {
      ...getter(_orders),
      playerId: [...list, order],
    });
  }

  OrderValidationResult _addOrderWithContext<T>(
    Game game,
    MapTopology topology,
    String playerId,
    T order,
    Map<String, List<T>> Function(Orders) getter,
    Orders Function(Orders, Map<String, List<T>>) updater,
    String orderLabel, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    _appendOrder(playerId, order, getter, updater);
    logicLog.d('validating orders with context player=$playerId');
    final results = validatePlayerOrdersWithContext(
      game,
      topology,
      playerId,
      tileMapByRegion: tileMapByRegion,
    );
    if (results.isEmpty) {
      return OrderValidationResult.accepted();
    }
    final r = results.last;
    if (!r.isAccepted) {
      // Keep diagnostics bounded on probe-heavy paths by suppressing repeated
      // cascade rejections ("Previous invalid"), while preserving first-cause
      // rejection logging for debugging. Refs #2237 AC3.
      if (r.reason != previousInvalidOrderResult.reason) {
        logicLog.w(
          '$orderLabel order rejected player=$playerId reason=${r.reason}',
        );
      }
    }
    return r;
  }

  void _removeOrderAt<T>(
    String playerId,
    int index,
    Map<String, List<T>> Function(Orders) getter,
    Orders Function(Orders, Map<String, List<T>>) updater,
  ) {
    final list = List<T>.from(getter(_orders)[playerId] ?? []);
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      _orders = updater(_orders, {...getter(_orders), playerId: list});
    }
  }

  /// Used by generated [order_engine.g.dart] mixins; not part of the supported public API.
  OrderValidationResult addOrderForSlot<T>(
    String playerId,
    T order,
    _OrderSlot<T> slot,
  ) {
    _appendOrder(playerId, order, slot.getter, slot.updater);
    return OrderValidationResult.accepted();
  }

  /// Used by generated [order_engine.g.dart] mixins; not part of the supported public API.
  OrderValidationResult addOrderForSlotWithContext<T>(
    Game game,
    MapTopology topology,
    String playerId,
    T order,
    _OrderSlot<T> slot, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    return _addOrderWithContext(
      game,
      topology,
      playerId,
      order,
      slot.getter,
      slot.updater,
      slot.label,
      tileMapByRegion: tileMapByRegion,
    );
  }

  /// Used by generated [order_engine.g.dart] mixins; not part of the supported public API.
  void removeOrderForSlot<T>(String playerId, int index, _OrderSlot<T> slot) {
    _removeOrderAt(playerId, index, slot.getter, slot.updater);
  }

  /// Validates with full context. Call this when Game and topology available.
  List<OrderValidationResult> validatePlayerOrdersWithContext(
    Game game,
    MapTopology topology,
    String playerId, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    if (_trackValidatePlayerOrdersWithContextInvocationsForTests) {
      _validatePlayerOrdersWithContextInvocationCountForTests++;
    }
    final player = game.playerById(playerId);
    if (player == null) return <OrderValidationResult>[];

    final view = buildPlayerView(game, topology, playerId);

    final moves = _orders.moveOrdersByPlayerId[playerId] ?? [];
    final armyMoves = _orders.armyMoveOrdersByPlayerId[playerId] ?? [];
    final recruitWorkers =
        _orders.recruitWorkerOrdersByPlayerId[playerId] ?? [];
    final builds = _orders.buildUnitOrdersByPlayerId[playerId] ?? [];
    final works = _orders.workOrdersByPlayerId[playerId] ?? [];
    final diplomatic = _orders.diplomaticOrdersByPlayerId[playerId] ?? [];
    final navals = _orders.navalMoveOrdersByPlayerId[playerId] ?? [];
    final missions = _orders.navalMissionOrdersByPlayerId[playerId] ?? [];
    final tradeOrders = _orders.tradeOrdersByPlayerId[playerId] ?? [];

    final unitsById = Map<String, Unit>.from(game.worldState.allUnitsById);

    // Single per-pass [OrderResolutionContext] snapshot shared across every
    // validator factory invocation and per-phase probe (Refs #2836 AC 3;
    // SPEC/program/logic-validator-units-params.md). The same `view` +
    // `unitsById` references back both the bundle factory and the per-move
    // validation context so probes do not rebuild equivalent maps.
    final resolution = orderResolutionContextFromView(
      view,
      game,
      unitsById: unitsById,
    );

    final devExclusiveTiles = devExclusiveTilesFromWorld(
      game.worldState,
      playerId,
    );

    final civilianDraftMoveUnitIds = <String>{};
    for (final m in moves) {
      final u = unitsById[m.unitId];
      if (u != null && u.tileKey != null && u.tileKey!.isNotEmpty) {
        civilianDraftMoveUnitIds.add(m.unitId);
      }
    }

    final factionMembership = DiplomacyFactionMembership.from(game);

    // Single-pass army index for full-pass army-move validation (Refs #2394,
    // SPEC/program/order-suggestions.md — same snapshot semantics as
    // [IncrementalCandidateValidator._armiesById] for read-only [game]).
    final armiesById = <String, Army>{
      for (final a in game.worldState.armies) a.id: a,
    };

    // Peasant reservation ledger: each accepted RecruitWorkerOrder consumes
    // peasants per `WorkerActionEconomyCatalog`, and the downstream build
    // validator must see the post-recruit headcount so military/naval builds
    // that consume a peasant respect the combined reservation (see
    // SPEC/game/workers-and-population.md § Peasant reservation).
    final state = _OrderValidationRunState(
      results: <OrderValidationResult>[],
      stockpile: player.stockpile,
      treasury: player.treasury,
      workerPool: player.workerPool,
    );

    _runOrderValidationPhases(
      state: state,
      game: game,
      player: player,
      playerId: playerId,
      resolution: resolution,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
      diplomatic: diplomatic,
      civilianDraftMoveUnitIds: civilianDraftMoveUnitIds,
      devExclusiveTiles: devExclusiveTiles,
      factionMembership: factionMembership,
      armiesById: armiesById,
      moves: moves,
      armyMoves: armyMoves,
      recruitWorkers: recruitWorkers,
      builds: builds,
      works: works,
      navals: navals,
      missions: missions,
      tradeOrders: tradeOrders,
    );
    return state.results;
  }

  /// Build and run the per-category validation phases for one player.
  /// Mutates [state] (results / rejected / stockpile / treasury / workerPool)
  /// in submission order: move, army-move, recruit-worker, build, work,
  /// diplomatic, naval, naval-mission, trade.
  ///
  /// [resolution] is the per-pass [OrderResolutionContext] snapshot built
  /// once in [validatePlayerOrdersWithContext] (view + unitsById +
  /// provinceById); both the per-bundle validator factory and the per-move
  /// validator share this exact record so probes do not rebuild equivalent
  /// maps (Refs #2836 AC 3; SPEC/program/logic-validator-units-params.md).
  void _runOrderValidationPhases({
    required _OrderValidationRunState state,
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
    OrderValidators newValidatorBundle() => _validatorFactory(
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

    // One ordered list: move + army share the initial bundle; each later
    // category refreshes validators so stockpile/treasury/diplomatic state
    // matches incremental validation ordering (Refs #2391 AC7,
    // SPEC/program/order-engine.md). Worker pool orders (recruit / train)
    // come before unit builds in both validation and resolution so the
    // peasant reservation ledger reflects accepted recruit consumes before
    // military / naval builds check their own peasant requirement
    // (SPEC/game/workers-and-population.md § Peasant reservation;
    // SPEC/program/turn-resolution-phase-details.md § Build / work).
    final validationPhases =
        <({bool refreshBundleBefore, void Function(OrderValidators) run})>[
          (
            refreshBundleBefore: false,
            run: (v) => _runMovePhase(
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
          ),
          (
            refreshBundleBefore: false,
            run: (v) => _runArmyMovePhase(
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
          ),
          (
            refreshBundleBefore: true,
            run: (v) => _runRecruitWorkerPhase(v, state, recruitWorkers),
          ),
          (
            refreshBundleBefore: true,
            run: (v) => _runBuildPhase(v, state, builds),
          ),
          (
            refreshBundleBefore: true,
            run: (v) => _runWorkPhase(v, state, works),
          ),
          (
            refreshBundleBefore: true,
            run: (v) => _runDiplomaticPhase(v, state, diplomatic),
          ),
          (
            refreshBundleBefore: true,
            run: (v) => _runNavalPhase(v, state, navals, missions),
          ),
          (
            refreshBundleBefore: false,
            run: (v) => _runTradeOrderPhase(
              state,
              game,
              playerId,
              tradeOrders,
              topology,
              copyOrdersSnapshotForEngine(_orders),
              tileMapByRegion,
            ),
          ),
        ];

    var validators = newValidatorBundle();
    for (final phase in validationPhases) {
      if (phase.refreshBundleBefore) {
        validators = newValidatorBundle();
      }
      phase.run(validators);
    }
  }

  void _runMovePhase(
    OrderValidators v,
    _OrderValidationRunState state,
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
    _OrderValidationRunState state,
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
      (o, prev) => prev
          ? previousInvalidOrderResult
          : v.armyMoveValidator.validate(
              o,
              game,
              playerId,
              diplomatic,
              view,
              topology,
              armiesById: armiesById,
              factionMembership: factionMembership,
            ),
    );
  }

  void _runRecruitWorkerPhase(
    OrderValidators v,
    _OrderValidationRunState state,
    List<RecruitWorkerOrder> recruitWorkers,
  ) {
    state.rejected = _appendValidationResults(
      state.results,
      recruitWorkers,
      state.rejected,
      (o, prev) => v.recruitWorkerValidator.validate(o, previousRejected: prev),
    );
    state.workerPool = v.recruitWorkerValidator.workers;
    state.stockpile = v.recruitWorkerValidator.stockpile;
    state.treasury = v.recruitWorkerValidator.treasury;
  }

  void _runBuildPhase(
    OrderValidators v,
    _OrderValidationRunState state,
    List<BuildUnitOrder> builds,
  ) {
    state.rejected = _appendValidationResults(
      state.results,
      builds,
      state.rejected,
      (o, prev) => v.buildValidator.validate(o, previousRejected: prev),
    );
    state.workerPool = v.buildValidator.workers;
    state.stockpile = v.buildValidator.stockpile;
    state.treasury = v.buildValidator.treasury;
  }

  void _runWorkPhase(
    OrderValidators v,
    _OrderValidationRunState state,
    List<WorkOrder> works,
  ) {
    state.rejected = _appendValidationResults(
      state.results,
      works,
      state.rejected,
      (o, prev) => v.workValidator.validate(o, previousRejected: prev),
    );
    state.stockpile = v.workValidator.stockpile;
    state.treasury = v.workValidator.treasury;
  }

  void _runDiplomaticPhase(
    OrderValidators v,
    _OrderValidationRunState state,
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
    _OrderValidationRunState state,
    List<NavalMoveOrder> navals,
    List<NavalMissionOrder> missions,
  ) {
    state.rejected = _appendValidationResults(
      state.results,
      navals,
      state.rejected,
      (o, prev) =>
          v.navalValidator.validateNavalMove(o, previousRejected: prev),
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
    _OrderValidationRunState state,
    Game game,
    String playerId,
    List<TradeOrder> tradeOrders,
    MapTopology topology,
    Orders stagedOrders,
    Map<String, TileMapResult>? tileMapByRegion,
  ) {
    if (tradeOrders.isEmpty) return;
    if (state.rejected) {
      for (var i = 0; i < tradeOrders.length; i++) {
        state.results.add(previousInvalidOrderResult);
      }
      return;
    }
    final context = tradeOrderValidationContextFromGame(
      game,
      playerId,
      stagedOrders: stagedOrders,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
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

  /// Dry-run: apply orders via resolver (no mutation of [game]); return projected effects.
  /// Uses [projectOrderEffects] for worker count, treasury delta, unit locations, stockpile deltas.
  /// When [tileMapByRegion] is null or omitted, an empty map is used and projected extraction is zero
  /// (caller may pass tile maps when available so expected extraction is non-zero).
  ProjectedEffects projectedEffects(
    Game game,
    MapTopology topology,
    String playerId, {
    List<AssignedRecipe> defaultAssignments = const [],
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    final tileMaps = tileMapByRegion ?? <String, TileMapResult>{};
    if (tileMaps.isEmpty) {
      logicLog.d(
        'projectedEffects called with no tileMapByRegion; expected extraction will be zero',
      );
    }
    return projectOrderEffects(
      game: game,
      orders: copyOrdersSnapshotForEngine(_orders),
      topology: topology,
      tileMapByRegion: tileMaps,
      playerId: playerId,
      defaultAssignments: defaultAssignments,
    );
  }
}

OrderValidators _defaultOrderValidatorFactory(
  Game game,
  Player player,
  String playerId,
  OrderResolutionContext resolution,
  MapTopology topology,
  List<DiplomaticOrder> diplomaticOrders,
  Map<String, TileMapResult>? tileMapByRegion,
  Set<String> civilianDraftMoveUnitIds,
  Set<String> devExclusiveTiles,
  Stockpile stockpile,
  int treasury,
  DiplomacyFactionMembership factionMembership,
  WorkerPool workerPool,
) {
  return createOrderValidators(
    game: game,
    player: player,
    playerId: playerId,
    resolution: resolution,
    topology: topology,
    diplomaticOrders: diplomaticOrders,
    tileMapByRegion: tileMapByRegion,
    civilianDraftMoveUnitIds: civilianDraftMoveUnitIds,
    devExclusiveTiles: devExclusiveTiles,
    stockpile: stockpile,
    treasury: treasury,
    factionMembership: factionMembership,
    workerPool: workerPool,
  );
}
