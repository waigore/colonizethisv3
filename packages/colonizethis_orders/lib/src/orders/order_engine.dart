import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_effects_projector.dart';
export 'order_effects_projector.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'order_resolution_context.dart';
import 'orders_application_context.dart' show copyUnitsById;
import 'orders_logging.dart';
export 'order_validation_result.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'unit_type_helpers.dart';
export 'validator_bundle.dart'
    show
        OrderValidators,
        buildWorkOrderValidationContext,
        createOrderValidators,
        createWorkOrderValidator;
import 'validator_bundle.dart';

part 'order_engine.g.dart';
part 'order_engine_validation.dart';

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
/// Per-category validation phases live in the `order_engine_validation.dart`
/// `part of` fragment (Refs #3290 Phase 0 file decomposition).
class OrderEngine with _OrderEngineGeneratedOrderMethods {
  OrderEngine({
    Orders initialOrders = const Orders(),
    OrderValidatorFactory? validatorFactory,
    OrderEffectsProjector? projector,
  }) : _orders = copyInitialOrdersForEngine(initialOrders),
       _validatorFactory = validatorFactory ?? _defaultOrderValidatorFactory,
       _projector = projector;

  Orders _orders;
  final OrderValidatorFactory _validatorFactory;

  /// Injected dry-run projector (Refs #3290 C2). `null` when the engine is
  /// constructed without one; required only by [projectedEffects] and trade-
  /// order validation. SPEC/program/order-engine.md § Injected projector seam.
  final OrderEffectsProjector? _projector;

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
    ordersLog.d('validating orders with context player=$playerId');
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
        ordersLog.w(
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

    final unitsById = copyUnitsById(game.worldState.allUnitsById);

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
      validatorFactory: _validatorFactory,
      projector: _projector,
      orders: _orders,
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
      ordersLog.d(
        'projectedEffects called with no tileMapByRegion; expected extraction will be zero',
      );
    }
    final projector = _projector;
    if (projector == null) {
      throw StateError(
        'OrderEngine.projectedEffects requires an injected OrderEffectsProjector; '
        'construct OrderEngine(projector: projectOrderEffects).',
      );
    }
    return projector(
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
