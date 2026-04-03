import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'army_migration.dart';
import 'movement.dart';
import 'province_lookup.dart';

final _log = logicLogger();

/// Applies army moves in [regionId] (same-region leg). See [applyMoveOrdersToRegion].
WorldState applyArmyMoveOrdersToRegion(
  WorldState worldState,
  MapTopology topology,
  Map<String, List<ArmyMoveOrder>> ordersByPlayerId, {
  required String regionId,
  bool Function(String playerId, String destFullProvinceId)?
      isDestinationOwnedByPlayer,
}) {
  if (ordersByPlayerId.isEmpty) {
    return worldState;
  }

  final armyById = {for (final a in worldState.armies) a.id: a};
  var ws = worldState;
  var applied = 0;
  var ignored = 0;

  for (final entry in ordersByPlayerId.entries) {
    final playerId = entry.key;
    for (final order in entry.value) {
      final army = armyById[order.armyId];
      if (army == null) {
        ignored++;
        continue;
      }
      if (army.ownerId != playerId) {
        ignored++;
        continue;
      }
      if (army.isHomeArmy) {
        ignored++;
        _log.d(
          'army_move ignored reason=home_army_locked armyId=${order.armyId}',
        );
        continue;
      }
      if (ProvinceId.regionIdFrom(army.stationedProvinceId) != regionId) {
        ignored++;
        continue;
      }
      final destProvinceId = order.destinationProvinceId;
      if (ProvinceId.isPrefixed(destProvinceId) &&
          ProvinceId.regionIdFrom(destProvinceId) != regionId) {
        ignored++;
        continue;
      }
      final destFullId = !ProvinceId.isPrefixed(destProvinceId)
          ? ProvinceId.full(regionId, destProvinceId)
          : destProvinceId;

      final fromLocal = ProvinceId.localIdFrom(army.stationedProvinceId);
      final toLocal = ProvinceId.localIdFrom(destFullId);
      final ownProvinceMove = isDestinationOwnedByPlayer != null &&
          isDestinationOwnedByPlayer(playerId, destFullId);
      final valid = ownProvinceMove ||
          isValidLandMoveInRegion(topology, regionId, fromLocal, toLocal);
      if (!valid) {
        ignored++;
        _log.d(
          'army_move ignored reason=invalid_adjacency armyId=${order.armyId} '
          'from=$fromLocal to=$toLocal',
        );
        continue;
      }

      ws = updateArmyStation(ws, army.id, destFullId);
      applied++;
    }
  }

  if (applied + ignored > 0) {
    _log.i(
      'army_move apply regionId=$regionId applied=$applied ignored=$ignored',
    );
  }
  return ws;
}

/// Cross-region moves for armies between owned provinces (instant), mirroring civilians.
({
  WorldState worldState,
  Map<String, List<ArmyMoveOrder>> remainingArmyMoveOrdersByPlayerId,
}) applyCrossRegionArmyMovesWithinOwnedProvinces({
  required Game game,
  required WorldState worldState,
  required Map<String, List<ArmyMoveOrder>> armyMoveOrdersByPlayerId,
}) {
  var ws = worldState;
  final remaining = <String, List<ArmyMoveOrder>>{};

  for (final entry in armyMoveOrdersByPlayerId.entries) {
    final playerId = entry.key;
    final left = <ArmyMoveOrder>[];
    for (final order in entry.value) {
      final armyMap = {for (final a in ws.armies) a.id: a};
      final army = armyMap[order.armyId];
      if (army == null || army.ownerId != playerId || army.isHomeArmy) {
        left.add(order);
        continue;
      }
      final fromRegion = ProvinceId.regionIdFrom(army.stationedProvinceId);
      final destFull = resolveToFullProvinceId(ws, order.destinationProvinceId);
      final destRegion = ProvinceId.regionIdFrom(destFull);
      final destProvince = tryGetProvince(ws, destFull);
      if (destProvince == null || destProvince.ownerId != playerId) {
        left.add(order);
        continue;
      }
      if (fromRegion == destRegion) {
        left.add(order);
        continue;
      }
      ws = updateArmyStation(ws, army.id, destFull);
    }
    if (left.isNotEmpty) {
      remaining[playerId] = left;
    }
  }

  return (
    worldState: ws,
    remainingArmyMoveOrdersByPlayerId: remaining,
  );
}
