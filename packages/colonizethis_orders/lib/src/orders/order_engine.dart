import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_effects_projector.dart';
export 'order_effects_projector.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import 'order_engine.g.dart';
import 'order_engine_slot.dart';
import 'order_engine_test_hooks.dart';
export 'order_engine_test_hooks.dart';
import 'order_engine_validation_run.dart';
import 'order_resolution_context.dart';
import 'order_validation_result.dart';
import 'order_validator_factory.dart';
export 'order_validator_factory.dart';
import 'orders_logging.dart';
export 'order_validation_result.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
export 'validator_bundle.dart'
    show
        OrderValidators,
        buildWorkOrderValidationContext,
        createOrderValidators,
        createWorkOrderValidator;

/// One post–move/army validation round: caller constructs a fresh [OrderValidators]
/// bundle, then invokes this to append results and propagate economy state.
/// Order engine: holds per-player orders, validates in submission order,
/// exposes projected effects. SPEC/program/order-engine.md.
/// Slot table and public add/remove/withContext methods are generated into the
/// standalone `order_engine.g.dart` library from [order_engine_manifest.yaml]
/// and mixed in via [OrderEngineGeneratedOrderMethods].
/// Per-category validation phases live in the standalone
/// `order_engine_validation.dart` library (Refs #3290 Phase 0 file
/// decomposition; Refs #3543 de-part-file).
class OrderEngine with OrderEngineGeneratedOrderMethods {
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
    OrderSlot<T> slot,
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
    OrderSlot<T> slot, {
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
  void removeOrderForSlot<T>(String playerId, int index, OrderSlot<T> slot) {
    _removeOrderAt(playerId, index, slot.getter, slot.updater);
  }

  /// Validates with full context. Call this when Game and topology available.
  List<OrderValidationResult> validatePlayerOrdersWithContext(
    Game game,
    MapTopology topology,
    String playerId, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) {
    bumpOrderEngineValidatePlayerOrdersWithContextInvocationIfTracking();
    return runOrderEnginePlayerValidation(
      validatorFactory: _validatorFactory,
      projector: _projector,
      stagedOrders: copyOrdersSnapshotForEngine(_orders),
      game: game,
      playerId: playerId,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
    );
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
