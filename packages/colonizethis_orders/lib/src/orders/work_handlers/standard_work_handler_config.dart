import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../orders_logging.dart';
import '../order_work_constants.dart';
import '../build_rail_work_rules.dart';
import '../validators/work_order_cost_calculator.dart';

class StandardWorkTargetConfig {
  const StandardWorkTargetConfig({
    required this.allowedForUnitType,
    required this.costFn,
    required this.totalTurnsFn,
  });

  final bool Function(String) allowedForUnitType;
  final WorkOrderCost? Function() costFn;
  final int Function() totalTurnsFn;
}

/// Declarative cost/turn strategy for each standard build work target (Refs
/// #3877). Fixed-material targets share one resolver; improvement and fort
/// retain context-sensitive cost/turn wiring.
enum StandardWorkTargetKind {
  fixedMaterial,
  improvement,
  fort,
}

const Map<String, StandardWorkTargetKind> standardWorkTargetKinds = {
  kWorkTargetBuildImprovement: StandardWorkTargetKind.improvement,
  kWorkTargetBuildFort: StandardWorkTargetKind.fort,
  kWorkTargetBuildRoad: StandardWorkTargetKind.fixedMaterial,
  kWorkTargetBuildPort: StandardWorkTargetKind.fixedMaterial,
  kWorkTargetBuildRail: StandardWorkTargetKind.fixedMaterial,
  kWorkTargetUpgradeTown: StandardWorkTargetKind.fixedMaterial,
};

const StandardWorkTargetConfig unsupportedStandardWorkTargetConfig =
    StandardWorkTargetConfig(
      allowedForUnitType: alwaysFalseForWorkTarget,
      costFn: nullWorkOrderCost,
      totalTurnsFn: singleTurnWorkDuration,
    );

StandardWorkTargetConfig buildStandardWorkTargetConfig({
  required Game game,
  required String target,
  required String targetTileKey,
  required Unit unit,
  required TileMapState tileState,
  required Map<String, Province> provincesById,
}) {
  final kind = standardWorkTargetKinds[target];
  if (kind == null) return unsupportedStandardWorkTargetConfig;
  return switch (kind) {
    StandardWorkTargetKind.fixedMaterial => StandardWorkTargetConfig(
      allowedForUnitType: (t) =>
          isWorkOrderTargetAllowedForUnitType(t, target),
      costFn: () => workOrderMaterialCost(target),
      totalTurnsFn: () => totalTurnsForWork(target),
    ),
    StandardWorkTargetKind.improvement => StandardWorkTargetConfig(
      allowedForUnitType: (t) => isWorkOrderTargetAllowedForUnitType(
        t,
        kWorkTargetBuildImprovement,
      ),
      costFn: () => WorkOrderCostCalculator(
        game,
        playerId: unit.ownerId,
      ).calculateCost(
        kWorkTargetBuildImprovement,
        targetTileKey,
        improvementLevel: tileState.improvementLevel(targetTileKey),
      ),
      totalTurnsFn: () => totalTurnsForWork(
        kWorkTargetBuildImprovement,
        improvementLevel: tileState.improvementLevel(targetTileKey),
      ),
    ),
    StandardWorkTargetKind.fort => fortWorkTargetConfig(
      unit: unit,
      provincesById: provincesById,
    ),
  };
}

StandardWorkTargetConfig fortWorkTargetConfig({
  required Unit unit,
  required Map<String, Province> provincesById,
}) {
  final fortLevel = provincesById[unit.locationProvinceId]?.fortLevel ?? 0;
  return StandardWorkTargetConfig(
    allowedForUnitType: (t) =>
        isWorkOrderTargetAllowedForUnitType(t, kWorkTargetBuildFort),
    costFn: () =>
        workOrderMaterialCost(kWorkTargetBuildFort, fortLevel: fortLevel),
    totalTurnsFn: () =>
        totalTurnsForWork(kWorkTargetBuildFort, fortLevel: fortLevel),
  );
}

bool alwaysFalseForWorkTarget(String _) => false;
WorkOrderCost? nullWorkOrderCost() => null;
int singleTurnWorkDuration() => 1;

bool applyStandardWorkOrder({
  required Game game,
  required WorkOrder order,
  required Unit unit,
  required String targetTileKey,
  required bool hasValidTarget,
  required String orderTarget,
  required TileMapState tileState,
  required Map<String, Province> provincesById,
  required bool Function(WorkOrderCost) canAffordMaterialCost,
  required void Function(WorkOrderCost) deductMaterialCost,
  required void Function(String, Unit) updateUnit,
}) {
  if (unit.currentWork != null || !hasValidTarget) return false;

  final config = buildStandardWorkTargetConfig(
    game: game,
    target: orderTarget,
    targetTileKey: targetTileKey,
    unit: unit,
    tileState: tileState,
    provincesById: provincesById,
  );
  if (!config.allowedForUnitType(unit.type)) return false;

  final cost = config.costFn();
  if (cost == null || !canAffordMaterialCost(cost)) return false;

  deductMaterialCost(cost);
  final totalTurns = config.totalTurnsFn();
  ordersLog.d(
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
    ordersLog.d(
      'build_fort skipped - Mine Engineering required for fort level 2',
    );
    return true;
  }
  if (fortLevel == 2 && techUnlocked?[kTechIdModernForts] != true) {
    ordersLog.d('build_fort skipped - Modern Forts required for fort level 3');
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
  ordersLog.d('build_rail skipped - $railReason');
  return true;
}
