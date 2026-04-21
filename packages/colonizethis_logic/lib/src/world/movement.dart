import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/package_logger.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import 'province_lookup.dart';
import 'topology_helpers.dart';
import 'unit_lookup.dart';

final _log = packageLogger();

/// Movement validation and application.
/// SPEC/program/movement.md
/// Adjacency is region-scoped when topology has multiple regions (SPEC/game/world-model-identity.md).

/// Province local ids in [regionId] that are adjacent to [localProvinceId] (P–P only).
/// Use this when topology may have duplicate local ids across regions.
/// Handles both prefixed (regionId|localId) and unprefixed topology node ids.
Iterable<String> neighborProvinceIdsInRegion(
  MapTopology topology,
  String regionId,
  String localProvinceId,
) sync* {
  final nodeIdsInRegion = provinceNodeIdsForRegion(topology, regionId);
  final localIdsInRegion = nodeIdsInRegion
      .map((id) => ProvinceId.localIdFrom(id))
      .toSet();
  if (!localIdsInRegion.contains(localProvinceId)) return;
  final idToMatch = nodeIdsInRegion.contains(localProvinceId)
      ? localProvinceId
      : ProvinceId.full(regionId, localProvinceId);
  if (!nodeIdsInRegion.contains(idToMatch)) return;
  for (final edge in topology.edges) {
    if (edge.id1 != idToMatch && edge.id2 != idToMatch) continue;
    final other = edge.id1 == idToMatch ? edge.id2 : edge.id1;
    if (nodeIdsInRegion.contains(other)) yield ProvinceId.localIdFrom(other);
  }
}

/// Validates whether a land move from [fromLocal] to [toLocal] is allowed within [regionId].
/// Use when topology has multiple regions or duplicate local ids (SPEC/game/world-model-identity.md).
bool isValidLandMoveInRegion(
  MapTopology topology,
  String regionId,
  String fromLocal,
  String toLocal,
) {
  if (fromLocal == toLocal) return false;
  return neighborProvinceIdsInRegion(topology, regionId, fromLocal)
      .contains(toLocal);
}

/// Validates whether a move from [fromProvinceId] to [toProvinceId] is allowed
/// for a land unit using [topology]. Prefer [isValidLandMoveInRegion] when
/// [regionId] is known (required when topology has duplicate local ids across regions).
bool isValidLandMove(
  MapTopology topology,
  String fromProvinceId,
  String toProvinceId,
) {
  if (fromProvinceId == toProvinceId) return false;
  final fromNodes = topology.nodes
      .where((n) =>
          n.id == fromProvinceId && n.type == TopologyNodeType.province)
      .toList();
  if (fromNodes.isEmpty) return false;
  if (fromNodes.length > 1) {
    // Duplicate local id across regions; cannot decide without regionId.
    return false;
  }
  return isValidLandMoveInRegion(
    topology,
    fromNodes.single.regionId,
    fromProvinceId,
    toProvinceId,
  );
}

({List<Unit> ow, List<Unit> nw}) _replaceCivilianUnitInSameRegion(
  List<Unit> ow,
  List<Unit> nw,
  String srcRegion,
  String unitId,
  Unit moved,
) {
  if (srcRegion == kRegionOldWorld) {
    return (
      ow: ow.map((x) => x.id == unitId ? moved : x).toList(),
      nw: nw,
    );
  }
  return (
    ow: ow,
    nw: nw.map((x) => x.id == unitId ? moved : x).toList(),
  );
}

({List<Unit> ow, List<Unit> nw}) _moveCivilianUnitAcrossRegions(
  List<Unit> ow,
  List<Unit> nw,
  String unitId,
  Unit moved,
  String destRegion,
) {
  ow.removeWhere((u) => u.id == unitId);
  nw.removeWhere((u) => u.id == unitId);
  if (destRegion == kRegionOldWorld) {
    return (ow: [...ow, moved], nw: nw);
  }
  return (ow: ow, nw: [...nw, moved]);
}

