import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_work_constants.dart';

/// Selected Builder + tile for a pending `build_improvement` assign.
class DevelopmentImproveAssignCandidate {
  const DevelopmentImproveAssignCandidate({
    required this.builderUnitId,
    required this.targetTileKey,
    required this.isCapitalConnected,
  });

  final String builderUnitId;
  final String targetTileKey;
  final bool isCapitalConnected;

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
