import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import '../../orders/bundled_civilian_work_order.dart';
import '../../orders/draft_orders_mutations.dart';
import '../../world/army_movement.dart';
import '../../world/movement.dart';
import '../../world/naval_resolution.dart';
import '../../world/player_view.dart';
import '../../world/province_lookup.dart';
import '../../world/unit_lookup.dart';

Game runMovementPhase(Game game, MapTopology topology, Orders orders) {
  var state = game;

  final moveOrders = orders.moveOrdersByPlayerId;
  if (moveOrders.isNotEmpty) {
    final ownerByProvinceId = <String, String?>{
      for (final p in allProvinces(state.worldState)) p.id: p.ownerId,
    };

    final originalOldWorld = state.worldState.oldWorld;
    final originalNewWorld = state.worldState.newWorld;

    final tiled = applyCivilianTileMoveOrdersToWorldRegions(state, moveOrders);
    final oldWorld = tiled.oldWorld;
    final newWorld = tiled.newWorld;
    final spyTimers = Map<String, Map<String, int>>.from(
      state.worldState.spyRevealTurnsByPlayer.map(
        (k, v) => MapEntry(k, Map<String, int>.from(v)),
      ),
    );
    void recordSpyLeft(String ownerId, String provinceId) {
      final provinceOwner = ownerByProvinceId[provinceId];
      if (provinceOwner == null || provinceOwner == ownerId) {
        return;
      }
      spyTimers.putIfAbsent(ownerId, () => {})[provinceId] = 5;
    }

    void recordSpyProvinceChanges(RegionData before, RegionData after) {
      for (final u in before.units) {
        if (!isSpyUnit(u.type)) continue;
        final idx = after.units.indexWhere((x) => x.id == u.id);
        if (idx < 0) continue;
        final afterUnit = after.units[idx];
        if (afterUnit.locationProvinceId != u.locationProvinceId) {
          recordSpyLeft(u.ownerId, u.locationProvinceId);
        }
      }
    }

    recordSpyProvinceChanges(originalOldWorld, oldWorld);
    recordSpyProvinceChanges(originalNewWorld, newWorld);
    state = state.copyWith(
      worldState: state.worldState.copyWith(
        oldWorld: oldWorld,
        newWorld: newWorld,
        spyRevealTurnsByPlayer: spyTimers,
      ),
    );
  }
  state = applyImplicitBundledCivilianWorkOrderMoves(state, topology, orders);

  final armyMoveOrders = orders.armyMoveOrdersByPlayerId;
  if (armyMoveOrders.isNotEmpty) {
    bool isDestinationOwnedByPlayer(
      String playerId,
      String destFullProvinceId,
    ) =>
        tryGetProvince(state.worldState, destFullProvinceId)?.ownerId ==
        playerId;

    final cross = applyCrossRegionArmyMovesWithinOwnedProvinces(
      game: state,
      worldState: state.worldState,
      armyMoveOrdersByPlayerId: armyMoveOrders,
    );
    var ws = cross.worldState;
    final remaining = cross.remainingArmyMoveOrdersByPlayerId;
    ws = applyArmyMoveOrdersToRegion(
      ws,
      topology,
      remaining,
      regionId: kRegionOldWorld,
      isDestinationOwnedByPlayer: isDestinationOwnedByPlayer,
    );
    ws = applyArmyMoveOrdersToRegion(
      ws,
      topology,
      remaining,
      regionId: kRegionNewWorld,
      isDestinationOwnedByPlayer: isDestinationOwnedByPlayer,
    );
    state = state.copyWith(worldState: ws);
  }

  final navalOrders = orders.navalMoveOrdersByPlayerId;
  if (navalOrders.isNotEmpty) {
    state = applyNavalMovesAndShipReveal(state, topology, navalOrders);
  }

  final missionOrders = navalMissionOrdersRespectingNavalMoves(
    orders.navalMissionOrdersByPlayerId,
    orders.navalMoveOrdersByPlayerId,
  );
  state = applyNavalMissionOrders(state, missionOrders);

  return state;
}

Game applyImplicitBundledCivilianWorkOrderMoves(
  Game game,
  MapTopology topology,
  Orders orders,
) {
  var state = game;
  final workByPlayerId = orders.workOrdersByPlayerId;
  if (workByPlayerId.isEmpty) {
    return state;
  }

  for (final entry in workByPlayerId.entries) {
    final playerId = entry.key;
    final diplomatic =
        orders.diplomaticOrdersByPlayerId[playerId] ??
        const <DiplomaticOrder>[];
    for (final workOrder in entry.value) {
      final unitById = unitsByIdFromWorld(state.worldState);
      final unit = unitById[workOrder.unitId];
      if (unit == null || unit.ownerId != playerId) {
        continue;
      }
      if (!civilianBundledWorkNeedsProvinceMoveLeg(state, unit, workOrder)) {
        continue;
      }
      final destination = executionProvinceFullIdFromWorkOrder(
        state,
        workOrder,
      );
      if (destination == null) {
        continue;
      }
      final view = buildPlayerView(state, topology, playerId);
      final destinationTile = firstLegalBundledEntryTileKeyInProvince(
        game: state,
        topology: topology,
        playerId: playerId,
        unit: unit,
        destProvinceFullId: destination,
        preferredTargetTileKey: workOrder.targetTileKey,
        view: view,
        unitsById: unitById,
        diplomaticOrders: diplomatic,
      );
      if (destinationTile == null) {
        continue;
      }

      final destinationRegion = ProvinceId.regionIdFrom(destination);
      final inOldWorld = destinationRegion == kRegionOldWorld;
      final oldUnits = [...state.worldState.oldWorld.units];
      final newUnits = [...state.worldState.newWorld.units];
      oldUnits.removeWhere((u) => u.id == unit.id);
      newUnits.removeWhere((u) => u.id == unit.id);
      final movedUnit = unit.copyWith(
        locationProvinceId: destination,
        tileKey: destinationTile,
      );
      if (inOldWorld) {
        oldUnits.add(movedUnit);
      } else {
        newUnits.add(movedUnit);
      }
      state = state.copyWith(
        worldState: state.worldState.copyWith(
          oldWorld: RegionData(
            provinces: state.worldState.oldWorld.provinces,
            units: oldUnits,
          ),
          newWorld: RegionData(
            provinces: state.worldState.newWorld.provinces,
            units: newUnits,
          ),
        ),
      );
    }
  }
  return state;
}
