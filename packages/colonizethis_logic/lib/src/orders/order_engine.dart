import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import '../economy/economy_production.dart';
import 'order_projections.dart';
import '../world/player_view.dart';
import '../world/unit_lookup.dart';
import '../constants.dart';
import 'projected_effects.dart';
import 'order_validation_result.dart';
export 'order_validation_result.dart';
import 'validators/move_validator.dart';
import 'validators/diplomatic_order_validator.dart';
import 'validators/build_order_validator.dart';
import 'validators/work_order_validator.dart';
import 'validators/naval_order_validator.dart';

final Logger _log = Logger();

/// Order engine: current-turn orders per player, validation, projected effects.
/// SPEC/program/order-engine.md. Does not mutate world state.

/// Order engine: holds per-player orders, validates in submission order,
/// exposes projected effects. No world state mutation.
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

class OrderEngine {
  OrderEngine({
    Orders initialOrders = const Orders(),
  }) : _orders = Orders(
          moveOrdersByPlayerId: Map.from(initialOrders.moveOrdersByPlayerId)
            ..updateAll((_, v) => List.from(v)),
          buildUnitOrdersByPlayerId:
              Map.from(initialOrders.buildUnitOrdersByPlayerId)
                ..updateAll((_, v) => List.from(v)),
          workOrdersByPlayerId: Map.from(initialOrders.workOrdersByPlayerId)
            ..updateAll((_, v) => List.from(v)),
          diplomaticOrdersByPlayerId:
              Map.from(initialOrders.diplomaticOrdersByPlayerId)
                ..updateAll((_, v) => List.from(v)),
          researchOrdersByPlayerId:
              Map.from(initialOrders.researchOrdersByPlayerId)
                ..updateAll((_, v) => List.from(v)),
          navalMoveOrdersByPlayerId:
              Map.from(initialOrders.navalMoveOrdersByPlayerId)
                ..updateAll((_, v) => List<NavalMoveOrder>.from(v)),
          navalMissionOrdersByPlayerId:
              Map.from(initialOrders.navalMissionOrdersByPlayerId)
                ..updateAll((_, v) => List<NavalMissionOrder>.from(v)),
        );

  Orders _orders;

  Orders get orders => _copyOrders(_orders);

