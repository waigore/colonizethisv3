import 'package:colonizethis_models/colonizethis_models.dart';

/// Orders plus conquest-pass metadata for AI trace export.
class DomainPlannerOutcome {
  const DomainPlannerOutcome({
    required this.orders,
    this.declaredWarTargetFactionId,
    this.conquestArmyMoveCount = 0,
  });

  final Orders orders;
  final String? declaredWarTargetFactionId;
  final int conquestArmyMoveCount;
}
