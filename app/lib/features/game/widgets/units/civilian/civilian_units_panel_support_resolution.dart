/// Pending work-order resolution helpers. SPEC/ui/civilian-units-panel.md.
///
/// De-parted wave-9 cluster (Refs #4117).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

import '../../train/train_dialog_chrome.dart';
import '../shared/region_labels.dart';

const Map<String, String> civilianWorkTargetLabels = {
  kWorkTargetExplore: 'Explore',
  kWorkTargetProspect: 'Prospect',
  kWorkTargetBuildImprovement: 'Build improvement',
  kWorkTargetUpgradeTown: 'Upgrade town',
  kWorkTargetBuildRoad: 'Build road',
  kWorkTargetBuildPort: 'Build port',
  kWorkTargetBuildFort: 'Build fort',
  kWorkTargetBuildRail: 'Build rail',
  kWorkTargetCounterSpy: 'Counter spy',
  kWorkTargetPurchaseLand: 'Purchase land',
};

// Sort/partition helpers live in `civilian_units_sort.dart` (public surface):
// `provinceNamesByPrefixedId`, `isCivilianUnit`, `civilianUnitsInRegion`, and
// `civilianSortProvinceName`. Refs #2575 (Phase 4 testability).

/// Pending assigned-to line plus optional cost strip. SPEC/ui/civilian-units-panel.md.
class PendingAssignedResolution {
  const PendingAssignedResolution({
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

PendingAssignedResolution resolvePendingAssignedResolution(
  Game game,
  Unit unit,
  WorkOrder order,
  Map<String, String> provinceNames,
) {
  final workLabel = civilianWorkTargetLabels[order.target] ?? order.target;
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
      return PendingAssignedResolution(
        mainLine: base,
        totalTurns: totalTurns,
        treasuryAmount: purchaseLandCost(resourceId),
      );
    }
    return PendingAssignedResolution(mainLine: base, totalTurns: totalTurns);
  }
  if (order.target == kWorkTargetCounterSpy) {
    return PendingAssignedResolution(mainLine: base, totalTurns: totalTurns);
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
    return PendingAssignedResolution(
      mainLine: base,
      totalTurns: totalTurns,
      materialCosts: costMap,
    );
  }
  return PendingAssignedResolution(mainLine: base, totalTurns: totalTurns);
}

List<MapEntry<String, int>> sortedMaterialCostEntries(Map<String, int> m) {
  final list = m.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
  return list;
}

/// Dense chip matching train-dialog resource chips. SPEC/ui/civilian-units-panel.md.
class CivilianAssignedCostChip extends StatelessWidget {
  const CivilianAssignedCostChip({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TrainDialogResourceChip(child: child);
  }
}
