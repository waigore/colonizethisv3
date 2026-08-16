import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_work_constants.dart';

/// Selected Builder + tile for a pending `build_improvement` assign.
class DevelopmentImproveAssignCandidate {
  const DevelopmentImproveAssignCandidate({
    required this.builderUnitId,
    required this.targetTileKey,
    required this.isCapitalConnected,
    this.currentImprovementLevel = 0,
    this.materialCosts = const {},
    this.canAffordPreview = true,
  });

  final String builderUnitId;
  final String targetTileKey;
  final bool isCapitalConnected;

  /// Tile improvement level before this assign (map `{n} of {cap}` current).
  final int currentImprovementLevel;

  /// Effective material cost after pending replay and feedstock waivers.
  final Map<String, int> materialCosts;

  /// Affordability of [materialCosts] vs projected stockpile.
  final bool canAffordPreview;

  int get nextImprovementLevel => currentImprovementLevel + 1;

  WorkOrder toWorkOrder() => WorkOrder(
    unitId: builderUnitId,
    target: kWorkTargetBuildImprovement,
    targetTileKey: targetTileKey,
  );
}

/// Assign row affordance for one improvable commodity row.
class DevelopmentAssignRowState {
  const DevelopmentAssignRowState({
    required this.enabled,
    this.disabledReason,
    this.candidate,
  });

  final bool enabled;
  final String? disabledReason;
  final DevelopmentImproveAssignCandidate? candidate;
}