  Orders _copyOrders(Orders o) => Orders(
        moveOrdersByPlayerId: o.moveOrdersByPlayerId.map(
          (k, v) => MapEntry(k, List<MoveOrder>.from(v)),
        ),
        buildUnitOrdersByPlayerId: o.buildUnitOrdersByPlayerId.map(
          (k, v) => MapEntry(k, List<BuildUnitOrder>.from(v)),
        ),
        workOrdersByPlayerId: o.workOrdersByPlayerId.map(
          (k, v) => MapEntry(k, List<WorkOrder>.from(v)),
        ),
        diplomaticOrdersByPlayerId: o.diplomaticOrdersByPlayerId.map(
          (k, v) => MapEntry(k, List<DiplomaticOrder>.from(v)),
        ),
        researchOrdersByPlayerId: o.researchOrdersByPlayerId.map(
          (k, v) => MapEntry(k, List<ResearchOrder>.from(v)),
        ),
        navalMoveOrdersByPlayerId: o.navalMoveOrdersByPlayerId.map(
          (k, v) => MapEntry(k, List<NavalMoveOrder>.from(v)),
        ),
        navalMissionOrdersByPlayerId: o.navalMissionOrdersByPlayerId.map(
          (k, v) => MapEntry(k, List<NavalMissionOrder>.from(v)),
        ),
      );

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
      playerId: [...list, order]
    });
  }

  OrderValidationResult _addOrderWithContext<T>(
    Game game,
    MapTopology topology,
    String playerId,
    T order,
    Map<String, List<T>> Function(Orders) getter,
    Orders Function(Orders, Map<String, List<T>>) updater,
    String orderLabel,
  ) {
    _appendOrder(playerId, order, getter, updater);
    _log.d('logic: validating orders with context player=$playerId');
    final results = validatePlayerOrdersWithContext(game, topology, playerId);
    if (results.isEmpty) {
      return OrderValidationResult.accepted();
    }
    final r = results.last;
    if (!r.isAccepted)
      _log.w(
          'logic: $orderLabel order rejected player=$playerId reason=${r.reason}');
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

  // -- Field accessors for Orders --

  static Map<String, List<MoveOrder>> _moveOrders(Orders o) =>
      o.moveOrdersByPlayerId;
  static Orders _withMoveOrders(Orders o, Map<String, List<MoveOrder>> m) =>
      o.copyWith(moveOrdersByPlayerId: m);

  static Map<String, List<BuildUnitOrder>> _buildOrders(Orders o) =>
      o.buildUnitOrdersByPlayerId;
  static Orders _withBuildOrders(
          Orders o, Map<String, List<BuildUnitOrder>> m) =>
      o.copyWith(buildUnitOrdersByPlayerId: m);

  static Map<String, List<WorkOrder>> _workOrders(Orders o) =>
      o.workOrdersByPlayerId;
  static Orders _withWorkOrders(Orders o, Map<String, List<WorkOrder>> m) =>
      o.copyWith(workOrdersByPlayerId: m);

  static Map<String, List<DiplomaticOrder>> _diplomaticOrders(Orders o) =>
      o.diplomaticOrdersByPlayerId;
  static Orders _withDiplomaticOrders(
          Orders o, Map<String, List<DiplomaticOrder>> m) =>
      o.copyWith(diplomaticOrdersByPlayerId: m);

  static Map<String, List<NavalMoveOrder>> _navalMoveOrders(Orders o) =>
      o.navalMoveOrdersByPlayerId;
  static Orders _withNavalMoveOrders(
          Orders o, Map<String, List<NavalMoveOrder>> m) =>
      o.copyWith(navalMoveOrdersByPlayerId: m);

  static Map<String, List<NavalMissionOrder>> _navalMissionOrders(Orders o) =>
      o.navalMissionOrdersByPlayerId;
  static Orders _withNavalMissionOrders(
          Orders o, Map<String, List<NavalMissionOrder>> m) =>
      o.copyWith(navalMissionOrdersByPlayerId: m);

  // -- Public add/remove methods --

  static const _OrderSlot<MoveOrder> _moveSlot = _OrderSlot<MoveOrder>(
    getter: _moveOrders,
    updater: _withMoveOrders,
    label: 'move',
  );

  static const _OrderSlot<BuildUnitOrder> _buildSlot =
      _OrderSlot<BuildUnitOrder>(
    getter: _buildOrders,
    updater: _withBuildOrders,
    label: 'build',
  );

  static const _OrderSlot<WorkOrder> _workSlot = _OrderSlot<WorkOrder>(
    getter: _workOrders,
    updater: _withWorkOrders,
    label: 'work',
  );

  static const _OrderSlot<DiplomaticOrder> _diplomaticSlot =
      _OrderSlot<DiplomaticOrder>(
    getter: _diplomaticOrders,
    updater: _withDiplomaticOrders,
    label: 'diplomatic',
  );

  static const _OrderSlot<NavalMoveOrder> _navalMoveSlot =
      _OrderSlot<NavalMoveOrder>(
    getter: _navalMoveOrders,
    updater: _withNavalMoveOrders,
    label: 'naval move',
  );

  static const _OrderSlot<NavalMissionOrder> _navalMissionSlot =
      _OrderSlot<NavalMissionOrder>(
    getter: _navalMissionOrders,
    updater: _withNavalMissionOrders,
    label: 'naval mission',
  );

  OrderValidationResult _addOrder<T>(
    String playerId,
    T order,
    _OrderSlot<T> slot,
  ) {
    _appendOrder(playerId, order, slot.getter, slot.updater);
    return OrderValidationResult.accepted();
  }

  OrderValidationResult _addOrderWithContextSlot<T>(
    Game game,
    MapTopology topology,
    String playerId,
    T order,
    _OrderSlot<T> slot,
  ) {
    return _addOrderWithContext(
      game,
      topology,
      playerId,
      order,
      slot.getter,
      slot.updater,
      slot.label,
    );
  }

  void _removeOrderAtSlot<T>(
    String playerId,
    int index,
    _OrderSlot<T> slot,
  ) {
    _removeOrderAt(playerId, index, slot.getter, slot.updater);
  }

  OrderValidationResult addMoveOrder(String playerId, MoveOrder order) =>
      _addOrder(playerId, order, _moveSlot);

  OrderValidationResult addMoveOrderWithContext(
          Game game, MapTopology topology, String playerId, MoveOrder order) =>
      _addOrderWithContextSlot(game, topology, playerId, order, _moveSlot);

  OrderValidationResult addBuildOrder(String playerId, BuildUnitOrder order) =>
      _addOrder(playerId, order, _buildSlot);

  OrderValidationResult addBuildOrderWithContext(Game game,
          MapTopology topology, String playerId, BuildUnitOrder order) =>
      _addOrderWithContextSlot(game, topology, playerId, order, _buildSlot);

  OrderValidationResult addWorkOrder(String playerId, WorkOrder order) =>
      _addOrder(playerId, order, _workSlot);

  OrderValidationResult addWorkOrderWithContext(
          Game game, MapTopology topology, String playerId, WorkOrder order) =>
      _addOrderWithContextSlot(game, topology, playerId, order, _workSlot);

  OrderValidationResult addDiplomaticOrder(
          String playerId, DiplomaticOrder order) =>
      _addOrder(playerId, order, _diplomaticSlot);

  OrderValidationResult addDiplomaticOrderWithContext(
    Game game,
    MapTopology topology,
    String playerId,
    DiplomaticOrder order,
  ) =>
      _addOrderWithContextSlot(
        game,
        topology,
        playerId,
        order,
        _diplomaticSlot,
      );

  OrderValidationResult addNavalMoveOrder(
          String playerId, NavalMoveOrder order) =>
      _addOrder(playerId, order, _navalMoveSlot);

  OrderValidationResult addNavalMoveOrderWithContext(Game game,
          MapTopology topology, String playerId, NavalMoveOrder order) =>
      _addOrderWithContextSlot(
        game,
        topology,
        playerId,
        order,
        _navalMoveSlot,
      );

  OrderValidationResult addNavalMissionOrder(
          String playerId, NavalMissionOrder order) =>
      _addOrder(playerId, order, _navalMissionSlot);

  OrderValidationResult addNavalMissionOrderWithContext(Game game,
          MapTopology topology, String playerId, NavalMissionOrder order) =>
      _addOrderWithContextSlot(
        game,
        topology,
        playerId,
        order,
        _navalMissionSlot,
      );

  void removeMoveOrder(String playerId, int index) =>
      _removeOrderAtSlot(playerId, index, _moveSlot);

  void removeBuildOrder(String playerId, int index) =>
      _removeOrderAtSlot(playerId, index, _buildSlot);

  void removeWorkOrder(String playerId, int index) =>
      _removeOrderAtSlot(playerId, index, _workSlot);

  /// Validates with full context. Call this when Game and topology available.
  List<OrderValidationResult> validatePlayerOrdersWithContext(
    Game game,
    MapTopology topology,
    String playerId,
  ) {
    final results = <OrderValidationResult>[];
    final player = game.playerById(playerId);
    if (player == null) return results;

    final view = buildPlayerView(game, topology, playerId);

    final moves = _orders.moveOrdersByPlayerId[playerId] ?? [];
    final builds = _orders.buildUnitOrdersByPlayerId[playerId] ?? [];
    final works = _orders.workOrdersByPlayerId[playerId] ?? [];
    final diplomatic = _orders.diplomaticOrdersByPlayerId[playerId] ?? [];
    final navals = _orders.navalMoveOrdersByPlayerId[playerId] ?? [];
    final missions = _orders.navalMissionOrdersByPlayerId[playerId] ?? [];
    var rejected = false;

    final unitsById =
        Map<String, Unit>.from(unitsByIdFromWorld(game.worldState));

    // Per-player tile exclusivity (SPEC/game/civilian-units.md, SPEC/program/orders.md):
    // track tiles already reserved by this player's Builder/Engineer/Merchant work
    // (existing multi-turn currentWork and newly accepted work orders in this validation pass).
    final devExclusiveTiles = <String>{};
    for (final u in allUnitsFromWorld(game.worldState)) {
      final w = u.currentWork;
          if (u.ownerId == playerId &&
          isDevExclusiveUnitType(u.type) &&
          w != null &&
          w.tileKey.isNotEmpty) {
        devExclusiveTiles.add(w.tileKey);
      }
    }

    const _moveValidator = MoveValidator();

    OrderValidationResult validateMove(MoveOrder o) {
      return _moveValidator.validate(
        o, game, playerId, unitsById, diplomatic, view, topology,
      );
    }

    for (final o in moves) {
      if (rejected) {
        results.add(previousInvalidOrderResult);
        continue;
      }
      final r = validateMove(o);
      results.add(r);
      if (!r.isAccepted) rejected = true;
    }

    var stockpile = player.stockpile;
    var treasury = player.treasury;

    final buildValidator = BuildOrderValidator(game: game, player: player);
    for (final o in builds) {
      final r = buildValidator.validate(o, previousRejected: rejected);
      results.add(r);
      if (!r.isAccepted) rejected = true;
    }
    stockpile = buildValidator.stockpile;
    treasury = buildValidator.treasury;

    final workValidator = WorkOrderValidator(
      game: game,
      player: player,
      playerId: playerId,
      view: view,
      unitsById: unitsById,
      devExclusiveTiles: devExclusiveTiles,
      stockpile: stockpile,
      treasury: treasury,
    );
    for (final o in works) {
      final r = workValidator.validate(o, previousRejected: rejected);
      results.add(r);
      if (!r.isAccepted) rejected = true;
    }
    stockpile = workValidator.stockpile;
    treasury = workValidator.treasury;

    final diplomaticValidator = DiplomaticOrderValidator(
      game: game,
      playerId: playerId,
      initialTreasury: treasury,
    );
    for (final o in diplomatic) {
      final r = diplomaticValidator.validate(
        o,
        previousRejected: rejected,
      );
      results.add(r.result);
      treasury = r.treasury;
      if (!r.result.isAccepted) {
        rejected = true;
      }
    }

    final navalValidator = NavalOrderValidator(
      game: game,
      topology: topology,
      playerId: playerId,
    );
    for (final o in navals) {
      final r = navalValidator.validateNavalMove(o, previousRejected: rejected);
      results.add(r);
      if (!r.isAccepted) rejected = true;
    }
    for (final o in missions) {
      final r =
          navalValidator.validateNavalMission(o, previousRejected: rejected);
      results.add(r);
      if (!r.isAccepted) rejected = true;
    }
    return results;
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
    final orders = _copyOrders(_orders);
    final tileMaps = tileMapByRegion ?? <String, TileMapResult>{};
    if (tileMaps.isEmpty) {
      _log.d(
          'logic: projectedEffects called with no tileMapByRegion; expected extraction will be zero');
    }
    return projectOrderEffects(
      game: game,
      orders: orders,
      topology: topology,
      tileMapByRegion: tileMaps,
      playerId: playerId,
      defaultAssignments: defaultAssignments,
    );
  }
}
