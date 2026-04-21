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
  return neighborProvinceIdsInRegion(
    topology,
    regionId,
    fromLocal,
  ).contains(toLocal);
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
      .where(
        (n) => n.id == fromProvinceId && n.type == TopologyNodeType.province,
      )
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
    return (ow: ow.map((x) => x.id == unitId ? moved : x).toList(), nw: nw);
  }
  return (ow: ow, nw: nw.map((x) => x.id == unitId ? moved : x).toList());
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
({RegionData oldWorld, RegionData newWorld})
applyCivilianTileMoveOrdersToWorldRegions(
  Game game,
  Map<String, List<MoveOrder>> moveOrdersByPlayerId,
) {
  if (moveOrdersByPlayerId.isEmpty) return _unchangedWorldRegions(game);
  final result = _applyCivilianMoveOrders(game, moveOrdersByPlayerId);
  if (result.ordersSeen > 0) {
    _log.i(
      'civilian tile movement apply orders=${result.ordersSeen} '
      'applied=${result.applied} ignored=${result.ignored}',
    );
  }
  return _toWorldRegions(game, result.ow, result.nw);
}

({RegionData oldWorld, RegionData newWorld}) _unchangedWorldRegions(
  Game game,
) => (oldWorld: game.worldState.oldWorld, newWorld: game.worldState.newWorld);

({RegionData oldWorld, RegionData newWorld}) _toWorldRegions(
  Game game,
  List<Unit> ow,
  List<Unit> nw,
) => (
  oldWorld: RegionData(
    provinces: game.worldState.oldWorld.provinces,
    units: ow,
  ),
  newWorld: RegionData(
    provinces: game.worldState.newWorld.provinces,
    units: nw,
  ),
);

({List<Unit> ow, List<Unit> nw, int ordersSeen, int applied, int ignored})
_applyCivilianMoveOrders(
  Game game,
  Map<String, List<MoveOrder>> moveOrdersByPlayerId,
) {
  var ow = List<Unit>.from(game.worldState.oldWorld.units);
  var nw = List<Unit>.from(game.worldState.newWorld.units);
  var ordersSeen = 0;
  var applied = 0;
  var ignored = 0;
  final sortedPlayers = moveOrdersByPlayerId.keys.toList()..sort();
  for (final playerId in sortedPlayers) {
    for (final order in moveOrdersByPlayerId[playerId] ?? const []) {
      ordersSeen++;
      final appliedOrder = _applyOneCivilianMoveOrder(ow, nw, playerId, order);
      ow = appliedOrder.ow;
      nw = appliedOrder.nw;
      applied += appliedOrder.applied;
      ignored += appliedOrder.ignored;
    }
  }
  return (
    ow: ow,
    nw: nw,
    ordersSeen: ordersSeen,
    applied: applied,
    ignored: ignored,
  );
}

({List<Unit> ow, List<Unit> nw, int applied, int ignored})
_applyOneCivilianMoveOrder(
  List<Unit> ow,
  List<Unit> nw,
  String playerId,
  MoveOrder order,
) {
  final unit = _findCivilianMoveUnit(ow, nw, order.unitId);
  if (unit == null)
    return _ignoredMove(ow, nw, 'unit_not_found', order, playerId: playerId);
  if (unit.ownerId != playerId) {
    return _ignoredMove(
      ow,
      nw,
      'owner_mismatch',
      order,
      playerId: playerId,
      ownerId: unit.ownerId,
    );
  }
  if (isMilitaryUnit(unit.type))
    return (ow: ow, nw: nw, applied: 0, ignored: 1);
  final prepared = _prepareMovedCivilianUnit(unit, order.destinationTileKey);
  if (prepared == null) return (ow: ow, nw: nw, applied: 0, ignored: 1);
  final srcRegion = _regionHoldingUnit(ow, nw, unit.id);
  if (srcRegion.isEmpty) return (ow: ow, nw: nw, applied: 0, ignored: 1);
  final lists = _applyCivilianMoveToWorkingUnitLists(
    ow: ow,
    nw: nw,
    unitId: unit.id,
    moved: prepared.moved,
    srcRegion: srcRegion,
    destRegion: prepared.destRegion,
  );
  return (ow: lists.ow, nw: lists.nw, applied: 1, ignored: 0);
}

({List<Unit> ow, List<Unit> nw, int applied, int ignored}) _ignoredMove(
  List<Unit> ow,
  List<Unit> nw,
  String reason,
  MoveOrder order, {
  required String playerId,
  String? ownerId,
}) {
  _log.d(
    'civilian movement ignored reason=$reason unitId=${order.unitId} '
    'orderPlayerId=$playerId${ownerId == null ? '' : ' unitOwnerId=$ownerId'}',
  );
  return (ow: ow, nw: nw, applied: 0, ignored: 1);
}

Unit? _findCivilianMoveUnit(List<Unit> ow, List<Unit> nw, String id) {
  for (final u in ow) {
    if (u.id == id) return u;
  }
  for (final u in nw) {
    if (u.id == id) return u;
  }
  return null;
}

String _regionHoldingUnit(List<Unit> ow, List<Unit> nw, String unitId) {
  if (ow.any((u) => u.id == unitId)) return kRegionOldWorld;
  if (nw.any((u) => u.id == unitId)) return kRegionNewWorld;
  return '';
}

({Unit moved, String destRegion})? _prepareMovedCivilianUnit(
  Unit unit,
  String destinationTileKey,
) {
  if (destinationTileKey.isEmpty) return null;
  final destProvince = Unit.provinceIdFromTileKey(destinationTileKey);
  if (destProvince == null) return null;
  return (
    moved: unit.copyWith(
      locationProvinceId: destProvince,
      tileKey: destinationTileKey,
    ),
    destRegion: Unit.requireRegionIdFromTileKey(destinationTileKey),
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
