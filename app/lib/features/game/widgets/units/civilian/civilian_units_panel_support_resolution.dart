/// Pending work-order resolution helpers. SPEC/ui/civilian-units-panel.md.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../train/train_dialog_chrome.dart';
import '../shared/region_labels.dart';

const Map<String, String> civilianUnitsPanelWorkTargetLabels = {
  kWorkTargetExplore: 'Explore',
  kWorkTargetProspect: 'Prospect',
  kWorkTargetBuildImprovement: 'Build improvement',
  kWorkTargetUpgradeTown: 'Upgrade town',
  kWorkTargetBuildRoad: 'Build road',
  kWorkTargetBuildPort: 'Build port',
  kWorkTargetBuildFort: 'Build fort',
  kWorkTargetBuildRail: 'Build rail',
  kWorkTargetCounterSpy: 'Counter-espionage',
  kWorkTargetPurchaseLand: 'Purchase land',
};

/// Pending assigned-to line plus optional cost strip. SPEC/ui/civilian-units-panel.md.
class CivilianUnitsPanelPendingAssignedResolution {
  const CivilianUnitsPanelPendingAssignedResolution({
    required this.mainLine,
    required this.totalTurns,
    this.materialCosts,
    this.treasuryAmount,
  });

  final String mainLine;
  final int totalTurns;
  final Map<String, int>? materialCosts;
  final int? treasuryAmount;
}

CivilianUnitsPanelPendingAssignedResolution
resolveCivilianUnitsPanelPendingAssignedResolution(
  Game game,
  Unit unit,
  WorkOrder order,
  Map<String, String> provinceNames,
) {
  final workLabel =
      civilianUnitsPanelWorkTargetLabels[order.target] ?? order.target;
  final regionId = Unit.regionIdFromTileKey(order.targetTileKey);
  final provinceId = Unit.provinceIdFromTileKey(order.targetTileKey);
  var location = '';
  if (regionId != null && provinceId != null) {
    final name =
        provinceNames['$regionId|$provinceId'] ?? '$regionId|$provinceId';
    location = ' (${regionDisplayLabel(regionId)} — $name)';
  }
  final base = '$workLabel$location';
  final totalTurns = previewTotalTurnsForPendingWorkOrder(
    game: game,
    unit: unit,
    order: order,
  );

  if (order.target == kWorkTargetPurchaseLand) {
    final resourceId = game.worldState.resourceByTileKey[order.targetTileKey];
    if (resourceId != null && resourceId.isNotEmpty) {
      return CivilianUnitsPanelPendingAssignedResolution(
        mainLine: base,
        totalTurns: totalTurns,
        treasuryAmount: purchaseLandCost(resourceId),
      );
    }
    return CivilianUnitsPanelPendingAssignedResolution(
      mainLine: base,
      totalTurns: totalTurns,
    );
  }
  if (order.target == kWorkTargetCounterSpy) {
    return CivilianUnitsPanelPendingAssignedResolution(
      mainLine: base,
      totalTurns: totalTurns,
    );
  }

  final targetProvinceId = Unit.provinceIdFromTileKey(order.targetTileKey);
  final province = targetProvinceId != null
      ? game.worldState.tryGetProvince(targetProvinceId)
      : null;

  final improvementLevel = order.target == kWorkTargetBuildImprovement
      ? game.worldState.tileState.improvementLevel(order.targetTileKey)
      : 0;
  final fortLevel = province?.fortLevel ?? 0;
  final roadLevel = game.worldState.tileState.roadLevel(order.targetTileKey);

  final costMap = WorkOrderCostCalculator(game).calculateCost(
    order.target,
    order.targetTileKey,
    improvementLevel: improvementLevel,
    fortLevel: fortLevel,
    roadLevel: roadLevel,
  );
  if (costMap != null && costMap.isNotEmpty) {
    return CivilianUnitsPanelPendingAssignedResolution(
      mainLine: base,
      totalTurns: totalTurns,
      materialCosts: costMap,
    );
  }
  return CivilianUnitsPanelPendingAssignedResolution(
    mainLine: base,
    totalTurns: totalTurns,
  );
}

List<MapEntry<String, int>> sortedCivilianUnitsPanelMaterialCostEntries(
  Map<String, int> m,
) {
  final list = m.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return list;
}

/// Dense chip matching train-dialog resource chips. SPEC/ui/civilian-units-panel.md.
class CivilianUnitsPanelAssignedCostChip extends StatelessWidget {
  const CivilianUnitsPanelAssignedCostChip({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TrainDialogResourceChip(child: child);
  }
}
