import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import '../economy/economy_production.dart';
import '../world/movement.dart';
import '../world/naval.dart';
import 'order_visibility.dart';
import '../world/player_view.dart';
import '../constants.dart';
import '../world/province_lookup.dart';
import '../turn/turn_resolver.dart';

final Logger _log = Logger();

/// Order engine: current-turn orders per player, validation, projected effects.
/// SPEC/program/order-engine.md. Does not mutate world state.

/// Validation result for one order. First invalid + all subsequent rejected.
enum OrderValidationStatus { accepted, rejected }

class OrderValidationResult {
  const OrderValidationResult({
    required this.status,
    this.reason,
  });

  final OrderValidationStatus status;
  final String? reason;

  bool get isAccepted => status == OrderValidationStatus.accepted;
}

/// Projected effects after dry-run of orders. For UI feedback.
class ProjectedEffects {
  const ProjectedEffects({
    this.workerCount,
    this.unitLocations,
    this.stockpileDeltas,
    this.treasuryDelta,
  });

  final int? workerCount;
  final Map<String, String>? unitLocations;
  final Map<String, int>? stockpileDeltas;
  final int? treasuryDelta;
}

/// Order engine: holds per-player orders, validates in submission order,
/// exposes projected effects. No world state mutation.
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
    _orders = updater(_orders, {...getter(_orders), playerId: [...list, order]});
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
    final results = validatePlayerOrdersWithContext(game, topology, playerId);
    if (results.isEmpty) {
      return const OrderValidationResult(status: OrderValidationStatus.accepted);
    }
    final r = results.last;
    if (!r.isAccepted) _log.w('logic: $orderLabel order rejected player=$playerId reason=${r.reason}');
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

  static Map<String, List<MoveOrder>> _moveOrders(Orders o) => o.moveOrdersByPlayerId;
  static Orders _withMoveOrders(Orders o, Map<String, List<MoveOrder>> m) =>
      Orders(moveOrdersByPlayerId: m, buildUnitOrdersByPlayerId: o.buildUnitOrdersByPlayerId, workOrdersByPlayerId: o.workOrdersByPlayerId, researchOrdersByPlayerId: o.researchOrdersByPlayerId, navalMoveOrdersByPlayerId: o.navalMoveOrdersByPlayerId, navalMissionOrdersByPlayerId: o.navalMissionOrdersByPlayerId);

  static Map<String, List<BuildUnitOrder>> _buildOrders(Orders o) => o.buildUnitOrdersByPlayerId;
  static Orders _withBuildOrders(Orders o, Map<String, List<BuildUnitOrder>> m) =>
      Orders(moveOrdersByPlayerId: o.moveOrdersByPlayerId, buildUnitOrdersByPlayerId: m, workOrdersByPlayerId: o.workOrdersByPlayerId, researchOrdersByPlayerId: o.researchOrdersByPlayerId, navalMoveOrdersByPlayerId: o.navalMoveOrdersByPlayerId, navalMissionOrdersByPlayerId: o.navalMissionOrdersByPlayerId);

  static Map<String, List<WorkOrder>> _workOrders(Orders o) => o.workOrdersByPlayerId;
  static Orders _withWorkOrders(Orders o, Map<String, List<WorkOrder>> m) =>
      Orders(moveOrdersByPlayerId: o.moveOrdersByPlayerId, buildUnitOrdersByPlayerId: o.buildUnitOrdersByPlayerId, workOrdersByPlayerId: m, researchOrdersByPlayerId: o.researchOrdersByPlayerId, navalMoveOrdersByPlayerId: o.navalMoveOrdersByPlayerId, navalMissionOrdersByPlayerId: o.navalMissionOrdersByPlayerId);

  static Map<String, List<NavalMoveOrder>> _navalMoveOrders(Orders o) => o.navalMoveOrdersByPlayerId;
  static Orders _withNavalMoveOrders(Orders o, Map<String, List<NavalMoveOrder>> m) =>
      Orders(moveOrdersByPlayerId: o.moveOrdersByPlayerId, buildUnitOrdersByPlayerId: o.buildUnitOrdersByPlayerId, workOrdersByPlayerId: o.workOrdersByPlayerId, researchOrdersByPlayerId: o.researchOrdersByPlayerId, navalMoveOrdersByPlayerId: m, navalMissionOrdersByPlayerId: o.navalMissionOrdersByPlayerId);

  static Map<String, List<NavalMissionOrder>> _navalMissionOrders(Orders o) => o.navalMissionOrdersByPlayerId;
  static Orders _withNavalMissionOrders(Orders o, Map<String, List<NavalMissionOrder>> m) =>
      Orders(moveOrdersByPlayerId: o.moveOrdersByPlayerId, buildUnitOrdersByPlayerId: o.buildUnitOrdersByPlayerId, workOrdersByPlayerId: o.workOrdersByPlayerId, researchOrdersByPlayerId: o.researchOrdersByPlayerId, navalMoveOrdersByPlayerId: o.navalMoveOrdersByPlayerId, navalMissionOrdersByPlayerId: m);

  // -- Public add/remove methods --

  OrderValidationResult addMoveOrder(String playerId, MoveOrder order) {
    _appendOrder(playerId, order, _moveOrders, _withMoveOrders);
    return const OrderValidationResult(status: OrderValidationStatus.accepted);
  }

  OrderValidationResult addMoveOrderWithContext(Game game, MapTopology topology, String playerId, MoveOrder order) =>
      _addOrderWithContext(game, topology, playerId, order, _moveOrders, _withMoveOrders, 'move');

  OrderValidationResult addBuildOrder(String playerId, BuildUnitOrder order) {
    _appendOrder(playerId, order, _buildOrders, _withBuildOrders);
    return const OrderValidationResult(status: OrderValidationStatus.accepted);
  }

  OrderValidationResult addBuildOrderWithContext(Game game, MapTopology topology, String playerId, BuildUnitOrder order) =>
      _addOrderWithContext(game, topology, playerId, order, _buildOrders, _withBuildOrders, 'build');

  OrderValidationResult addWorkOrder(String playerId, WorkOrder order) {
    _appendOrder(playerId, order, _workOrders, _withWorkOrders);
    return const OrderValidationResult(status: OrderValidationStatus.accepted);
  }

  OrderValidationResult addWorkOrderWithContext(Game game, MapTopology topology, String playerId, WorkOrder order) =>
      _addOrderWithContext(game, topology, playerId, order, _workOrders, _withWorkOrders, 'work');

  OrderValidationResult addNavalMoveOrder(String playerId, NavalMoveOrder order) {
    _appendOrder(playerId, order, _navalMoveOrders, _withNavalMoveOrders);
    return const OrderValidationResult(status: OrderValidationStatus.accepted);
  }

  OrderValidationResult addNavalMoveOrderWithContext(Game game, MapTopology topology, String playerId, NavalMoveOrder order) =>
      _addOrderWithContext(game, topology, playerId, order, _navalMoveOrders, _withNavalMoveOrders, 'naval move');

  OrderValidationResult addNavalMissionOrder(String playerId, NavalMissionOrder order) {
    _appendOrder(playerId, order, _navalMissionOrders, _withNavalMissionOrders);
    return const OrderValidationResult(status: OrderValidationStatus.accepted);
  }

  OrderValidationResult addNavalMissionOrderWithContext(Game game, MapTopology topology, String playerId, NavalMissionOrder order) =>
      _addOrderWithContext(game, topology, playerId, order, _navalMissionOrders, _withNavalMissionOrders, 'naval mission');

  void removeMoveOrder(String playerId, int index) =>
      _removeOrderAt(playerId, index, _moveOrders, _withMoveOrders);

  void removeBuildOrder(String playerId, int index) =>
      _removeOrderAt(playerId, index, _buildOrders, _withBuildOrders);

  void removeWorkOrder(String playerId, int index) =>
      _removeOrderAt(playerId, index, _workOrders, _withWorkOrders);

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
    final navals = _orders.navalMoveOrdersByPlayerId[playerId] ?? [];
    final missions = _orders.navalMissionOrdersByPlayerId[playerId] ?? [];
    var rejected = false;

    final unitsById = {for (final u in game.worldState.oldWorld.units) u.id: u}
      ..addAll({for (final u in game.worldState.newWorld.units) u.id: u});

    bool _ownerIsGreatPower(String? ownerId) {
      if (ownerId == null) return false;
      return game.players.any((p) => p.id == ownerId);
    }

    bool _ownerIsMinorOrTribe(String? ownerId) {
      if (ownerId == null) return false;
      return game.minorNations.any((m) => m.id == ownerId) ||
          game.tribes.any((t) => t.id == ownerId);
    }

    OrderValidationResult validateMove(MoveOrder o) {
      final unit = unitsById[o.unitId];
      if (unit == null || unit.ownerId != playerId) {
        return const OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Invalid move');
      }
      final unitRegion = unit.tileKey != null && unit.tileKey!.isNotEmpty
          ? Unit.requireRegionIdFromTileKey(unit.tileKey)
          : ProvinceId.regionIdFrom(resolveToFullProvinceId(game.worldState, unit.provinceId));
      final unitLocalId = ProvinceId.localIdFrom(unit.locationProvinceId);
      final destLocalId = ProvinceId.localIdFrom(o.destinationProvinceId);
      if (!isValidLandMove(topology, unitLocalId, destLocalId)) {
        return const OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Invalid move');
      }
      final destProvince = tryGetProvince(game.worldState, o.destinationProvinceId);
      final destOwnerId = destProvince?.ownerId;
      if (!isMilitaryUnit(unit.type) && destOwnerId != null && destOwnerId != playerId) {
        if (_ownerIsGreatPower(destOwnerId)) {
          return const OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Civilian cannot enter other Great Power territory');
        }
        if (_ownerIsMinorOrTribe(destOwnerId) && !isExplorerUnit(unit.type) && !isMerchantUnit(unit.type)) {
          return const OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Civilian cannot enter Minor/Tribe territory');
        }
      }
      if (!moveSourceVisibilityOk(view, unitRegion, unit.locationProvinceId) ||
          !moveDestVisibilityOk(view, unitRegion, o.destinationProvinceId, unit.type)) {
        return const OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Source or destination not visible');
      }
      return const OrderValidationResult(status: OrderValidationStatus.accepted);
    }

    for (final o in moves) {
      if (rejected) {
        results.add(const OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Previous invalid'));
        continue;
      }
      final r = validateMove(o);
      results.add(r);
      if (!r.isAccepted) rejected = true;
    }

    var workers = player.workerPool;
    var stockpile = player.stockpile;
    var treasury = player.treasury;

    OrderValidationResult validateBuild(BuildUnitOrder o) {
      if (player.capitalProvinceId == null) {
        return const OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'No capital to spawn unit');
      }
      if (!o.isMilitary) {
        return const OrderValidationResult(status: OrderValidationStatus.accepted);
      }
      final econ = RegimentEconomyCatalog.byId[o.unitType];
      if (econ == null) {
        return const OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Insufficient resources');
      }
      if (workers.peasants <= 0) {
        return const OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Insufficient resources');
      }
      if (treasury < econ.buildTreasuryCost) {
        return const OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Insufficient resources');
      }
      for (final e in econ.buildInputs.entries) {
        if (stockpile.quantityOf(e.key) < e.value) {
          return const OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Insufficient resources');
        }
      }
      treasury -= econ.buildTreasuryCost;
      for (final e in econ.buildInputs.entries) {
        stockpile = stockpile.applyDelta(e.key, -e.value);
      }
      workers = workers.copyWith(peasants: workers.peasants - 1);
      return const OrderValidationResult(status: OrderValidationStatus.accepted);
    }

    for (final o in builds) {
      if (rejected) {
        results.add(const OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Previous invalid'));
        continue;
      }
      final r = validateBuild(o);
      results.add(r);
      if (!r.isAccepted) rejected = true;
    }

    OrderValidationResult validateWork(WorkOrder o) {
      final unit = unitsById[o.unitId];
      if (unit == null || unit.ownerId != playerId) {
        return const OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Unit not found');
      }
      final type = unit.type;
      const explorerTargets = {'explore', 'prospect'};
      const workerTargets = {'build_improvement', 'upgrade_town', 'build_road', 'build_port', 'build_fort', 'build_rail'};
      final targetOk = (isExplorerUnit(type) && explorerTargets.contains(o.target)) ||
          (isCivilianWorkerUnit(type) && workerTargets.contains(o.target));
      if (!targetOk) {
        return const OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Invalid work target for unit type');
      }
      if (o.targetTileKey.isEmpty) {
        return const OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Work order requires a target tile');
      }
      if (!isExplorerUnit(type)) {
        final targetProvinceId = Unit.provinceIdFromTileKey(o.targetTileKey);
        final province = targetProvinceId != null
            ? tryGetProvince(game.worldState, targetProvinceId)
            : null;
        final ownerId = province?.ownerId;
        if (ownerId != null && ownerId != playerId) {
          return const OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Cannot work in foreign province');
        }
      }
      if (!workOrderVisibilityOk(view, unit, o.target, o.targetTileKey)) {
        return const OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Province or tile not visible for this work');
      }
      return const OrderValidationResult(status: OrderValidationStatus.accepted);
    }

    for (final o in works) {
      if (rejected) {
        results.add(const OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Previous invalid'));
        continue;
      }
      final r = validateWork(o);
      results.add(r);
      if (!r.isAccepted) rejected = true;
    }

    final fleetById = {for (final f in game.worldState.fleets) f.id: f};
    for (final o in navals) {
      if (rejected) {
        results.add(OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Previous invalid'));
        continue;
      }
      final fleet = fleetById[o.fleetId];
      final valid = fleet != null &&
          fleet.ownerId == playerId &&
          isAdjacentSeaZone(topology, fleet.seaZoneId, o.destinationSeaZoneId);
      results.add(OrderValidationResult(
        status: valid ? OrderValidationStatus.accepted : OrderValidationStatus.rejected,
        reason: valid ? null : (fleet == null ? 'Fleet not found' : 'Invalid naval move'),
      ));
      if (!valid) rejected = true;
    }

    for (final o in missions) {
      if (rejected) {
        results.add(OrderValidationResult(status: OrderValidationStatus.rejected, reason: 'Previous invalid'));
        continue;
      }
      final fleet = fleetById[o.fleetId];
      final valid = fleet != null && fleet.ownerId == playerId;
      results.add(OrderValidationResult(
        status: valid ? OrderValidationStatus.accepted : OrderValidationStatus.rejected,
        reason: valid ? null : (fleet == null ? 'Fleet not found' : 'Fleet not owned by player'),
      ));
      if (!valid) rejected = true;
    }
    return results;
  }

  /// Dry-run: apply orders to copy of game, return projected effects.
  ProjectedEffects projectedEffects(
    Game game,
    MapTopology topology,
    String playerId, {
    List<AssignedRecipe> defaultAssignments = const [],
  }) {
    final orders = _copyOrders(_orders);
    final tileMapByRegion = <String, TileMapResult>{};
    final next = resolveTurnForGame(
      game: game,
      topology: topology,
      orders: orders,
      tileMapByRegion: tileMapByRegion.isEmpty ? null : tileMapByRegion,
      defaultAssignments: defaultAssignments,
    );
    final player = next.playerById(playerId);
    if (player == null) return const ProjectedEffects();

    final origPlayer = game.playerById(playerId);

    return ProjectedEffects(
      workerCount: player.workerPool.totalWorkers,
      treasuryDelta: origPlayer != null ? player.treasury - origPlayer.treasury : null,
    );
  }
}
