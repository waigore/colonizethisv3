import 'package:colonizethis_models/colonizethis_models.dart';

/// Outcome of a diplomacy planner pass (orders plus optional declare-war target).
class DiplomacyPlannerResult {
  const DiplomacyPlannerResult({
    required this.orders,
    this.declaredWarTargetFactionId,
  });

  final Orders orders;
  final String? declaredWarTargetFactionId;
}

/// Which diplomatic candidates a planner pass may consider.
enum DiplomacyPlannerPass {
  /// All diplomatic order types (legacy single-pass callers).
  all,

  /// Only [DiplomaticOrderType.declareWar] candidates.
  declareWarOnly,

  /// All types except declare war; skips targets already declared this turn.
  nonDeclareWarOnly,
}
