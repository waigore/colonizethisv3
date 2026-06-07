import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_world/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import 'package:colonizethis_world/src/trace/turn_trace_runtime.dart';
import 'army_migration.dart';
import 'movement.dart';
import 'province_lookup.dart';

/// Single-pass index of [WorldState.armies] by army id for O(1) lookups (Refs
/// #2394, SPEC/program/order-suggestions.md — incremental validation throughput
/// bounds).
///
/// Callers that iterate over many build/recruit orders against a stable
/// [WorldState] snapshot should build once and reuse the resulting map instead
/// of issuing a per-order `indexWhere`/`firstWhereOrNull` scan over
/// [WorldState.armies].
Map<String, Army> armiesByIdForWorld(WorldState world) {
  return {for (final a in world.armies) a.id: a};
}

void _logArmyMoveIgnoredHomeArmyIfDebug(String armyId) {
  if (Level.debug.value >= Logger.level.value) {
    worldLog.d('army_move ignored reason=home_army_locked armyId=$armyId');
  }
}

void _logArmyMoveIgnoredInvalidAdjacencyIfDebug(
  String armyId,
  String fromLocal,
  String toLocal,
) {
  if (Level.debug.value >= Logger.level.value) {
    worldLog.d(
      'army_move ignored reason=invalid_adjacency armyId=$armyId '
      'from=$fromLocal to=$toLocal',
    );
  }
}

/// Applies army moves in [regionId] (same-region leg). See [applyMoveOrdersToRegion].
///
/// When [onArmyMoveOrderTrace] is set, each order processed by this region pass
/// emits at most one trace event with [regionId] context. Orders that belong to
/// a different region are silently skipped without trace events to avoid
/// double-counting across both region calls; callers should pre-trace
/// global-decision rejections (army not found, owner mismatch, home army)
/// before invoking this helper.
WorldState applyArmyMoveOrdersToRegion(
  WorldState worldState,
  MapTopology topology,
  Map<String, List<ArmyMoveOrder>> ordersByPlayerId, {
  required String regionId,
  bool Function(String playerId, String destFullProvinceId)?
  isDestinationOwnedByPlayer,
  ArmyMoveOrderTraceCallback? onArmyMoveOrderTrace,
}) {
  if (ordersByPlayerId.isEmpty) {
    return worldState;
  }

  final armyById = armiesByIdForWorld(worldState);
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
        _logArmyMoveIgnoredHomeArmyIfDebug(order.armyId);
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
        onArmyMoveOrderTrace?.call(
          playerId: playerId,
          order: order,
          applied: false,
          regionId: regionId,
          ignoreReason: 'destination_in_other_region',
        );
        continue;
      }
      final destFullId = !ProvinceId.isPrefixed(destProvinceId)
          ? ProvinceId.full(regionId, destProvinceId)
          : destProvinceId;

      final fromLocal = ProvinceId.localIdFrom(army.stationedProvinceId);
      final toLocal = ProvinceId.localIdFrom(destFullId);
      final ownProvinceMove =
          isDestinationOwnedByPlayer != null &&
          isDestinationOwnedByPlayer(playerId, destFullId);
      final valid =
          ownProvinceMove ||
          isValidLandMoveInRegion(topology, regionId, fromLocal, toLocal);
      if (!valid) {
        ignored++;
        _logArmyMoveIgnoredInvalidAdjacencyIfDebug(
          order.armyId,
          fromLocal,
          toLocal,
        );
        onArmyMoveOrderTrace?.call(
          playerId: playerId,
          order: order,
          applied: false,
          regionId: regionId,
          destinationProvinceId: destFullId,
          ignoreReason: 'invalid_adjacency',
        );
        continue;
      }

      ws = updateArmyStation(ws, army.id, destFullId);
      applied++;
      onArmyMoveOrderTrace?.call(
        playerId: playerId,
        order: order,
        applied: true,
        regionId: regionId,
        destinationProvinceId: destFullId,
      );
    }
  }

  if (applied + ignored > 0) {
    worldLog.i(
      'army_move apply regionId=$regionId applied=$applied ignored=$ignored',
    );
  }
  return ws;
}

/// Cross-region moves for armies between owned provinces (instant), mirroring civilians.
///
/// When [onArmyMoveOrderTrace] is set, this helper only emits trace events for
/// orders it actually applies (cross-region instant move). Orders that fall
/// through to [remainingArmyMoveOrdersByPlayerId] are intentionally not traced
/// here so the same-region [applyArmyMoveOrdersToRegion] pass can attribute
/// the final decision without double-counting.
({
  WorldState worldState,
  Map<String, List<ArmyMoveOrder>> remainingArmyMoveOrdersByPlayerId,
})
applyCrossRegionArmyMovesWithinOwnedProvinces({
  required Game game,
  required WorldState worldState,
  required Map<String, List<ArmyMoveOrder>> armyMoveOrdersByPlayerId,
  ArmyMoveOrderTraceCallback? onArmyMoveOrderTrace,
}) {
  var ws = worldState;
  final remaining = <String, List<ArmyMoveOrder>>{};
  final armyById = armiesByIdForWorld(ws);

  for (final entry in armyMoveOrdersByPlayerId.entries) {
    final playerId = entry.key;
    final left = <ArmyMoveOrder>[];
    for (final order in entry.value) {
      final army = armyById[order.armyId];
      if (army == null || army.ownerId != playerId || army.isHomeArmy) {
        left.add(order);
        continue;
      }
      final fromRegion = ProvinceId.regionIdFrom(army.stationedProvinceId);
      final destFull = resolveToFullProvinceId(ws, order.destinationProvinceId);
      final destRegion = ProvinceId.regionIdFrom(destFull);
      final destProvince = ws.tryGetProvince(destFull);
      if (destProvince == null || destProvince.ownerId != playerId) {
        left.add(order);
        continue;
      }
      if (fromRegion == destRegion) {
        left.add(order);
        continue;
      }
      ws = updateArmyStation(ws, army.id, destFull);
      armyById[army.id] = army.copyWith(
        regionId: destRegion,
        stationedProvinceId: destFull,
      );
      onArmyMoveOrderTrace?.call(
        playerId: playerId,
        order: order,
        applied: true,
        regionId: destRegion,
        destinationProvinceId: destFull,
      );
    }
    if (left.isNotEmpty) {
      remaining[playerId] = left;
    }
  }

  return (worldState: ws, remainingArmyMoveOrdersByPlayerId: remaining);
}
