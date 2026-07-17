import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../world_constants.dart';
import 'package:colonizethis_world/src/trace/turn_trace_runtime.dart';
import 'move_order_apply_logging.dart';
import 'province_lookup.dart';
import 'region_unit_lists.dart';
import 'topology_helpers.dart';

/// Movement validation and application.
/// SPEC/program/movement.md
/// Adjacency is region-scoped when topology has multiple regions (SPEC/game/world-model-identity.md).

/// Province local ids in [regionId] that are adjacent to [localProvinceId] (P–P only).
/// Use this when topology may have duplicate local ids across regions.
/// Handles both prefixed (regionId|localId) and unprefixed topology node ids.
/// Consults cached [topologyAdjacency] rather than scanning all edges (Refs #3978).
Iterable<String> neighborProvinceIdsInRegion(
  MapTopology topology,
  String regionId,
  String localProvinceId,
) sync* {
  final nodeIdsInRegion = provinceNodeIdsForRegion(topology, regionId);
  final localIdsInRegion = nodeIdsInRegion
      .map((id) => ProvinceId.isPrefixed(id) ? ProvinceId.localIdFrom(id) : id)
      .toSet();
  if (!localIdsInRegion.contains(localProvinceId)) return;
  final idToMatch = nodeIdsInRegion.contains(localProvinceId)
      ? localProvinceId
      : ProvinceId.full(regionId, localProvinceId);
  if (!nodeIdsInRegion.contains(idToMatch)) return;
  final neighbors = topologyAdjacency(topology)[idToMatch];
  if (neighbors == null) return;
  for (final other in neighbors) {
    if (nodeIdsInRegion.contains(other)) {
      yield ProvinceId.isPrefixed(other)
          ? ProvinceId.localIdFrom(other)
          : other;
    }
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
  final fromNodes = _provinceNodesForId(topology, fromProvinceId);
  if (!_hasSingleResolvedFromNode(fromNodes)) return false;
  return isValidLandMoveInRegion(
    topology,
    fromNodes.single.regionId,
    fromProvinceId,
    toProvinceId,
  );
}

List<TopologyNode> _provinceNodesForId(
  MapTopology topology,
  String fromProvinceId,
) => topology.nodes
    .where((n) => n.id == fromProvinceId && n.type == TopologyNodeType.province)
    .toList();

bool _hasSingleResolvedFromNode(List<TopologyNode> fromNodes) {
  if (fromNodes.isEmpty) return false;
  if (fromNodes.length > 1) return false;
  return true;
}

RegionUnitLists _applyCivilianMoveToWorkingUnitLists({
  required RegionUnitLists lists,
  required String unitId,
  required Unit moved,
  required String srcRegion,
  required String destRegion,
}) {
  if (srcRegion == destRegion) {
    return lists.replaceUnitInRegion(srcRegion, unitId, moved);
  }
  return lists.moveUnitAcrossRegions(unitId, moved, destRegion);
}

/// Applies civilian [MoveOrder]s (tile destinations) across both world regions.
/// Ignores military units and invalid payloads. Resolution assumes orders passed validation.
/// Returns [game.worldState] with updated unit lists via [WorldState.mapBothRegionUnits].
/// SPEC/program/movement.md; issue #1877.
WorldState applyCivilianTileMoveOrdersToWorldRegions(
  Game game,
  Map<String, List<MoveOrder>> moveOrdersByPlayerId, {
  CivilianMoveOrderTraceCallback? onCivilianMoveOrderTrace,
}) {
  if (moveOrdersByPlayerId.isEmpty) return game.worldState;
  final result = _applyCivilianMoveOrders(
    game,
    moveOrdersByPlayerId,
    onCivilianMoveOrderTrace: onCivilianMoveOrderTrace,
  );
  logMoveOrderApplySummary(
    message:
        'civilian tile movement apply orders=${result.totals.ordersSeen} '
        'applied=${result.totals.applied} ignored=${result.totals.ignored}',
    applied: result.totals.applied,
    ignored: result.totals.ignored,
  );
  return game.worldState.mapBothRegionUnits(
    (regionId, _) => result.lists.unitListForRegion(regionId),
  );
}

CivilianMovePlayerOutcome _applyCivilianMoveOrders(
  Game game,
  Map<String, List<MoveOrder>> moveOrdersByPlayerId, {
  CivilianMoveOrderTraceCallback? onCivilianMoveOrderTrace,
}) {
  var lists = game.worldState.mutableRegionUnitLists();
  var totals = _zeroMoveTotals();
  final sortedPlayers = moveOrdersByPlayerId.keys.toList()..sort();
  for (final playerId in sortedPlayers) {
    final forPlayer = _applyCivilianMoveOrdersForPlayer(
      lists: lists,
      playerId: playerId,
      orders: moveOrdersByPlayerId[playerId] ?? const [],
      onCivilianMoveOrderTrace: onCivilianMoveOrderTrace,
    );
    lists = forPlayer.lists;
    totals = _sumMoveTotals(totals, forPlayer.totals);
  }
  return (lists: lists, totals: totals);
}

CivilianMoveTotals _zeroMoveTotals() =>
    (ordersSeen: 0, applied: 0, ignored: 0);

CivilianMoveTotals _sumMoveTotals(
  CivilianMoveTotals totals,
  CivilianMoveTotals update,
) => (
  ordersSeen: totals.ordersSeen + update.ordersSeen,
  applied: totals.applied + update.applied,
  ignored: totals.ignored + update.ignored,
);

CivilianMovePlayerOutcome _applyCivilianMoveOrdersForPlayer({
  required RegionUnitLists lists,
  required String playerId,
  required List<MoveOrder> orders,
  CivilianMoveOrderTraceCallback? onCivilianMoveOrderTrace,
}) {
  var localLists = lists;
  var totals = _zeroMoveTotals();
  for (final order in orders) {
    final one = _applyOneCivilianMoveOrder(
      localLists,
      playerId,
      order,
      onCivilianMoveOrderTrace: onCivilianMoveOrderTrace,
    );
    localLists = one.lists;
    totals = _sumPerOrderTotals(totals, one);
  }
  return (lists: localLists, totals: totals);
}

CivilianMoveTotals _sumPerOrderTotals(
  CivilianMoveTotals totals,
  CivilianMoveOrderOutcome one,
) => (
  ordersSeen: totals.ordersSeen + 1,
  applied: totals.applied + one.applied,
  ignored: totals.ignored + one.ignored,
);

CivilianMoveOrderOutcome _applyOneCivilianMoveOrder(
  RegionUnitLists lists,
  String playerId,
  MoveOrder order, {
  CivilianMoveOrderTraceCallback? onCivilianMoveOrderTrace,
}) {
  final precheck = _precheckCivilianMoveOrder(
    lists,
    playerId,
    order,
    onCivilianMoveOrderTrace: onCivilianMoveOrderTrace,
  );
  if (precheck != null) return precheck;
  final found = _findCivilianUnitAndRegion(lists, order.unitId);
  if (found == null) return _ignoredOrderOutcome(lists);
  final unit = found.unit;
  final prepared = _prepareMovedCivilianUnit(unit, order.destinationTileKey);
  if (prepared == null) {
    onCivilianMoveOrderTrace?.call(
      playerId: playerId,
      order: order,
      applied: false,
      ignoreReason: 'invalid_destination',
    );
    return _ignoredOrderOutcome(lists);
  }
  final srcRegion = found.regionId;
  if (srcRegion.isEmpty) {
    onCivilianMoveOrderTrace?.call(
      playerId: playerId,
      order: order,
      applied: false,
      ignoreReason: 'region_unknown',
    );
    return _ignoredOrderOutcome(lists);
  }
  final nextLists = _applyCivilianMoveToWorkingUnitLists(
    lists: lists,
    unitId: unit.id,
    moved: prepared.moved,
    srcRegion: srcRegion,
    destRegion: prepared.destRegion,
  );
  onCivilianMoveOrderTrace?.call(
    playerId: playerId,
    order: order,
    applied: true,
  );
  return _appliedOrderOutcome(nextLists);
}

CivilianMoveOrderOutcome _ignoredOrderOutcome(RegionUnitLists lists) =>
    (lists: lists, applied: 0, ignored: 1);

CivilianMoveOrderOutcome _appliedOrderOutcome(RegionUnitLists lists) =>
    (lists: lists, applied: 1, ignored: 0);

CivilianMoveOrderOutcome? _precheckCivilianMoveOrder(
  RegionUnitLists lists,
  String playerId,
  MoveOrder order, {
  CivilianMoveOrderTraceCallback? onCivilianMoveOrderTrace,
}) {
  final found = _findCivilianUnitAndRegion(lists, order.unitId);
  if (found == null) {
    return _ignoredMove(
      lists,
      'unit_not_found',
      order,
      playerId: playerId,
      onCivilianMoveOrderTrace: onCivilianMoveOrderTrace,
    );
  }
  final unit = found.unit;
  final ownerMismatch = _ownerMismatchPrecheck(
    lists,
    playerId,
    order,
    unit,
    onCivilianMoveOrderTrace: onCivilianMoveOrderTrace,
  );
  if (ownerMismatch != null) return ownerMismatch;
  if (isMilitaryUnit(unit.type)) {
    onCivilianMoveOrderTrace?.call(
      playerId: playerId,
      order: order,
      applied: false,
      ignoreReason: 'military_unit',
    );
    return _ignoredOrderOutcome(lists);
  }
  return null;
}

CivilianMoveOrderOutcome? _ownerMismatchPrecheck(
  RegionUnitLists lists,
  String playerId,
  MoveOrder order,
  Unit unit, {
  CivilianMoveOrderTraceCallback? onCivilianMoveOrderTrace,
}) {
  if (unit.ownerId == playerId) return null;
  return _ignoredMove(
    lists,
    'owner_mismatch',
    order,
    playerId: playerId,
    ownerId: unit.ownerId,
    onCivilianMoveOrderTrace: onCivilianMoveOrderTrace,
  );
}

CivilianMoveOrderOutcome _ignoredMove(
  RegionUnitLists lists,
  String reason,
  MoveOrder order, {
  required String playerId,
  String? ownerId,
  CivilianMoveOrderTraceCallback? onCivilianMoveOrderTrace,
}) {
  logMoveOrderIgnoredIfDebug(
    'civilian movement ignored reason=$reason unitId=${order.unitId} '
    'orderPlayerId=$playerId${ownerId == null ? '' : ' unitOwnerId=$ownerId'}',
  );
  onCivilianMoveOrderTrace?.call(
    playerId: playerId,
    order: order,
    applied: false,
    ignoreReason: reason,
  );
  return _ignoredOrderOutcome(lists);
}

({Unit unit, String regionId})? _findCivilianUnitAndRegion(
  RegionUnitLists lists,
  String unitId,
) {
  for (final regionId in [kRegionOldWorld, kRegionNewWorld]) {
    for (final u in lists.unitListForRegion(regionId)) {
      if (u.id == unitId) return (unit: u, regionId: regionId);
    }
  }
  return null;
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
