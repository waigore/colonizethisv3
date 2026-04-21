import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/province_lookup.dart';
import 'build_rail_work_rules.dart';
import 'orders_application_context.dart';
import 'orders_application_helpers.dart';

void _completeInstantCivilianOrder(
  void Function(String, Unit) updateUnit,
  Unit unit,
  String targetTileKey,
) {
  updateUnit(
    unit.id,
    unit.copyWith(
      status: UnitStatus.idle,
      tileKey: targetTileKey,
      clearOriginTileKey: true,
      clearAssignedTileKey: true,
      clearCurrentWork: true,
    ),
  );
}

int _applyPurchaseLandOrder({
  required BuildWorkState state,
  required Player player,
  required Unit unit,
  required String targetTileKey,
  required int treasury,
  required Map<String, String> purchasedTilesByTileKey,
  required Province? Function(String) provinceById,
  required void Function(String, Unit) updateUnit,
}) {
  final resourceId = state.game.worldState.resourceByTileKey[targetTileKey];
  if (resourceId == null) return treasury;

  final provinceId =
      Unit.provinceIdFromTileKey(targetTileKey) ?? unit.locationProvinceId;
  final province = provinceById(provinceId);
  final ownerId = province?.ownerId;
  if (ownerId == null) return treasury;

  final hasEmbassy = state.game.overtureStates.any(
    (o) => o.gpId == player.id && o.targetId == ownerId && o.hasEmbassy,
  );
  if (!hasEmbassy) return treasury;

  final atWar = state.game.diplomacyRelations.any((rel) {
    final ids = {rel.factionId1, rel.factionId2};
    return ids.contains(player.id) && ids.contains(ownerId) && rel.atWar;
  });
  if (atWar) return treasury;

  final cost = purchaseLandCost(resourceId);
  if (treasury < cost) return treasury;
  if (purchasedTilesByTileKey.containsKey(targetTileKey)) return treasury;

  treasury -= cost;
  purchasedTilesByTileKey[targetTileKey] = player.id;
  _completeInstantCivilianOrder(updateUnit, unit, targetTileKey);
  return treasury;
}

bool _tryApplyExploreWorkOrder({
  required BuildWorkState state,
  required WorkOrder order,
  required Unit unit,
  required String targetTileKey,
  required String Function(String) regionForUnit,
  required void Function(String, Unit) updateUnit,
}) {
  final regionId = regionForUnit(order.unitId);
  final provinceId =
      Unit.provinceIdFromTileKey(targetTileKey) ?? unit.locationProvinceId;
  final byProvince = state.game.worldState.tileKeysByRegionAndProvince[regionId];
  if (byProvince == null || byProvince.isEmpty) return false;

  final tilesInP = byProvince[provinceId]?.length ?? 0;
  if (tilesInP <= 0) return false;

  var maxTiles = 1;
  for (final list in byProvince.values) {
    if (list.length > maxTiles) maxTiles = list.length;
  }
  final totalTurns = (3 * tilesInP / maxTiles).ceil().clamp(1, 999);
  ordersApplicationLog.d(
    'work order accepted and assigned unit=${order.unitId} target=explore targetTileKey=$targetTileKey totalTurns=$totalTurns',
  );
  updateUnit(
    order.unitId,
    unit.copyWith(
      status: UnitStatus.working,
      tileKey: targetTileKey,
      originTileKey: unit.originTileKey ?? unit.tileKey,
      assignedTileKey: targetTileKey,
      currentWork: CurrentWork(
        workTarget: kWorkTargetExplore,
        tileKey: targetTileKey,
        totalTurns: totalTurns,
        remainingTurns: totalTurns,
      ),
    ),
  );
  return true;
}

class _StandardWorkTargetConfig {
  const _StandardWorkTargetConfig({
    required this.allowedForUnitType,
    required this.costFn,
    required this.totalTurnsFn,
  });

  final bool Function(String) allowedForUnitType;
  final WorkOrderCost? Function() costFn;
  final int Function() totalTurnsFn;
}

