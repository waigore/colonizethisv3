import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../order_work_constants.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import '../build_rail_work_rules.dart';
import '../orders_application_helpers.dart';
import 'work_order_cost_calculator.dart';
import '../order_validation_result.dart';
import 'work_order_validator.dart';

/// Material, tech, and projected-cost helpers for [WorkOrderValidator].
///
/// Split from `work_order_validator.dart` for the wave-6 physical-line ratchet
/// (Refs #4246).
extension WorkOrderValidatorMaterial on WorkOrderValidator {
  OrderValidationResult? validateMaterialAndTechRules(
    WorkOrder o,
    int fortLevel,
  ) {
    if (_skipsMaterialAndTechValidation(o.target)) return null;
    final improvementLevel = _improvementLevelForCost(o);
    final roadLevel = workOrderContext.game.worldState.roadLevelAtTile(
      o.targetTileKey,
    );
    final techResult = _validateRoadFortRailTech(o, fortLevel, roadLevel);
    if (techResult != null) return techResult;
    return _validateWorkMaterialCosts(
      o,
      improvementLevel: improvementLevel,
      fortLevel: fortLevel,
      roadLevel: roadLevel,
    );
  }

  void applyProjectedWorkCost(WorkOrder o) {
    if (_applyProjectedPurchaseLandCost(o)) return;
    if (_skipsProjectedCost(o.target)) return;
    final costMap =
        WorkOrderCostCalculator(
          workOrderContext.game,
          playerId: workOrderContext.playerId,
        ).calculateCost(
          o.target,
          o.targetTileKey,
          improvementLevel: _improvementLevelForCost(o),
        );
    if (costMap == null) return;
    _applyProjectedCostMap(costMap);
  }

  OrderValidationResult? validateProspectTarget(WorkOrder o) {
    if (o.target != kWorkTargetProspect) return null;
    if (!isMineralEligibleTile(
      workOrderContext.game,
      workOrderContext.tileMapByRegion,
      o.targetTileKey,
    )) {
      return OrderValidationResult.rejected(
        'Tile is not mineral-eligible for prospecting',
      );
    }
    final prospected = workOrderContext.game.worldState.prospectedTilesForPlayer(
      workOrderContext.playerId,
    );
    if (prospected.contains(o.targetTileKey)) {
      return OrderValidationResult.rejected('Tile already prospected');
    }
    return null;
  }

  bool _skipsMaterialAndTechValidation(String target) =>
      kWorkTargetsWithoutMaterialCost.contains(target);

  int _improvementLevelForCost(WorkOrder o) =>
      o.target == kWorkTargetBuildImprovement
      ? workOrderContext.game.worldState.improvementLevelAtTile(o.targetTileKey)
      : 0;

  OrderValidationResult? _validateRoadFortRailTech(
    WorkOrder o,
    int fortLevel,
    int roadLevel,
  ) {
    final roadResult = _validateRoadTech(o.target, roadLevel);
    if (roadResult != null) return roadResult;
    final fortResult = _validateFortTech(o.target, fortLevel);
    if (fortResult != null) return fortResult;
    return _validateRailTech(o, roadLevel);
  }

  OrderValidationResult? _validateRoadTech(String target, int roadLevel) {
    if (target != kWorkTargetBuildRoad || roadLevel < 1) return null;
    final hasRoadConstruction =
        workOrderContext.player.techUnlocked?[kTechIdRoadConstruction] == true;
    if (hasRoadConstruction) return null;
    return OrderValidationResult.rejected(
      'Road Construction tech required for transport level 2',
    );
  }

  OrderValidationResult? _validateFortTech(String target, int fortLevel) {
    if (target != kWorkTargetBuildFort) return null;
    if (fortLevel == 1 &&
        workOrderContext.player.techUnlocked?[kTechIdMineEngineering] != true) {
      return OrderValidationResult.rejected(
        'Mine Engineering tech required for fort level 2',
      );
    }
    if (fortLevel == 2 &&
        workOrderContext.player.techUnlocked?[kTechIdModernForts] != true) {
      return OrderValidationResult.rejected(
        'Modern Forts tech required for fort level 3',
      );
    }
    return null;
  }

  OrderValidationResult? _validateRailTech(WorkOrder o, int roadLevel) {
    if (o.target != kWorkTargetBuildRail) return null;
    final terrain = terrainTypeForTileKey(
      workOrderContext.tileMapByRegion,
      o.targetTileKey,
    );
    final reason = rejectionReasonForBuildRailOrder(
      techUnlocked: workOrderContext.player.techUnlocked,
      roadLevel: roadLevel,
      terrain: terrain,
    );
    if (reason == null) return null;
    return OrderValidationResult.rejected(reason);
  }

  OrderValidationResult? _validateWorkMaterialCosts(
    WorkOrder o, {
    required int improvementLevel,
    required int fortLevel,
    required int roadLevel,
  }) {
    final costMap = _workCostMap(
      o.target,
      o.targetTileKey,
      improvementLevel: improvementLevel,
      fortLevel: fortLevel,
      roadLevel: roadLevel,
    );
    if (costMap == null) return null;
    if (_hasInsufficientStockpileForCost(costMap)) {
      return OrderValidationResult.rejected(
        'Insufficient materials for work order',
      );
    }
    return null;
  }

  Map<String, int>? _workCostMap(
    String target,
    String tileKey, {
    required int improvementLevel,
    required int fortLevel,
    required int roadLevel,
  }) => WorkOrderCostCalculator(workOrderContext.game, playerId: workOrderContext.playerId)
      .calculateCost(
        target,
        tileKey,
        improvementLevel: improvementLevel,
        fortLevel: fortLevel,
        roadLevel: roadLevel,
      );

  bool _hasInsufficientStockpileForCost(Map<String, int> costMap) =>
      !ProjectedCostEngine.canAffordWorkMaterialCost(stockpileState, costMap);

  bool _applyProjectedPurchaseLandCost(WorkOrder o) {
    if (o.target != kWorkTargetPurchaseLand) return false;
    // Treasury is validated in precheck and charged only on work completion
    // (SPEC/program/orders.md); do not deduct here.
    return true;
  }

  bool _skipsProjectedCost(String target) =>
      kWorkTargetsWithoutProjectedMaterialCost.contains(target);

  void _applyProjectedCostMap(Map<String, int> costMap) {
    if (!ProjectedCostEngine.canAffordWorkMaterialCost(
      stockpileState,
      costMap,
    )) {
      return;
    }
    stockpileState = ProjectedCostEngine.deductWorkMaterialCost(
      stockpileState,
      costMap,
    );
  }
}
