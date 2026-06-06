import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:logger/logger.dart';

import '../constants.dart';
import '../trace/turn_trace_runtime.dart';
import 'province_lookup.dart';
import 'topology_helpers.dart';
import 'unit_lookup.dart';

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
      .map((id) => ProvinceId.isPrefixed(id) ? ProvinceId.localIdFrom(id) : id)
      .toSet();
  if (!localIdsInRegion.contains(localProvinceId)) return;
  final idToMatch = nodeIdsInRegion.contains(localProvinceId)
      ? localProvinceId
      : ProvinceId.full(regionId, localProvinceId);
  if (!nodeIdsInRegion.contains(idToMatch)) return;
  for (final edge in topology.edges) {
    if (edge.id1 != idToMatch && edge.id2 != idToMatch) continue;
    final other = edge.id1 == idToMatch ? edge.id2 : edge.id1;
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
  Map<String, List<MoveOrder>> moveOrdersByPlayerId, {
  CivilianMoveOrderTraceCallback? onCivilianMoveOrderTrace,
}) {
  if (moveOrdersByPlayerId.isEmpty) return _unchangedWorldRegions(game);
  final result = _applyCivilianMoveOrders(
    game,
    moveOrdersByPlayerId,
    onCivilianMoveOrderTrace: onCivilianMoveOrderTrace,
  );
  if (result.ordersSeen > 0) {
    logicLog.i(
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
) {
  final ws = game.worldState.mapBothRegionUnits((regionId, _) {
    return regionId == kRegionOldWorld ? ow : nw;
  });
  return (oldWorld: ws.oldWorld, newWorld: ws.newWorld);
}

({List<Unit> ow, List<Unit> nw, int ordersSeen, int applied, int ignored})
_applyCivilianMoveOrders(
  Game game,
  Map<String, List<MoveOrder>> moveOrdersByPlayerId, {
  CivilianMoveOrderTraceCallback? onCivilianMoveOrderTrace,
}) {
  final initialLists = _initialUnitListsForCivilianMoves(game);
  var ow = initialLists.ow;
  var nw = initialLists.nw;
  var totals = _zeroMoveTotals();
  final sortedPlayers = moveOrdersByPlayerId.keys.toList()..sort();
  for (final playerId in sortedPlayers) {
    final forPlayer = _applyCivilianMoveOrdersForPlayer(
      ow: ow,
      nw: nw,
      playerId: playerId,
      orders: moveOrdersByPlayerId[playerId] ?? const [],
      onCivilianMoveOrderTrace: onCivilianMoveOrderTrace,
    );
    ow = forPlayer.ow;
    nw = forPlayer.nw;
    totals = _sumMoveTotals(totals, forPlayer);
  }
  return _withListsAndTotals(ow, nw, totals);
}

({List<Unit> ow, List<Unit> nw}) _initialUnitListsForCivilianMoves(Game game) {
  final unitsByRegion = game.worldState.mutableUnitListsByRegion();
  return (
    ow: unitsByRegion[kRegionOldWorld]!,
    nw: unitsByRegion[kRegionNewWorld]!,
  );
}

({int ordersSeen, int applied, int ignored}) _zeroMoveTotals() =>
    (ordersSeen: 0, applied: 0, ignored: 0);

({int ordersSeen, int applied, int ignored}) _sumMoveTotals(
  ({int ordersSeen, int applied, int ignored}) totals,
  ({List<Unit> ow, List<Unit> nw, int ordersSeen, int applied, int ignored})
  update,
) => (
  ordersSeen: totals.ordersSeen + update.ordersSeen,
  applied: totals.applied + update.applied,
  ignored: totals.ignored + update.ignored,
);

({List<Unit> ow, List<Unit> nw, int ordersSeen, int applied, int ignored})
_withListsAndTotals(
  List<Unit> ow,
  List<Unit> nw,
  ({int ordersSeen, int applied, int ignored}) totals,
) => (
  ow: ow,
  nw: nw,
  ordersSeen: totals.ordersSeen,
  applied: totals.applied,
  ignored: totals.ignored,
);

({List<Unit> ow, List<Unit> nw, int ordersSeen, int applied, int ignored})
_applyCivilianMoveOrdersForPlayer({
  required List<Unit> ow,
  required List<Unit> nw,
  required String playerId,
  required List<MoveOrder> orders,
  CivilianMoveOrderTraceCallback? onCivilianMoveOrderTrace,
}) {
  var localOw = ow;
  var localNw = nw;
  var totals = _zeroMoveTotals();
  for (final order in orders) {
    final one = _applyOneCivilianMoveOrder(
      localOw,
      localNw,
      playerId,
      order,
      onCivilianMoveOrderTrace: onCivilianMoveOrderTrace,
    );
    localOw = one.ow;
    localNw = one.nw;
    totals = _sumPerOrderTotals(totals, one);
  }
  return _withListsAndTotals(localOw, localNw, totals);
}

({int ordersSeen, int applied, int ignored}) _sumPerOrderTotals(
  ({int ordersSeen, int applied, int ignored}) totals,
  ({List<Unit> ow, List<Unit> nw, int applied, int ignored}) one,
) => (
  ordersSeen: totals.ordersSeen + 1,
  applied: totals.applied + one.applied,
  ignored: totals.ignored + one.ignored,
);

({List<Unit> ow, List<Unit> nw, int applied, int ignored})
_applyOneCivilianMoveOrder(
  List<Unit> ow,
  List<Unit> nw,
  String playerId,
  MoveOrder order, {
  CivilianMoveOrderTraceCallback? onCivilianMoveOrderTrace,
}) {
  final precheck = _precheckCivilianMoveOrder(
    ow,
    nw,
    playerId,
    order,
    onCivilianMoveOrderTrace: onCivilianMoveOrderTrace,
  );
  if (precheck != null) return precheck;
  final unit = _findCivilianMoveUnit(ow, nw, order.unitId);
  if (unit == null) return (ow: ow, nw: nw, applied: 0, ignored: 1);
  final prepared = _prepareMovedCivilianUnit(unit, order.destinationTileKey);
  if (prepared == null) {
    onCivilianMoveOrderTrace?.call(
      playerId: playerId,
      order: order,
      applied: false,
      ignoreReason: 'invalid_destination',
    );
    return (ow: ow, nw: nw, applied: 0, ignored: 1);
  }
  final srcRegion = _regionHoldingUnit(ow, nw, unit.id);
  if (srcRegion.isEmpty) {
    onCivilianMoveOrderTrace?.call(
      playerId: playerId,
      order: order,
      applied: false,
      ignoreReason: 'region_unknown',
    );
    return (ow: ow, nw: nw, applied: 0, ignored: 1);
  }
  final lists = _applyCivilianMoveToWorkingUnitLists(
    ow: ow,
    nw: nw,
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
  return _appliedMoveResult(lists.ow, lists.nw);
}

({List<Unit> ow, List<Unit> nw, int applied, int ignored}) _ignoredWithoutLog(
  List<Unit> ow,
  List<Unit> nw,
) => (ow: ow, nw: nw, applied: 0, ignored: 1);

({List<Unit> ow, List<Unit> nw, int applied, int ignored}) _appliedMoveResult(
  List<Unit> ow,
  List<Unit> nw,
) => (ow: ow, nw: nw, applied: 1, ignored: 0);

({List<Unit> ow, List<Unit> nw, int applied, int ignored})?
_precheckCivilianMoveOrder(
  List<Unit> ow,
  List<Unit> nw,
  String playerId,
  MoveOrder order, {
  CivilianMoveOrderTraceCallback? onCivilianMoveOrderTrace,
}) {
  final unit = _findCivilianMoveUnit(ow, nw, order.unitId);
  if (unit == null) {
    return _ignoredMove(
      ow,
      nw,
      'unit_not_found',
      order,
      playerId: playerId,
      onCivilianMoveOrderTrace: onCivilianMoveOrderTrace,
    );
  }
  final ownerMismatch = _ownerMismatchPrecheck(
    ow,
    nw,
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
    return _ignoredWithoutLog(ow, nw);
  }
  return null;
}

({List<Unit> ow, List<Unit> nw, int applied, int ignored})?
_ownerMismatchPrecheck(
  List<Unit> ow,
  List<Unit> nw,
  String playerId,
  MoveOrder order,
  Unit unit, {
  CivilianMoveOrderTraceCallback? onCivilianMoveOrderTrace,
}) {
  if (unit.ownerId == playerId) return null;
  return _ignoredMove(
    ow,
    nw,
    'owner_mismatch',
    order,
    playerId: playerId,
    ownerId: unit.ownerId,
    onCivilianMoveOrderTrace: onCivilianMoveOrderTrace,
  );
}

({List<Unit> ow, List<Unit> nw, int applied, int ignored}) _ignoredMove(
  List<Unit> ow,
  List<Unit> nw,
  String reason,
  MoveOrder order, {
  required String playerId,
  String? ownerId,
  CivilianMoveOrderTraceCallback? onCivilianMoveOrderTrace,
}) {
  if (Level.debug.value >= Logger.level.value) {
    logicLog.d(
      'civilian movement ignored reason=$reason unitId=${order.unitId} '
      'orderPlayerId=$playerId${ownerId == null ? '' : ' unitOwnerId=$ownerId'}',
    );
  }
  onCivilianMoveOrderTrace?.call(
    playerId: playerId,
    order: order,
    applied: false,
    ignoreReason: reason,
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
  for (final u in ow) {
    if (u.id == unitId) return kRegionOldWorld;
  }
  for (final u in nw) {
    if (u.id == unitId) return kRegionNewWorld;
  }
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
