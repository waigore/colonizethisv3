import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/logging.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../constants.dart';
import '../build_rail_work_rules.dart';
import '../validators/work_order_cost_calculator.dart';
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

typedef _StandardWorkTargetConfigBuilder =
    _StandardWorkTargetConfig Function({
      required Game game,
      required String targetTileKey,
      required Unit unit,
      required TileMapState tileState,
      required Map<String, Province> provincesById,
    });

_StandardWorkTargetConfig _fixedMaterialWorkTargetConfig(String target) =>
    _StandardWorkTargetConfig(
      allowedForUnitType: (t) => isWorkOrderTargetAllowedForUnitType(t, target),
      costFn: () => workOrderMaterialCost(target),
      totalTurnsFn: () => totalTurnsForWork(target),
    );

final Map<String, _StandardWorkTargetConfigBuilder>
_standardWorkTargetConfigBuilders = {
  kWorkTargetBuildImprovement:
      ({
        required game,
        required targetTileKey,
        required unit,
        required tileState,
        required provincesById,
      }) => _StandardWorkTargetConfig(
        allowedForUnitType: (t) =>
            isWorkOrderTargetAllowedForUnitType(t, kWorkTargetBuildImprovement),
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
  kWorkTargetBuildFort:
      ({
        required game,
        required targetTileKey,
        required unit,
        required tileState,
        required provincesById,
      }) {
        final prov = provincesById[unit.locationProvinceId];
        final fortLevel = prov?.fortLevel ?? 0;
        return _StandardWorkTargetConfig(
          allowedForUnitType: (t) =>
              isWorkOrderTargetAllowedForUnitType(t, kWorkTargetBuildFort),
          costFn: () =>
              workOrderMaterialCost(kWorkTargetBuildFort, fortLevel: fortLevel),
          totalTurnsFn: () =>
              totalTurnsForWork(kWorkTargetBuildFort, fortLevel: fortLevel),
        );
      },
  kWorkTargetBuildRoad: _fixedMaterialWorkTargetConfigBuilder(
    kWorkTargetBuildRoad,
  ),
  kWorkTargetBuildPort: _fixedMaterialWorkTargetConfigBuilder(
    kWorkTargetBuildPort,
  ),
  kWorkTargetBuildRail: _fixedMaterialWorkTargetConfigBuilder(
    kWorkTargetBuildRail,
  ),
  kWorkTargetUpgradeTown: _fixedMaterialWorkTargetConfigBuilder(
    kWorkTargetUpgradeTown,
  ),
};

_StandardWorkTargetConfigBuilder _fixedMaterialWorkTargetConfigBuilder(
  String target,
) =>
    ({
      required game,
      required targetTileKey,
      required unit,
      required tileState,
      required provincesById,
    }) => _fixedMaterialWorkTargetConfig(target);

const _StandardWorkTargetConfig _unsupportedStandardWorkTargetConfig =
    _StandardWorkTargetConfig(
      allowedForUnitType: _alwaysFalseForWorkTarget,
      costFn: _nullWorkOrderCost,
      totalTurnsFn: _singleTurnWorkDuration,
    );

_StandardWorkTargetConfig _buildStandardWorkTargetConfig({
  required Game game,
  required String target,
  required String targetTileKey,
  required Unit unit,
  required TileMapState tileState,
  required Map<String, Province> provincesById,
}) {
  final builder = _standardWorkTargetConfigBuilders[target];
  if (builder == null) return _unsupportedStandardWorkTargetConfig;
  return builder(
    game: game,
    targetTileKey: targetTileKey,
    unit: unit,
    tileState: tileState,
    provincesById: provincesById,
  );
}

bool _alwaysFalseForWorkTarget(String _) => false;
WorkOrderCost? _nullWorkOrderCost() => null;
int _singleTurnWorkDuration() => 1;

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

  final config = _buildStandardWorkTargetConfig(
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
    logicLog.d(
      'build_fort skipped - Mine Engineering required for fort level 2',
    );
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

typedef StandardBuildPreApplyGate =
    bool Function({
      required Player player,
      required Unit unit,
      required String targetTileKey,
      required TileMapState tileState,
      required Map<String, Province> provincesById,
      required TerrainType? terrain,
    });

/// Applies multi-turn standard build work for a single [target] string.
class StandardBuildWorkOrderHandler implements WorkOrderHandler {
  const StandardBuildWorkOrderHandler(this.target, {this.preApplyGate});

  final String target;
  final StandardBuildPreApplyGate? preApplyGate;

  @override
  bool supports(String workTarget) => workTarget == target;

  @override
  bool tryApply(
    WorkOrderExecutionContext context,
    WorkOrder order,
    Unit unit,
    String targetTileKey,
    bool hasValidTarget,
  ) {
    if (preApplyGate != null &&
        preApplyGate!(
          player: context.player,
          unit: unit,
          targetTileKey: targetTileKey,
          tileState: context.state.work.tileState,
          provincesById: context.provincesById,
          terrain: terrainTypeForTileKey(
            context.state.tileMapByRegion,
            targetTileKey,
          ),
        )) {
      return true;
    }
    return applyStandardWorkOrder(
      game: context.state.game,
      order: order,
      unit: unit,
      targetTileKey: targetTileKey,
      hasValidTarget: hasValidTarget,
      orderTarget: target,
      tileState: context.state.work.tileState,
      provincesById: context.provincesById,
      canAffordMaterialCost: context.canAffordMaterialCost,
      deductMaterialCost: context.deductMaterialCost,
      updateUnit: context.updateUnit,
    );
  }
}

bool _skipBuildFortPreApply({
  required Player player,
  required Unit unit,
  required String targetTileKey,
  required TileMapState tileState,
  required Map<String, Province> provincesById,
  required TerrainType? terrain,
}) {
  return shouldSkipBuildFortForMissingTech(
    province: provincesById[unit.locationProvinceId],
    techUnlocked: player.techUnlocked,
  );
}

bool _skipBuildRailPreApply({
  required Player player,
  required Unit unit,
  required String targetTileKey,
  required TileMapState tileState,
  required Map<String, Province> provincesById,
  required TerrainType? terrain,
}) {
  return shouldSkipBuildRailForInvalidTerrainOrTech(
    techUnlocked: player.techUnlocked,
    roadLevel: tileState.roadLevel(targetTileKey),
    terrain: terrain,
  );
}

const StandardBuildWorkOrderHandler standardBuildImprovementWorkOrderHandler =
    StandardBuildWorkOrderHandler(kWorkTargetBuildImprovement);

const StandardBuildWorkOrderHandler standardBuildRoadWorkOrderHandler =
    StandardBuildWorkOrderHandler(kWorkTargetBuildRoad);

const StandardBuildWorkOrderHandler standardBuildPortWorkOrderHandler =
    StandardBuildWorkOrderHandler(kWorkTargetBuildPort);

const StandardBuildWorkOrderHandler standardBuildUpgradeTownWorkOrderHandler =
    StandardBuildWorkOrderHandler(kWorkTargetUpgradeTown);

const StandardBuildWorkOrderHandler standardBuildFortWorkOrderHandler =
    StandardBuildWorkOrderHandler(
      kWorkTargetBuildFort,
      preApplyGate: _skipBuildFortPreApply,
    );

const StandardBuildWorkOrderHandler standardBuildRailWorkOrderHandler =
    StandardBuildWorkOrderHandler(
      kWorkTargetBuildRail,
      preApplyGate: _skipBuildRailPreApply,
    );
