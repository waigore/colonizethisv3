import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import '../../orders/draft_orders_mutations.dart';
import '../../world/army_movement.dart';
import '../../world/movement.dart';
import '../../world/naval_resolution.dart';
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
