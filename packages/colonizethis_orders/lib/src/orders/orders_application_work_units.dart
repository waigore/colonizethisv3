import 'dart:math';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'order_work_constants.dart';
import 'orders_application_completed_work.dart';
import 'orders_application_context.dart';
import 'orders_application_helpers.dart';
import 'orders_logging.dart';

BuildWorkState applyExploreCompletionForWorkUnit(
  BuildWorkState s,
  Unit u,
  String regionId,
) {
  final cw = u.currentWork!;
  final parsedTarget = parseTileKeyCoordinates(cw.tileKey);
  final regionIdFromWork = parsedTarget?.regionId ?? regionId;
  final provinceId =
      parsedTarget?.provinceLocalId ??
      ProvinceId.localIdFrom(u.locationProvinceId);
  final fullProvinceId = parsedTarget != null
      ? ProvinceId.full(regionIdFromWork, provinceId)
      : u.locationProvinceId;
  final tileKeys = landTileKeysForProvinceBucket(
    s.game.worldState,
    regionIdFromWork,
    fullProvinceId,
  );
  final playerId = u.ownerId;
  final vis = Map<String, String>.from(s.work.visibilityByTile[playerId] ?? {});
  for (final tk in tileKeys) {
    vis[tk] = VisibilityLevel.fullyVisible.name;
  }
  final visibilityByTile = Map<String, Map<String, String>>.from(
    s.work.visibilityByTile,
  )..[playerId] = vis;
  return s.copyWith(work: s.work.copyWith(visibilityByTile: visibilityByTile));
}

BuildWorkState applyCompletedWorkTargetForWorkUnit(
  BuildWorkState s,
  Unit u,
  CurrentWork cw,
  List<Province> Function() getProvinces,
  WorkOrderState Function(WorkOrderState, List<Province>) replaceProvinces,
) {
  return dispatchCompletedWorkTarget(
    s,
    u,
    cw,
    getProvinces,
    replaceProvinces,
    applyExploreCompletionForWorkUnit,
  );
}

BuildWorkState processWorkUnitsInRegion(
  BuildWorkState s,
  bool oldWorldUnits,
  List<Province> Function() getProvinces,
  WorkOrderState Function(WorkOrderState, List<Province>) replaceProvinces,
) {
  final unitsById = copyUnitsById(s.work.unitsByIdForRegion(oldWorldUnits));
  var current = s.copyWith(
    work: s.work.withUnitsByIdForRegion(oldWorldUnits, unitsById),
  );
  final rand = s.game.globalGameSeed != null
      ? Random(
          s.game.globalGameSeed! +
              (s.game.worldState.turnState.turnNumber * 1000),
        )
      : Random();
  for (final entry in unitsById.entries.toList()) {
    final u = entry.value;
    if (u.currentWork == null) continue;
    final cw = u.currentWork!;
    final purchaser = current.game.worldState.purchaserOfTile(cw.tileKey);
    if (purchaser != null && purchaser != u.ownerId) {
      unitsById[entry.key] = cancelUnitWork(u);
      ordersApplicationLog.d(
        'work cancelled unit=${u.id} reason=tile no longer owned tileKey=${cw.tileKey}',
      );
      continue;
    }
    if (cw.workTarget != kWorkTargetCounterSpy &&
        cw.workTarget != kWorkTargetExplore &&
        cw.workTarget != kWorkTargetPurchaseLand &&
        !isTileControlledByPlayer(current.game, u.ownerId, cw.tileKey)) {
      unitsById[entry.key] = cancelUnitWork(u);
      ordersApplicationLog.d(
        'work cancelled unit=${u.id} reason=tile no longer under control tileKey=${cw.tileKey}',
      );
      continue;
    }
    if (cw.workTarget == kWorkTargetCounterSpy) {
      // Ongoing counter-espionage; kill/defection resolved in spyResolution phase.
      continue;
    }
    current = advanceWorkUnitTick(
      current,
      unitsById,
      entry.key,
      u,
      cw,
      rand,
      getProvinces,
      replaceProvinces,
      oldWorldUnits: oldWorldUnits,
    );
  }
  return current.copyWith(
    work: current.work.withUnitsByIdForRegion(oldWorldUnits, unitsById),
  );
}

BuildWorkState advanceWorkUnitTick(
  BuildWorkState s,
  Map<String, Unit> unitsById,
  String unitKey,
  Unit u,
  CurrentWork cw,
  Random rand,
  List<Province> Function() getProvinces,
  WorkOrderState Function(WorkOrderState, List<Province>) replaceProvinces, {
  required bool oldWorldUnits,
}) {
  final nextRemaining = cw.remainingTurns - 1;
  if (nextRemaining <= 0) {
    var next = applyCompletedWorkTargetForWorkUnit(
      s,
      u,
      cw,
      getProvinces,
      replaceProvinces,
    );
    unitsById[unitKey] = cancelUnitWork(u, restoredTile: u.tileKey);
    return next.copyWith(
      work: next.work.withUnitsByIdForRegion(oldWorldUnits, unitsById),
    );
  }
  unitsById[unitKey] = u.copyWith(
    currentWork: cw.copyWith(remainingTurns: nextRemaining),
  );
  return s.copyWith(
    work: s.work.withUnitsByIdForRegion(oldWorldUnits, unitsById),
  );
}
