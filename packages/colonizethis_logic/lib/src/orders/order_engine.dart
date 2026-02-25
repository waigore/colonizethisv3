import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import '../economy/economy_production.dart';
import '../world/movement.dart';
import '../world/naval.dart';
import 'order_visibility.dart';
import 'order_projections.dart';
import '../world/player_view.dart';
import '../constants.dart';
import '../world/province_lookup.dart';
import 'projected_effects.dart';
import '../diplomacy/diplomacy_resolver.dart';

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
      return const OrderValidationResult(
          status: OrderValidationStatus.accepted);
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
      Orders(
        moveOrdersByPlayerId: m,
        buildUnitOrdersByPlayerId: o.buildUnitOrdersByPlayerId,
        workOrdersByPlayerId: o.workOrdersByPlayerId,
        diplomaticOrdersByPlayerId: o.diplomaticOrdersByPlayerId,
        researchOrdersByPlayerId: o.researchOrdersByPlayerId,
        navalMoveOrdersByPlayerId: o.navalMoveOrdersByPlayerId,
        navalMissionOrdersByPlayerId: o.navalMissionOrdersByPlayerId,
      );

  static Map<String, List<BuildUnitOrder>> _buildOrders(Orders o) =>
      o.buildUnitOrdersByPlayerId;
  static Orders _withBuildOrders(
          Orders o, Map<String, List<BuildUnitOrder>> m) =>
      Orders(
        moveOrdersByPlayerId: o.moveOrdersByPlayerId,
        buildUnitOrdersByPlayerId: m,
        workOrdersByPlayerId: o.workOrdersByPlayerId,
        diplomaticOrdersByPlayerId: o.diplomaticOrdersByPlayerId,
        researchOrdersByPlayerId: o.researchOrdersByPlayerId,
        navalMoveOrdersByPlayerId: o.navalMoveOrdersByPlayerId,
        navalMissionOrdersByPlayerId: o.navalMissionOrdersByPlayerId,
      );

  static Map<String, List<WorkOrder>> _workOrders(Orders o) =>
      o.workOrdersByPlayerId;
  static Orders _withWorkOrders(Orders o, Map<String, List<WorkOrder>> m) =>
      Orders(
        moveOrdersByPlayerId: o.moveOrdersByPlayerId,
        buildUnitOrdersByPlayerId: o.buildUnitOrdersByPlayerId,
        workOrdersByPlayerId: m,
        diplomaticOrdersByPlayerId: o.diplomaticOrdersByPlayerId,
        researchOrdersByPlayerId: o.researchOrdersByPlayerId,
        navalMoveOrdersByPlayerId: o.navalMoveOrdersByPlayerId,
        navalMissionOrdersByPlayerId: o.navalMissionOrdersByPlayerId,
      );

  static Map<String, List<DiplomaticOrder>> _diplomaticOrders(Orders o) =>
      o.diplomaticOrdersByPlayerId;
  static Orders _withDiplomaticOrders(
          Orders o, Map<String, List<DiplomaticOrder>> m) =>
      Orders(
        moveOrdersByPlayerId: o.moveOrdersByPlayerId,
        buildUnitOrdersByPlayerId: o.buildUnitOrdersByPlayerId,
        workOrdersByPlayerId: o.workOrdersByPlayerId,
        diplomaticOrdersByPlayerId: m,
        researchOrdersByPlayerId: o.researchOrdersByPlayerId,
        navalMoveOrdersByPlayerId: o.navalMoveOrdersByPlayerId,
        navalMissionOrdersByPlayerId: o.navalMissionOrdersByPlayerId,
      );

  static Map<String, List<NavalMoveOrder>> _navalMoveOrders(Orders o) =>
      o.navalMoveOrdersByPlayerId;
  static Orders _withNavalMoveOrders(
          Orders o, Map<String, List<NavalMoveOrder>> m) =>
      Orders(
        moveOrdersByPlayerId: o.moveOrdersByPlayerId,
        buildUnitOrdersByPlayerId: o.buildUnitOrdersByPlayerId,
        workOrdersByPlayerId: o.workOrdersByPlayerId,
        diplomaticOrdersByPlayerId: o.diplomaticOrdersByPlayerId,
        researchOrdersByPlayerId: o.researchOrdersByPlayerId,
        navalMoveOrdersByPlayerId: m,
        navalMissionOrdersByPlayerId: o.navalMissionOrdersByPlayerId,
      );

  static Map<String, List<NavalMissionOrder>> _navalMissionOrders(Orders o) =>
      o.navalMissionOrdersByPlayerId;
  static Orders _withNavalMissionOrders(
          Orders o, Map<String, List<NavalMissionOrder>> m) =>
      Orders(
        moveOrdersByPlayerId: o.moveOrdersByPlayerId,
        buildUnitOrdersByPlayerId: o.buildUnitOrdersByPlayerId,
        workOrdersByPlayerId: o.workOrdersByPlayerId,
        diplomaticOrdersByPlayerId: o.diplomaticOrdersByPlayerId,
        researchOrdersByPlayerId: o.researchOrdersByPlayerId,
        navalMoveOrdersByPlayerId: o.navalMoveOrdersByPlayerId,
        navalMissionOrdersByPlayerId: m,
      );

  // -- Public add/remove methods --

  OrderValidationResult addMoveOrder(String playerId, MoveOrder order) {
    _appendOrder(playerId, order, _moveOrders, _withMoveOrders);
    return const OrderValidationResult(status: OrderValidationStatus.accepted);
  }

  OrderValidationResult addMoveOrderWithContext(
          Game game, MapTopology topology, String playerId, MoveOrder order) =>
      _addOrderWithContext(game, topology, playerId, order, _moveOrders,
          _withMoveOrders, 'move');

  OrderValidationResult addBuildOrder(String playerId, BuildUnitOrder order) {
    _appendOrder(playerId, order, _buildOrders, _withBuildOrders);
    return const OrderValidationResult(status: OrderValidationStatus.accepted);
  }

  OrderValidationResult addBuildOrderWithContext(Game game,
          MapTopology topology, String playerId, BuildUnitOrder order) =>
      _addOrderWithContext(game, topology, playerId, order, _buildOrders,
          _withBuildOrders, 'build');

  OrderValidationResult addWorkOrder(String playerId, WorkOrder order) {
    _appendOrder(playerId, order, _workOrders, _withWorkOrders);
    return const OrderValidationResult(status: OrderValidationStatus.accepted);
  }

  OrderValidationResult addWorkOrderWithContext(
          Game game, MapTopology topology, String playerId, WorkOrder order) =>
      _addOrderWithContext(game, topology, playerId, order, _workOrders,
          _withWorkOrders, 'work');

  OrderValidationResult addDiplomaticOrder(
      String playerId, DiplomaticOrder order) {
    _appendOrder(playerId, order, _diplomaticOrders, _withDiplomaticOrders);
    return const OrderValidationResult(status: OrderValidationStatus.accepted);
  }

  OrderValidationResult addDiplomaticOrderWithContext(
    Game game,
    MapTopology topology,
    String playerId,
    DiplomaticOrder order,
  ) =>
      _addOrderWithContext(
        game,
        topology,
        playerId,
        order,
        _diplomaticOrders,
        _withDiplomaticOrders,
        'diplomatic',
      );

  OrderValidationResult addNavalMoveOrder(
      String playerId, NavalMoveOrder order) {
    _appendOrder(playerId, order, _navalMoveOrders, _withNavalMoveOrders);
    return const OrderValidationResult(status: OrderValidationStatus.accepted);
  }

  OrderValidationResult addNavalMoveOrderWithContext(Game game,
          MapTopology topology, String playerId, NavalMoveOrder order) =>
      _addOrderWithContext(game, topology, playerId, order, _navalMoveOrders,
          _withNavalMoveOrders, 'naval move');

  OrderValidationResult addNavalMissionOrder(
      String playerId, NavalMissionOrder order) {
    _appendOrder(playerId, order, _navalMissionOrders, _withNavalMissionOrders);
    return const OrderValidationResult(status: OrderValidationStatus.accepted);
  }

  OrderValidationResult addNavalMissionOrderWithContext(Game game,
          MapTopology topology, String playerId, NavalMissionOrder order) =>
      _addOrderWithContext(game, topology, playerId, order, _navalMissionOrders,
          _withNavalMissionOrders, 'naval mission');

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
    final diplomatic = _orders.diplomaticOrdersByPlayerId[playerId] ?? [];
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
        return const OrderValidationResult(
            status: OrderValidationStatus.rejected, reason: 'Invalid move');
      }
      final unitRegion = unit.tileKey != null && unit.tileKey!.isNotEmpty
          ? Unit.requireRegionIdFromTileKey(unit.tileKey)
          : ProvinceId.regionIdFrom(
              resolveToFullProvinceId(game.worldState, unit.provinceId));
      final destFullId =
          resolveToFullProvinceId(game.worldState, o.destinationProvinceId);
      final destRegion = ProvinceId.regionIdFrom(destFullId);
      if (destRegion != unitRegion) {
        return const OrderValidationResult(
            status: OrderValidationStatus.rejected, reason: 'Invalid move');
      }
      final unitLocalId = ProvinceId.localIdFrom(unit.locationProvinceId);
      final destLocalId = ProvinceId.localIdFrom(destFullId);
      if (!isValidLandMoveInRegion(
          topology, unitRegion, unitLocalId, destLocalId)) {
        return const OrderValidationResult(
            status: OrderValidationStatus.rejected, reason: 'Invalid move');
      }
      final destProvince =
          tryGetProvince(game.worldState, o.destinationProvinceId);
      final destOwnerId = destProvince?.ownerId;
      if (!isMilitaryUnit(unit.type) &&
          destOwnerId != null &&
          destOwnerId != playerId) {
        if (_ownerIsGreatPower(destOwnerId) && !isSpyUnit(unit.type)) {
          return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Civilian cannot enter other Great Power territory');
        }
        if (_ownerIsMinorOrTribe(destOwnerId) &&
            !isExplorerUnit(unit.type) &&
            !isMerchantUnit(unit.type) &&
            !isSpyUnit(unit.type)) {
          return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Civilian cannot enter Minor/Tribe territory');
        }
      }
      if (!moveSourceVisibilityOk(view, unitRegion, unit.locationProvinceId) ||
          !moveDestVisibilityOk(
              view, unitRegion, o.destinationProvinceId, unit.type)) {
        return const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Source or destination not visible');
      }
      return const OrderValidationResult(
          status: OrderValidationStatus.accepted);
    }

    for (final o in moves) {
      if (rejected) {
        results.add(const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Previous invalid'));
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
        return const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'No capital to spawn unit');
      }
      final category = buildUnitCategoryForUnitType(o.unitType);
      switch (category) {
        case BuildUnitCategory.civilian:
          final econ = CivilianEconomyCatalog.byId[o.unitType];
          if (econ == null) {
            return const OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason: 'Insufficient resources');
          }
          final unlockingTechId = unlockingTechByCivilianId[o.unitType];
          if (unlockingTechId != null &&
              (player.techUnlocked?[unlockingTechId] != true)) {
            return const OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason: 'Insufficient resources');
          }
          if (treasury < econ.buildTreasuryCost) {
            return const OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason: 'Insufficient resources');
          }
          for (final e in econ.buildInputs.entries) {
            if (stockpile.quantityOf(e.key) < e.value) {
              return const OrderValidationResult(
                  status: OrderValidationStatus.rejected,
                  reason: 'Insufficient resources');
            }
          }
          treasury -= econ.buildTreasuryCost;
          for (final e in econ.buildInputs.entries) {
            stockpile = stockpile.applyDelta(e.key, -e.value);
          }
          return const OrderValidationResult(
              status: OrderValidationStatus.accepted);
        case BuildUnitCategory.military:
          final econ = RegimentEconomyCatalog.byId[o.unitType];
          if (econ == null) {
            return const OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason: 'Insufficient resources');
          }
          final regimentUnlockTech = unlockingTechByRegimentId[o.unitType];
          if (regimentUnlockTech != null &&
              (player.techUnlocked?[regimentUnlockTech] != true)) {
            return const OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason: 'Insufficient resources');
          }
          if (workers.peasants <= 0) {
            return const OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason: 'Insufficient resources');
          }
          if (treasury < econ.buildTreasuryCost) {
            return const OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason: 'Insufficient resources');
          }
          for (final e in econ.buildInputs.entries) {
            if (stockpile.quantityOf(e.key) < e.value) {
              return const OrderValidationResult(
                  status: OrderValidationStatus.rejected,
                  reason: 'Insufficient resources');
            }
          }
          treasury -= econ.buildTreasuryCost;
          for (final e in econ.buildInputs.entries) {
            stockpile = stockpile.applyDelta(e.key, -e.value);
          }
          workers = workers.copyWith(peasants: workers.peasants - 1);
          return const OrderValidationResult(
              status: OrderValidationStatus.accepted);
        case BuildUnitCategory.naval:
          final shipEcon = ShipEconomyCatalog.byId[o.unitType];
          if (shipEcon == null) {
            return const OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason: 'Insufficient resources');
          }
          if (treasury < shipEcon.buildTreasuryCost) {
            return const OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason: 'Insufficient resources');
          }
          for (final e in shipEcon.buildInputs.entries) {
            if (stockpile.quantityOf(e.key) < e.value) {
              return const OrderValidationResult(
                  status: OrderValidationStatus.rejected,
                  reason: 'Insufficient resources');
            }
          }
          treasury -= shipEcon.buildTreasuryCost;
          for (final e in shipEcon.buildInputs.entries) {
            stockpile = stockpile.applyDelta(e.key, -e.value);
          }
          return const OrderValidationResult(
              status: OrderValidationStatus.accepted);
        case BuildUnitCategory.unknown:
          return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Insufficient resources');
      }
    }

    for (final o in builds) {
      if (rejected) {
        results.add(const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Previous invalid'));
        continue;
      }
      final r = validateBuild(o);
      results.add(r);
      if (!r.isAccepted) rejected = true;
    }

    OrderValidationResult validateWork(WorkOrder o) {
      final unit = unitsById[o.unitId];
      if (unit == null || unit.ownerId != playerId) {
        return const OrderValidationResult(
            status: OrderValidationStatus.rejected, reason: 'Unit not found');
      }
      if (unit.currentWork != null) {
        return const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Unit already has a work order; cancel first');
      }
      final type = unit.type;
      if (!isWorkOrderTargetAllowedForUnitType(type, o.target)) {
        return const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Invalid work target for unit type');
      }
      if (o.targetTileKey.isEmpty) {
        return const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Work order requires a target tile');
      }
      final targetProvinceId = Unit.provinceIdFromTileKey(o.targetTileKey);
      final province = targetProvinceId != null
          ? tryGetProvince(game.worldState, targetProvinceId)
          : null;
      final ownerId = province?.ownerId;

      // steal_tech: target must be another GP's capital province; that GP must have tech we lack
      if (o.target == 'steal_tech') {
        if (targetProvinceId == null) {
          return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Invalid target for steal_tech');
        }
        final otherPlayer = game.players
            .where((p) =>
                p.id != playerId && p.capitalProvinceId == targetProvinceId)
            .firstOrNull;
        if (otherPlayer == null) {
          return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason:
                  'steal_tech target must be another Great Power capital province');
        }
        final ourTech = player.techUnlocked ?? {};
        final theirTech = otherPlayer.techUnlocked ?? {};
        final hasTechWeLack = theirTech.entries
            .any((e) => e.value == true && ourTech[e.key] != true);
        if (!hasTechWeLack) {
          return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Target has no technology you lack');
        }
      } else if (o.target == 'counter_spy') {
        if (ownerId != playerId) {
          return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'counter_spy target must be your own province');
        }
      } else if (o.target == 'purchase_land') {
        if (ownerId == null || ownerId == playerId) {
          return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'purchase_land target must be a Minor or Tribe province');
        }
        final isMinor = game.minorNations.any((m) => m.id == ownerId);
        final isTribe = game.tribes.any((t) => t.id == ownerId);
        if (!isMinor && !isTribe) {
          return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'purchase_land target must be a Minor or Tribe province');
        }
        final rel = game.diplomacyRelations
            .where((r) =>
                (r.factionId1 == playerId && r.factionId2 == ownerId) ||
                (r.factionId2 == playerId && r.factionId1 == ownerId))
            .firstOrNull;
        if (rel != null && rel.atWar) {
          return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Cannot purchase land: at war with that faction');
        }
        final overture = game.overtureStates
            .where((ov) => ov.gpId == playerId && ov.targetId == ownerId)
            .firstOrNull;
        if (overture == null || !overture.hasEmbassy) {
          return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason:
                  'Cannot purchase land: embassy required with that Minor/Tribe');
        }
        final resourceId = game.worldState.resourceByTileKey[o.targetTileKey];
        if (resourceId == null || resourceId.isEmpty) {
          return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Tile has no resource');
        }
        const mineralIds = {
          'iron',
          'copper',
          'tin',
          'coal',
          'silver',
          'gold',
          'gems',
          'diamonds'
        };
        if (mineralIds.contains(resourceId)) {
          final prospected = game.worldState.playerProspectedTiles[playerId] ??
              const <String>{};
          if (!prospected.contains(o.targetTileKey)) {
            return const OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason: 'Mineral tile must be prospected first');
          }
        }
        final cost = 15 * landPurchaseBasePrice(resourceId);
        if (treasury < cost) {
          return OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Insufficient treasury for purchase_land (need $cost)');
        }
      } else if (!isExplorerUnit(type)) {
        // Builder, Engineer, Rail Builder: must work in owned province
        if (ownerId != null && ownerId != playerId) {
          return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Cannot work in foreign province');
        }
      }

      // Cost validation: materials for build_* and upgrade_town; treasury for purchase_land already checked above
      if (o.target != 'steal_tech' &&
          o.target != 'counter_spy' &&
          o.target != 'purchase_land') {
        final improvementLevel = o.target == 'build_improvement'
            ? (game.worldState.tileState.improvementLevel(o.targetTileKey))
            : 0;
        final fortLevel = province?.fortLevel ?? 0;
        final roadLevel = game.worldState.tileState.roadLevel(o.targetTileKey);
        if (o.target == 'build_road' && roadLevel >= 1) {
          final hasRoadConstruction =
              player.techUnlocked?['road_construction'] == true;
          if (!hasRoadConstruction) {
            return const OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason:
                    'Road Construction tech required for transport level 2');
          }
        }
        final costMap = workOrderMaterialCost(
          o.target,
          improvementLevel: improvementLevel,
          fortLevel: fortLevel,
          roadLevel: roadLevel,
        );
        if (costMap != null) {
          for (final entry in costMap.entries) {
            if (stockpile.quantityOf(entry.key) < entry.value) {
              return const OrderValidationResult(
                  status: OrderValidationStatus.rejected,
                  reason: 'Insufficient materials for work order');
            }
          }
        }
      }

      if (!workOrderVisibilityOk(view, unit, o.target, o.targetTileKey)) {
        return const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Province or tile not visible for this work');
      }
      return const OrderValidationResult(
          status: OrderValidationStatus.accepted);
    }

    for (final o in works) {
      if (rejected) {
        results.add(const OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Previous invalid'));
        continue;
      }
      final r = validateWork(o);
      results.add(r);
      if (!r.isAccepted) {
        rejected = true;
      } else {
        // Project cost so subsequent work orders see updated stockpile/treasury
        final unit = unitsById[o.unitId];
        if (unit != null && o.target == 'purchase_land') {
          final resourceId = game.worldState.resourceByTileKey[o.targetTileKey];
          if (resourceId != null && resourceId.isNotEmpty) {
            final cost = 15 * landPurchaseBasePrice(resourceId);
            treasury -= cost;
          }
        } else if (unit != null &&
            o.target != 'steal_tech' &&
            o.target != 'counter_spy') {
          final provId = Unit.provinceIdFromTileKey(o.targetTileKey);
          final province =
              provId != null ? tryGetProvince(game.worldState, provId) : null;
          final improvementLevel = o.target == 'build_improvement'
              ? game.worldState.tileState.improvementLevel(o.targetTileKey)
              : 0;
          final fortLevel = province?.fortLevel ?? 0;
          final roadLevel =
              game.worldState.tileState.roadLevel(o.targetTileKey);
          final costMap = workOrderMaterialCost(o.target,
              improvementLevel: improvementLevel,
              fortLevel: fortLevel,
              roadLevel: roadLevel);
          if (costMap != null) {
            for (final entry in costMap.entries) {
              if (stockpile.quantityOf(entry.key) >= entry.value) {
                stockpile = stockpile.applyDelta(entry.key, -entry.value);
              }
            }
          }
        }
      }
    }

    bool _factionIsGreatPower(String id) => game.players.any((p) => p.id == id);
    bool _factionIsMinorOrTribe(String id) =>
        game.minorNations.any((m) => m.id == id) ||
        game.tribes.any((t) => t.id == id);

    OrderValidationResult validateDiplomatic(DiplomaticOrder o) {
      final targetId = o.targetFactionId;

      if (targetId == playerId) {
        return const OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: 'Cannot target own faction with diplomatic order',
        );
      }

      final targetExists =
          _factionIsGreatPower(targetId) || _factionIsMinorOrTribe(targetId);
      if (!targetExists) {
        return const OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: 'Target faction not found',
        );
      }

      final rel = getRelation(game, playerId, targetId);
      final atWar = rel?.atWar ?? false;
      final atPeace = rel == null || rel.atPeace;

      switch (o.type) {
        case DiplomaticOrderType.declareWar:
          if (!atPeace) {
            return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Already at war with that faction',
            );
          }
          return const OrderValidationResult(
              status: OrderValidationStatus.accepted);

        case DiplomaticOrderType.offerPeace:
          if (!atWar) {
            return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Cannot offer peace when not at war with that faction',
            );
          }
          return const OrderValidationResult(
              status: OrderValidationStatus.accepted);

        case DiplomaticOrderType.alliance:
          if (!_factionIsGreatPower(targetId)) {
            return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Alliance target must be a Great Power',
            );
          }
          if (atWar) {
            return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Cannot form alliance while at war with that faction',
            );
          }
          return const OrderValidationResult(
              status: OrderValidationStatus.accepted);

        case DiplomaticOrderType.establishOverture:
          final stage = o.overtureStage;
          if (stage == null || stage == OvertureStage.none) {
            return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Overture stage is required for establishOverture',
            );
          }
          if (!_factionIsMinorOrTribe(targetId)) {
            return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Overtures are only valid toward Minor Nations or Tribes',
            );
          }
          if (atWar) {
            return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason:
                  'Cannot establish overture while at war with that faction',
            );
          }

          final overture = getOverture(game, playerId, targetId);
          final currentStage = overture?.stage ?? OvertureStage.none;

          if (stage == OvertureStage.tradeConsulate) {
            if (currentStage != OvertureStage.none) {
              return const OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason: 'Trade Consulate requires no existing overture',
              );
            }
            if (treasury < overtureConsulateCost) {
              return OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason:
                    'Insufficient treasury for Trade Consulate (need $overtureConsulateCost)',
              );
            }
            treasury -= overtureConsulateCost;
          } else if (stage == OvertureStage.embassy) {
            if (currentStage != OvertureStage.tradeConsulate) {
              return const OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason:
                    'Embassy requires existing Trade Consulate with that faction',
              );
            }
            if (treasury < overtureEmbassyCost) {
              return OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason:
                    'Insufficient treasury for Embassy (need $overtureEmbassyCost)',
              );
            }
            treasury -= overtureEmbassyCost;
          } else if (stage == OvertureStage.nap) {
            if (currentStage != OvertureStage.embassy) {
              return const OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason:
                    'Non-Aggression Pact requires existing Embassy with that faction',
              );
            }
          } else if (stage == OvertureStage.joinEmpire) {
            if (currentStage != OvertureStage.nap) {
              return const OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason:
                    'Join Empire requires existing Non-Aggression Pact with that faction',
              );
            }
            final score = rel?.score ?? 50;
            if (score < 51) {
              return const OrderValidationResult(
                status: OrderValidationStatus.rejected,
                reason:
                    'Join Empire requires at least Friendly relations (score >= 51)',
              );
            }
          }

          return const OrderValidationResult(
              status: OrderValidationStatus.accepted);

        case DiplomaticOrderType.grantAid:
          final amount = o.amount ?? 0;
          if (amount <= 0) {
            return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'GrantAid amount must be positive',
            );
          }
          final overture = getOverture(game, playerId, targetId);
          if (overture == null || !overture.hasEmbassy) {
            return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Embassy required for GrantAid',
            );
          }
          if (treasury < amount) {
            return OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Insufficient treasury for GrantAid (need $amount)',
            );
          }
          treasury -= amount;
          return const OrderValidationResult(
              status: OrderValidationStatus.accepted);

        case DiplomaticOrderType.setSubsidy:
          final amount = o.amount ?? 0;
          if (amount <= 0) {
            return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'SetSubsidy amount must be positive',
            );
          }
          final overture = getOverture(game, playerId, targetId);
          if (overture == null || !overture.hasConsulate) {
            return const OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Consulate or Embassy required for SetSubsidy',
            );
          }
          if (treasury < amount) {
            return OrderValidationResult(
              status: OrderValidationStatus.rejected,
              reason: 'Insufficient treasury for SetSubsidy (need $amount)',
            );
          }
          treasury -= amount;
          return const OrderValidationResult(
              status: OrderValidationStatus.accepted);
      }
    }

    for (final o in diplomatic) {
      if (rejected) {
        results.add(const OrderValidationResult(
          status: OrderValidationStatus.rejected,
          reason: 'Previous invalid',
        ));
        continue;
      }
      final r = validateDiplomatic(o);
      results.add(r);
      if (!r.isAccepted) {
        rejected = true;
      }
    }

    final fleetById = {for (final f in game.worldState.fleets) f.id: f};
    for (final o in navals) {
      if (rejected) {
        results.add(OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Previous invalid'));
        continue;
      }
      final fleet = fleetById[o.fleetId];
      final valid = fleet != null &&
          fleet.ownerId == playerId &&
          isAdjacentSeaZone(topology, fleet.seaZoneId, o.destinationSeaZoneId);
      results.add(OrderValidationResult(
        status: valid
            ? OrderValidationStatus.accepted
            : OrderValidationStatus.rejected,
        reason: valid
            ? null
            : (fleet == null ? 'Fleet not found' : 'Invalid naval move'),
      ));
      if (!valid) rejected = true;
    }

    for (final o in missions) {
      if (rejected) {
        results.add(OrderValidationResult(
            status: OrderValidationStatus.rejected,
            reason: 'Previous invalid'));
        continue;
      }
      final fleet = fleetById[o.fleetId];
      final valid = fleet != null && fleet.ownerId == playerId;
      results.add(OrderValidationResult(
        status: valid
            ? OrderValidationStatus.accepted
            : OrderValidationStatus.rejected,
        reason: valid
            ? null
            : (fleet == null ? 'Fleet not found' : 'Fleet not owned by player'),
      ));
      if (!valid) rejected = true;
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
