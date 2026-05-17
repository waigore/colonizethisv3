import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import '../build_rail_work_rules.dart';
import 'work_order_handler.dart';

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
  required TileMapState tileState,
  required Province? Function(String) provinceById,
}) {
  switch (target) {
    case kWorkTargetBuildImprovement:
      return _StandardWorkTargetConfig(
        allowedForUnitType: (t) =>
            isWorkOrderTargetAllowedForUnitType(t, target),
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
        allowedForUnitType: (t) =>
            isWorkOrderTargetAllowedForUnitType(t, target),
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
        allowedForUnitType: (t) =>
            isWorkOrderTargetAllowedForUnitType(t, target),
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

bool applyStandardWorkOrder({
  required WorkOrder order,
  required Unit unit,
  required String targetTileKey,
  required bool hasValidTarget,
  required String orderTarget,
  required TileMapState tileState,
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
  logicLog.d(
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

bool shouldSkipBuildFortForMissingTech({
  required Province? province,
  required Map<String, bool>? techUnlocked,
}) {
  final fortLevel = province?.fortLevel ?? 0;
  if (fortLevel == 1 && techUnlocked?[kTechIdMineEngineering] != true) {
    logicLog.d('build_fort skipped - Mine Engineering required for fort level 2');
    return true;
  }
  if (fortLevel == 2 && techUnlocked?[kTechIdModernForts] != true) {
    logicLog.d('build_fort skipped - Modern Forts required for fort level 3');
    return true;
  }
  return false;
}

bool shouldSkipBuildRailForInvalidTerrainOrTech({
  required Map<String, bool>? techUnlocked,
  required int roadLevel,
  required TerrainType? terrain,
}) {
  final railReason = rejectionReasonForBuildRailOrder(
    techUnlocked: techUnlocked,
    roadLevel: roadLevel,
    terrain: terrain,
  );
  if (railReason == null) return false;
  logicLog.d('build_rail skipped - $railReason');
  return true;
}

bool tryApplyRemainingStandardBuildTargets({
  required String workTarget,
  required WorkOrder order,
  required Player player,
  required Unit unit,
  required String targetTileKey,
  required bool hasValidTarget,
  required TileMapState tileState,
  required Province? Function(String) provinceById,
  required bool Function(WorkOrderCost) canAffordMaterialCost,
  required void Function(WorkOrderCost) deductMaterialCost,
  required void Function(String, Unit) updateUnit,
  required TerrainType? terrain,
}) {
  if (workTarget == kWorkTargetBuildRoad ||
      workTarget == kWorkTargetBuildPort ||
      workTarget == kWorkTargetUpgradeTown) {
    return applyStandardWorkOrder(
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
    if (shouldSkipBuildFortForMissingTech(
      province: prov,
      techUnlocked: player.techUnlocked,
    )) {
      return true;
    }
    return applyStandardWorkOrder(
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
  if (shouldSkipBuildRailForInvalidTerrainOrTech(
    techUnlocked: player.techUnlocked,
    roadLevel: tileState.roadLevel(targetTileKey),
    terrain: terrain,
  )) {
    return true;
  }
  return applyStandardWorkOrder(
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

class BuildImprovementWorkOrderHandler implements WorkOrderHandler {
  const BuildImprovementWorkOrderHandler();

  @override
  bool supports(String target) => target == kWorkTargetBuildImprovement;

  @override
  bool tryApply(
    WorkOrderExecutionContext context,
    WorkOrder order,
    Unit unit,
    String targetTileKey,
    bool hasValidTarget,
  ) {
    return applyStandardWorkOrder(
      order: order,
      unit: unit,
      targetTileKey: targetTileKey,
      hasValidTarget: hasValidTarget,
      orderTarget: kWorkTargetBuildImprovement,
      tileState: context.state.work.tileState,
      provinceById: context.provinceById,
      canAffordMaterialCost: context.canAffordMaterialCost,
      deductMaterialCost: context.deductMaterialCost,
      updateUnit: context.updateUnit,
    );
  }
}

class RemainingStandardBuildTargetsWorkOrderHandler
    implements WorkOrderHandler {
  const RemainingStandardBuildTargetsWorkOrderHandler();

  @override
  bool supports(String target) {
    return target == kWorkTargetBuildRoad ||
        target == kWorkTargetBuildPort ||
        target == kWorkTargetUpgradeTown ||
        target == kWorkTargetBuildFort ||
        target == kWorkTargetBuildRail;
  }

  @override
  bool tryApply(
    WorkOrderExecutionContext context,
    WorkOrder order,
    Unit unit,
    String targetTileKey,
    bool hasValidTarget,
  ) {
    return tryApplyRemainingStandardBuildTargets(
      workTarget: order.target,
      order: order,
      player: context.player,
      unit: unit,
      targetTileKey: targetTileKey,
      hasValidTarget: hasValidTarget,
      tileState: context.state.work.tileState,
      provinceById: context.provinceById,
      canAffordMaterialCost: context.canAffordMaterialCost,
      deductMaterialCost: context.deductMaterialCost,
      updateUnit: context.updateUnit,
      terrain: terrainTypeForTileKey(
        context.state.tileMapByRegion,
        targetTileKey,
      ),
    );
  }
}
