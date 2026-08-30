/// Soft-phase priority weights for [runPhasePlanners] (Refs #2847).
///
/// Curve and override tables: `SPEC/ai/phase-planner-architecture.md`
/// § Soft-phase priority weights.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';
import 'expand_phase_planner.dart' show ExpandEconomyPlan, planExpandEconomy;
import 'phase_priority_weights_curve.dart';
import 'phase_priority_weights_overrides.dart';

export 'phase_priority_weights_curve.dart';
export 'phase_priority_weights_overrides.dart';

/// Per-domain priority weights for one dispatch (`[0.0, 1.0]`).
class PhasePriorityWeights {
  const PhasePriorityWeights({
    required this.oldWorldConquest,
    required this.newWorldAcquisition,
    required this.oldWorldCivilian,
    required this.newWorldCivilian,
  });

  final double oldWorldConquest;
  final double newWorldAcquisition;
  final double oldWorldCivilian;
  final double newWorldCivilian;

  /// Early-sprint plateau weights when no override fires.
  static const PhasePriorityWeights earlySprintDefault = PhasePriorityWeights(
    oldWorldConquest: 0.95,
    newWorldAcquisition: 0.05,
    oldWorldCivilian: 0.90,
    newWorldCivilian: 0.10,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PhasePriorityWeights &&
          other.oldWorldConquest == oldWorldConquest &&
          other.newWorldAcquisition == newWorldAcquisition &&
          other.oldWorldCivilian == oldWorldCivilian &&
          other.newWorldCivilian == newWorldCivilian;

  @override
  int get hashCode => Object.hash(
    oldWorldConquest,
    newWorldAcquisition,
    oldWorldCivilian,
    newWorldCivilian,
  );

  @override
  String toString() =>
      'PhasePriorityWeights('
      'oldWorldConquest: $oldWorldConquest, '
      'newWorldAcquisition: $newWorldAcquisition, '
      'oldWorldCivilian: $oldWorldCivilian, '
      'newWorldCivilian: $newWorldCivilian)';
}

/// Early-sprint OW ceiling for the priority-weight curves.
const int kPhasePriorityCurveEarlySprintCeiling = 7;

/// NW floor when treasury-recovery resource-need fires (Refs #2847).
const double kPhasePriorityNwTreasuryRecoveryFloor = 0.60;

/// NW floor when zero-regiment resource-need fires (Refs #2847).
const double kPhasePriorityNwZeroRegimentFloor = 0.30;

/// Below-quota NW-invasion pursuit threshold (smaller override floor).
///
/// Ordinary below-quota curve peaks at 0.20 and never reaches this.
const double kPhasePriorityNwInvadablePursuitWeightThreshold =
    kPhasePriorityNwZeroRegimentFloor;

/// Priority weights for one dispatch. Pure; `SPEC/ai/phase-planner-architecture.md`.
PhasePriorityWeights computePhasePriorityWeights({
  required AIWorldSnapshot snapshot,
  required Game game,
  required ExpandEconomyPlan expandEconomyPlan,
}) {
  final ow = snapshot.conquest.oldWorldProvincesOwned;
  final curve = curveWeightsForOw(ow);
  final nwFloor = nwAcquisitionFloor(
    snapshot: snapshot,
    game: game,
    expandEconomyPlan: expandEconomyPlan,
  );
  final nwAcquisition = nwFloor > curve.newWorldAcquisition
      ? nwFloor
      : curve.newWorldAcquisition;
  if (nwAcquisition == curve.newWorldAcquisition) {
    return curve;
  }
  return PhasePriorityWeights(
    oldWorldConquest: curve.oldWorldConquest,
    newWorldAcquisition: nwAcquisition,
    oldWorldCivilian: curve.oldWorldCivilian,
    newWorldCivilian: curve.newWorldCivilian,
  );
}

/// Goal-score colonial-pressure weight from the pre-prep EXPAND economy plan.
double goalColonialPressureWeightFor({
  required AIWorldSnapshot snapshot,
  required Game game,
}) => computePhasePriorityWeights(
  snapshot: snapshot,
  game: game,
  expandEconomyPlan: planExpandEconomy(game: game, snapshot: snapshot),
).newWorldAcquisition;