({List<Unit> ow, List<Unit> nw}) _applyCivilianMoveToWorkingUnitLists({
  required List<Unit> ow,
  required List<Unit> nw,
  required String unitId,
  required Unit moved,
  required String srcRegion,
  required String destRegion,
}) {
  if (srcRegion == destRegion) {
    return _replaceCivilianUnitInSameRegion(ow, nw, srcRegion, unitId, moved);
  }
  return _moveCivilianUnitAcrossRegions(ow, nw, unitId, moved, destRegion);
}

/// Applies civilian [MoveOrder]s (tile destinations) across both world regions.
/// Ignores military units and invalid payloads. Resolution assumes orders passed validation.
/// SPEC/program/movement.md; issue #1877.
({RegionData oldWorld, RegionData newWorld}) applyCivilianTileMoveOrdersToWorldRegions(
  Game game,
  Map<String, List<MoveOrder>> moveOrdersByPlayerId,
) {
  if (moveOrdersByPlayerId.isEmpty) {
    return (
      oldWorld: game.worldState.oldWorld,
      newWorld: game.worldState.newWorld,
    );
  }

  var ow = List<Unit>.from(game.worldState.oldWorld.units);
  var nw = List<Unit>.from(game.worldState.newWorld.units);

  Unit? findUnit(String id) {
    for (final u in ow) {
      if (u.id == id) return u;
    }
    for (final u in nw) {
      if (u.id == id) return u;
    }
    return null;
  }

  String regionHoldingUnit(String unitId) {
    if (ow.any((u) => u.id == unitId)) return kRegionOldWorld;
    if (nw.any((u) => u.id == unitId)) return kRegionNewWorld;
    return '';
  }

  var ordersSeen = 0;
  var applied = 0;
  var ignored = 0;

  final sortedPlayers = moveOrdersByPlayerId.keys.toList()..sort();
  for (final playerId in sortedPlayers) {
    for (final order in moveOrdersByPlayerId[playerId] ?? const []) {
      ordersSeen++;
      final unit = findUnit(order.unitId);
      if (unit == null) {
        ignored++;
        _log.d(
          'civilian movement ignored reason=unit_not_found '
          'unitId=${order.unitId} orderPlayerId=$playerId',
        );
        continue;
      }
      if (unit.ownerId != playerId) {
        ignored++;
        _log.d(
          'civilian movement ignored reason=owner_mismatch '
          'unitId=${order.unitId} orderPlayerId=$playerId unitOwnerId=${unit.ownerId}',
        );
        continue;
      }
      if (isMilitaryUnit(unit.type)) {
        ignored++;
        continue;
      }
      final destTile = order.destinationTileKey;
      if (destTile.isEmpty) {
        ignored++;
        continue;
      }
      final destProvince = Unit.provinceIdFromTileKey(destTile);
      if (destProvince == null) {
        ignored++;
        continue;
      }
      final destRegion = Unit.requireRegionIdFromTileKey(destTile);
      final moved = unit.copyWith(locationProvinceId: destProvince, tileKey: destTile);
      final srcRegion = regionHoldingUnit(unit.id);
      if (srcRegion.isEmpty) {
        ignored++;
        continue;
      }
      applied++;
      final lists = _applyCivilianMoveToWorkingUnitLists(
        ow: ow,
        nw: nw,
        unitId: unit.id,
        moved: moved,
        srcRegion: srcRegion,
        destRegion: destRegion,
      );
      ow = lists.ow;
      nw = lists.nw;
    }
  }

  if (ordersSeen > 0) {
    _log.i(
      'civilian tile movement apply orders=$ordersSeen applied=$applied ignored=$ignored',
    );
  }

  return (
    oldWorld: RegionData(
      provinces: game.worldState.oldWorld.provinces,
      units: ow,
    ),
    newWorld: RegionData(
      provinces: game.worldState.newWorld.provinces,
      units: nw,
    ),
  );
}

/// Legacy hook: civilian [MoveOrder] application uses
/// [applyCivilianTileMoveOrdersToWorldRegions]. This function is a no-op for move orders.
RegionData applyMoveOrdersToRegion(
  RegionData regionData,
  MapTopology topology,
  Map<String, List<MoveOrder>> moveOrdersByPlayerId, {
  String? regionId,
  Map<String, Map<String, List<String>>>? tileKeysByRegionAndProvince,
  bool Function(String playerId, String destFullProvinceId)?
      isDestinationOwnedByPlayer,
}) {
  return regionData;
}

