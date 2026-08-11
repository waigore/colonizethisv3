import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../order_work_constants.dart';
import '../build_rail_work_rules.dart';
import 'standard_work_handler_config.dart';
import 'work_order_handler.dart';

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