_StandardWorkTargetConfig _buildStandardWorkTargetConfig({
  required String target,
  required String targetTileKey,
  required Unit unit,
  required TileState tileState,
  required Province? Function(String) provinceById,
}) {
  switch (target) {
    case kWorkTargetBuildImprovement:
      return _StandardWorkTargetConfig(
        allowedForUnitType: (t) => isWorkOrderTargetAllowedForUnitType(t, target),
        costFn: () => workOrderMaterialCost(
          target,
          improvementLevel: tileState.improvementLevel(targetTileKey),
        ),
        totalTurnsFn: () => totalTurnsForWork(
          target,
          improvementLevel: tileState.improvementLevel(targetTileKey),
        ),
      );
    case kWorkTargetBuildFort:
      return _StandardWorkTargetConfig(
        allowedForUnitType: (t) => isWorkOrderTargetAllowedForUnitType(t, target),
        costFn: () {
          final prov = provinceById(unit.locationProvinceId);
          final fortLevel = prov?.fortLevel ?? 0;
          return workOrderMaterialCost(target, fortLevel: fortLevel);
        },
        totalTurnsFn: () {
          final prov = provinceById(unit.locationProvinceId);
          final fortLevel = prov?.fortLevel ?? 0;
          return totalTurnsForWork(target, fortLevel: fortLevel);
        },
      );
    case kWorkTargetBuildRoad:
    case kWorkTargetBuildPort:
    case kWorkTargetBuildRail:
    case kWorkTargetUpgradeTown:
      return _StandardWorkTargetConfig(
        allowedForUnitType: (t) => isWorkOrderTargetAllowedForUnitType(t, target),
        costFn: () => workOrderMaterialCost(target),
        totalTurnsFn: () => totalTurnsForWork(target),
      );
    default:
      return const _StandardWorkTargetConfig(
        allowedForUnitType: _alwaysFalseForWorkTarget,
        costFn: _nullWorkOrderCost,
        totalTurnsFn: _singleTurnWorkDuration,
      );
  }
}

bool _alwaysFalseForWorkTarget(String _) => false;
WorkOrderCost? _nullWorkOrderCost() => null;
int _singleTurnWorkDuration() => 1;

bool _applyStandardWorkOrder({
  required WorkOrder order,
  required Unit unit,
  required String targetTileKey,
  required bool hasValidTarget,
  required String orderTarget,
  required TileState tileState,
  required Province? Function(String) provinceById,
  required bool Function(WorkOrderCost) canAffordMaterialCost,
  required void Function(WorkOrderCost) deductMaterialCost,
  required void Function(String, Unit) updateUnit,
}) {
  if (unit.currentWork != null || !hasValidTarget) return false;

  final config = _buildStandardWorkTargetConfig(
    target: orderTarget,
    targetTileKey: targetTileKey,
    unit: unit,
    tileState: tileState,
    provinceById: provinceById,
  );
  if (!config.allowedForUnitType(unit.type)) return false;

  final cost = config.costFn();
  if (cost == null || !canAffordMaterialCost(cost)) return false;

  deductMaterialCost(cost);
  final totalTurns = config.totalTurnsFn();
  ordersApplicationLog.d(
    'work order accepted and assigned unit=${order.unitId} target=$orderTarget targetTileKey=$targetTileKey totalTurns=$totalTurns',
  );
  updateUnit(
    order.unitId,
    unit.copyWith(
      status: UnitStatus.working,
      tileKey: targetTileKey,
      originTileKey: unit.originTileKey ?? unit.tileKey,
      assignedTileKey: targetTileKey,
      currentWork: CurrentWork(
        workTarget: orderTarget,
        tileKey: targetTileKey,
        totalTurns: totalTurns,
        remainingTurns: totalTurns,
      ),
    ),
  );
  return true;
}

bool _shouldSkipBuildFortForMissingTech({
  required Province? province,
  required Map<String, bool>? techUnlocked,
}) {
  final fortLevel = province?.fortLevel ?? 0;
  if (fortLevel == 1 && techUnlocked?[kTechIdMineEngineering] != true) {
    ordersApplicationLog.d(
      'build_fort skipped - Mine Engineering required for fort level 2',
    );
    return true;
  }
  if (fortLevel == 2 && techUnlocked?[kTechIdModernForts] != true) {
    ordersApplicationLog.d(
      'build_fort skipped - Modern Forts required for fort level 3',
    );
    return true;
  }
  return false;
}

bool _shouldSkipBuildRailForInvalidTerrainOrTech({
  required Map<String, bool>? techUnlocked,
  required int roadLevel,
  required String? terrain,
}) {
  final railReason = rejectionReasonForBuildRailOrder(
    techUnlocked: techUnlocked,
    roadLevel: roadLevel,
    terrain: terrain,
  );
  if (railReason == null) return false;
  ordersApplicationLog.d('build_rail skipped - $railReason');
  return true;
}

