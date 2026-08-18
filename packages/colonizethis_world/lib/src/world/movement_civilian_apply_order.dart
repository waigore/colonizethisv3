import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../world_constants.dart';
import 'package:colonizethis_world/src/trace/turn_trace_runtime.dart';
import 'move_order_apply_logging.dart';
import 'region_unit_lists.dart';

/// Applies one civilian tile-move order. Invalid payloads are ignored.
/// SPEC/program/movement.md; issue #1877 / #4515.
CivilianMoveOrderOutcome applyOneCivilianMoveOrder(
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
