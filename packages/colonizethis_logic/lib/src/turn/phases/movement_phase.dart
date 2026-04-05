import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import '../../orders/draft_orders_mutations.dart';
import '../../world/army_movement.dart';
import '../../world/movement.dart';
import '../../world/naval_resolution.dart';
import '../../world/province_lookup.dart';
import '../../world/unit_lookup.dart';

/// Apply cross-region land moves within a player's own provinces (OldWorld ↔ NewWorld).
/// These moves ignore adjacency and complete in a single Movement phase. SPEC/program/movement.md.
({
  RegionData oldWorld,
  RegionData newWorld,
  Map<String, List<MoveOrder>> remainingMoveOrdersByPlayerId,
})
applyCrossRegionOwnProvinceMoves(
  Game game,
  Map<String, List<MoveOrder>> moveOrdersByPlayerId,
  Map<String, Map<String, List<String>>> tileKeysByRegionAndProvince,
) {
  var oldUnits = List<Unit>.from(game.worldState.oldWorld.units);
  var newUnits = List<Unit>.from(game.worldState.newWorld.units);

  final unitRegionById = <String, String>{
    for (final u in oldUnits) u.id: kRegionOldWorld,
    for (final u in newUnits) u.id: kRegionNewWorld,
  };
  final unitsById = Map<String, Unit>.from(unitsByIdFromWorld(game.worldState));

  String? firstTileFor(String regionId, String fullProvinceId) {
    final byProvince = tileKeysByRegionAndProvince[regionId];
    if (byProvince == null) return null;
    final tiles = byProvince[fullProvinceId];
    if (tiles == null || tiles.isEmpty) return null;
    return tiles.first;
  }

  final remaining = <String, List<MoveOrder>>{};

  moveOrdersByPlayerId.forEach((playerId, orders) {
    final remainingForPlayer = <MoveOrder>[];
    for (final o in orders) {
      final unit = unitsById[o.unitId];
      if (unit == null || unit.ownerId != playerId) {
        remainingForPlayer.add(o);
        continue;
      }
      final currentRegion = unitRegionById[unit.id];
      if (currentRegion == null) {
        remainingForPlayer.add(o);
        continue;
      }
      final destFullId = resolveToFullProvinceId(
        game.worldState,
        o.destinationProvinceId,
      );
      final destRegion = ProvinceId.regionIdFrom(destFullId);
      if (destRegion == currentRegion) {
        remainingForPlayer.add(o);
        continue;
      }
      final destProvince = tryGetProvince(game.worldState, destFullId);
      if (destProvince == null || destProvince.ownerId != playerId) {
        remainingForPlayer.add(o);
        continue;
      }

      final isCivilian = unit.tileKey != null && unit.tileKey!.isNotEmpty;
      final firstTile = isCivilian
          ? firstTileFor(destRegion, destFullId)
          : null;
      final movedUnit = isCivilian && firstTile != null
          ? unit.copyWith(locationProvinceId: destFullId, tileKey: firstTile)
          : unit.copyWith(locationProvinceId: destFullId);

      unitsById[unit.id] = movedUnit;
      unitRegionById[unit.id] = destRegion;

      if (currentRegion == kRegionOldWorld) {
        oldUnits = oldUnits.where((u) => u.id != unit.id).toList();
      } else if (currentRegion == kRegionNewWorld) {
        newUnits = newUnits.where((u) => u.id != unit.id).toList();
      }

      if (destRegion == kRegionOldWorld) {
        oldUnits = [...oldUnits, movedUnit];
      } else if (destRegion == kRegionNewWorld) {
        newUnits = [...newUnits, movedUnit];
      }
    }
    if (remainingForPlayer.isNotEmpty) {
      remaining[playerId] = remainingForPlayer;
    }
  });

  return (
    oldWorld: RegionData(
      provinces: game.worldState.oldWorld.provinces,
      units: oldUnits,
    ),
    newWorld: RegionData(
      provinces: game.worldState.newWorld.provinces,
      units: newUnits,
    ),
    remainingMoveOrdersByPlayerId: remaining,
  );
}

Game runMovementPhase(Game game, MapTopology topology, Orders orders) {
  var state = game;

  final moveOrders = orders.moveOrdersByPlayerId;
  final tileKeysByRegion = state.worldState.tileKeysByRegionAndProvince;
  if (moveOrders.isNotEmpty) {
    final ownerByProvinceId = <String, String?>{
      for (final p in allProvinces(state.worldState)) p.id: p.ownerId,
    };
    bool isDestinationOwnedByPlayer(
      String playerId,
      String destFullProvinceId,
    ) =>
        tryGetProvince(state.worldState, destFullProvinceId)?.ownerId ==
        playerId;

    final originalOldWorld = state.worldState.oldWorld;
    final originalNewWorld = state.worldState.newWorld;

    final crossRegionResult = applyCrossRegionOwnProvinceMoves(
      state,
      moveOrders,
      tileKeysByRegion,
    );

    final oldWorld = applyMoveOrdersToRegion(
      crossRegionResult.oldWorld,
      topology,
      crossRegionResult.remainingMoveOrdersByPlayerId,
      regionId: kRegionOldWorld,
      tileKeysByRegionAndProvince: tileKeysByRegion,
      isDestinationOwnedByPlayer: isDestinationOwnedByPlayer,
    );
    final newWorld = applyMoveOrdersToRegion(
      crossRegionResult.newWorld,
      topology,
      crossRegionResult.remainingMoveOrdersByPlayerId,
      regionId: kRegionNewWorld,
      tileKeysByRegionAndProvince: tileKeysByRegion,
      isDestinationOwnedByPlayer: isDestinationOwnedByPlayer,
    );
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

    for (final u in originalOldWorld.units) {
      if (!isSpyUnit(u.type)) continue;
      final after = oldWorld.units.where((x) => x.id == u.id).firstOrNull;
      if (after != null && after.locationProvinceId != u.locationProvinceId) {
        recordSpyLeft(u.ownerId, u.locationProvinceId);
      }
    }
    for (final u in originalNewWorld.units) {
      if (!isSpyUnit(u.type)) continue;
      final after = newWorld.units.where((x) => x.id == u.id).firstOrNull;
      if (after != null && after.locationProvinceId != u.locationProvinceId) {
        recordSpyLeft(u.ownerId, u.locationProvinceId);
      }
    }
    state = state.copyWith(
      worldState: state.worldState.copyWith(
        oldWorld: oldWorld,
        newWorld: newWorld,
        spyRevealTurnsByPlayer: spyTimers,
      ),
    );
  }

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