bool _tryAssignFixedDurationWorkOrder({
  required WorkOrder order,
  required Unit unit,
  required String targetTileKey,
  required String target,
  required int totalTurns,
  required int remainingTurns,
  required void Function(String, Unit) updateUnit,
}) {
  if (!isWorkOrderTargetAllowedForUnitType(unit.type, target)) return false;
  if (unit.currentWork != null || targetTileKey.isEmpty) return false;
  ordersApplicationLog.d(
    'work order accepted and assigned unit=${order.unitId} target=$target targetTileKey=$targetTileKey totalTurns=$totalTurns',
  );
  updateUnit(
    order.unitId,
    unit.copyWith(
      status: UnitStatus.working,
      tileKey: targetTileKey,
      originTileKey: unit.originTileKey ?? unit.tileKey,
      assignedTileKey: targetTileKey,
      currentWork: CurrentWork(
        workTarget: target,
        tileKey: targetTileKey,
        totalTurns: totalTurns,
        remainingTurns: remainingTurns,
      ),
    ),
  );
  return true;
}

void _tryApplyProspectWorkOrder({
  required BuildWorkState state,
  required Player player,
  required Unit unit,
  required String targetTileKey,
  required void Function(String, Unit) updateUnit,
}) {
  if (targetTileKey.isEmpty || unit.currentWork != null || !isExplorerUnit(unit.type)) {
    return;
  }
  if (!isMineralEligibleTile(state.game, state.tileMapByRegion, targetTileKey)) return;

  final existing = state.game.worldState.playerProspectedTiles[player.id] ?? const {};
  final newProspected = Set<String>.from(existing)..add(targetTileKey);
  state.game = state.game.copyWith(
    worldState: state.game.worldState.copyWith(
      playerProspectedTiles: {
        ...state.game.worldState.playerProspectedTiles,
        player.id: newProspected,
      },
    ),
  );
  _completeInstantCivilianOrder(updateUnit, unit, targetTileKey);
}

bool _tryApplyRemainingStandardBuildTargets({
  required String workTarget,
  required BuildWorkState state,
  required WorkOrder order,
  required Player player,
  required Unit unit,
  required String targetTileKey,
  required bool hasValidTarget,
  required TileState tileState,
  required Province? Function(String) provinceById,
  required bool Function(WorkOrderCost) canAffordMaterialCost,
  required void Function(WorkOrderCost) deductMaterialCost,
  required void Function(String, Unit) updateUnit,
}) {
  if (workTarget == kWorkTargetBuildRoad || workTarget == kWorkTargetBuildPort || workTarget == kWorkTargetUpgradeTown) {
    return _applyStandardWorkOrder(
      order: order,
      unit: unit,
      targetTileKey: targetTileKey,
      hasValidTarget: hasValidTarget,
      orderTarget: workTarget,
      tileState: tileState,
      provinceById: provinceById,
      canAffordMaterialCost: canAffordMaterialCost,
      deductMaterialCost: deductMaterialCost,
      updateUnit: updateUnit,
    );
  }
  if (workTarget == kWorkTargetBuildFort) {
    final prov = provinceById(unit.locationProvinceId);
    if (_shouldSkipBuildFortForMissingTech(
      province: prov,
      techUnlocked: player.techUnlocked,
    )) {
      return true;
    }
    return _applyStandardWorkOrder(
      order: order,
      unit: unit,
      targetTileKey: targetTileKey,
      hasValidTarget: hasValidTarget,
      orderTarget: kWorkTargetBuildFort,
      tileState: tileState,
      provinceById: provinceById,
      canAffordMaterialCost: canAffordMaterialCost,
      deductMaterialCost: deductMaterialCost,
      updateUnit: updateUnit,
    );
  }
  if (workTarget != kWorkTargetBuildRail) return false;
  if (_shouldSkipBuildRailForInvalidTerrainOrTech(
    techUnlocked: player.techUnlocked,
    roadLevel: tileState.roadLevel(targetTileKey),
    terrain: terrainTypeForTileKey(state.tileMapByRegion, targetTileKey),
  )) {
    return true;
  }
  return _applyStandardWorkOrder(
    order: order,
    unit: unit,
    targetTileKey: targetTileKey,
    hasValidTarget: hasValidTarget,
    orderTarget: kWorkTargetBuildRail,
    tileState: tileState,
    provinceById: provinceById,
    canAffordMaterialCost: canAffordMaterialCost,
    deductMaterialCost: deductMaterialCost,
    updateUnit: updateUnit,
  );
}

void runWorkPhase(
  BuildWorkState state,
  void Function(BuildWorkState, Unit, String) applyExploreCompletion,
  void Function(
    BuildWorkState,
    Unit,
    CurrentWork,
    List<Province> Function(),
    void Function(List<Province>),
  )
  applyCompletedWorkTarget,
) {
  final workOrders = state.workOrders;
  final tileState = state.work.tileState;
  final oldUnitsById = state.work.oldUnitsById;
  final newUnitsById = state.work.newUnitsById;
  final purchasedTilesByTileKey = state.work.purchasedTilesByTileKey;

  for (final player in state.game.players) {
    var stockpile = player.stockpile;
    var workers = player.workerPool;
    var treasury = player.treasury;

    Unit? lookupUnit(String unitId) =>
        oldUnitsById[unitId] ?? newUnitsById[unitId];

    void updateUnit(String unitId, Unit updated) {
      if (oldUnitsById.containsKey(unitId)) {
        oldUnitsById[unitId] = updated;
      } else {
        newUnitsById[unitId] = updated;
      }
    }

    String regionForUnit(String unitId) =>
        oldUnitsById.containsKey(unitId) ? kRegionOldWorld : kRegionNewWorld;

    Province? provinceById(String id) =>
        state.game.worldState.tryGetProvince(id);

    bool canAffordMaterialCost(WorkOrderCost cost) {
      for (final e in cost.entries) {
        if (stockpile.quantityOf(e.key) < e.value) return false;
      }
      return true;
    }

    void deductMaterialCost(WorkOrderCost cost) {
      for (final e in cost.entries) {
        stockpile = stockpile.applyDelta(e.key, -e.value);
      }
    }

    for (final order in workOrders[player.id] ?? const []) {
      final u = lookupUnit(order.unitId);
      if (u == null) continue;
      final targetTileKey = order.targetTileKey;
      final hasValidTarget = targetTileKey.isNotEmpty;

      if (order.target == kWorkTargetPurchaseLand &&
          isWorkOrderTargetAllowedForUnitType(
            u.type,
            kWorkTargetPurchaseLand,
          ) &&
          u.currentWork == null &&
          hasValidTarget) {
        // SPEC/game/diplomacy.md (GP–Minor/Tribe Rules): purchase_land requires an Embassy
        // with the Minor/Tribe and the buyer must not be at war with that faction.
        treasury = _applyPurchaseLandOrder(
          state: state,
          player: player,
          unit: u,
          targetTileKey: targetTileKey,
          treasury: treasury,
          purchasedTilesByTileKey: purchasedTilesByTileKey,
          provinceById: provinceById,
          updateUnit: updateUnit,
        );
        continue;
      }

      if (order.target == kWorkTargetStealTech &&
          _tryAssignFixedDurationWorkOrder(
            order: order,
            unit: u,
            targetTileKey: targetTileKey,
            target: kWorkTargetStealTech,
            totalTurns: totalTurnsForWork(kWorkTargetStealTech),
            remainingTurns: totalTurnsForWork(kWorkTargetStealTech),
            updateUnit: updateUnit,
          )) {
        continue;
      }

      if (order.target == kWorkTargetCounterSpy &&
          _tryAssignFixedDurationWorkOrder(
            order: order,
            unit: u,
            targetTileKey: targetTileKey,
            target: kWorkTargetCounterSpy,
            totalTurns: totalTurnsForWork(kWorkTargetCounterSpy),
            remainingTurns: 1,
            updateUnit: updateUnit,
          )) {
        continue;
      }

      if (order.target == kWorkTargetProspect) {
        _tryApplyProspectWorkOrder(
          state: state,
          player: player,
          unit: u,
          targetTileKey: targetTileKey,
          updateUnit: updateUnit,
        );
      }
      if (order.target == kWorkTargetBuildImprovement) {
        if (_applyStandardWorkOrder(
          order: order,
          unit: u,
          targetTileKey: targetTileKey,
          hasValidTarget: hasValidTarget,
          orderTarget: kWorkTargetBuildImprovement,
          tileState: tileState,
          provinceById: provinceById,
          canAffordMaterialCost: canAffordMaterialCost,
          deductMaterialCost: deductMaterialCost,
          updateUnit: updateUnit,
        )) {
          continue;
        }
      }
      if (order.target == kWorkTargetExplore &&
          isExplorerUnit(u.type) &&
          u.currentWork == null &&
          hasValidTarget) {
        if (_tryApplyExploreWorkOrder(
          state: state,
          order: order,
          unit: u,
          targetTileKey: targetTileKey,
          regionForUnit: regionForUnit,
          updateUnit: updateUnit,
        )) {
          continue;
        }
      }
      if (_tryApplyRemainingStandardBuildTargets(
        workTarget: order.target,
        state: state,
        order: order,
        player: player,
        unit: u,
        targetTileKey: targetTileKey,
        hasValidTarget: hasValidTarget,
        tileState: tileState,
        provinceById: provinceById,
        canAffordMaterialCost: canAffordMaterialCost,
        deductMaterialCost: deductMaterialCost,
        updateUnit: updateUnit,
      )) {
        continue;
      }
    }

    state.work.updatedPlayers.add(
      player.copyWith(
        stockpile: stockpile,
        workerPool: workers,
        treasury: treasury,
      ),
    );
  }
}
