/// OW-count priority curve for [computePhasePriorityWeights] (Refs #4310 Slice B).
library;

import 'phase_priority_weights.dart';

/// Returns the baseline [PhasePriorityWeights] for one OW province count
/// before § Resource-need override floors are applied.
PhasePriorityWeights curveWeightsForOw(int ow) {
  if (ow <= kPhasePriorityCurveEarlySprintCeiling) {
    return PhasePriorityWeights.earlySprintDefault;
  }
  switch (ow) {
    case 8:
      return const PhasePriorityWeights(
        oldWorldConquest: 0.90,
        newWorldAcquisition: 0.10,
        oldWorldCivilian: 0.85,
        newWorldCivilian: 0.15,
      );
    case 9:
      return const PhasePriorityWeights(
        oldWorldConquest: 0.80,
        newWorldAcquisition: 0.20,
        oldWorldCivilian: 0.75,
        newWorldCivilian: 0.25,
      );
    case 10:
      return const PhasePriorityWeights(
        oldWorldConquest: 0.60,
        newWorldAcquisition: 0.40,
        oldWorldCivilian: 0.55,
        newWorldCivilian: 0.45,
      );
    case 11:
      return const PhasePriorityWeights(
        oldWorldConquest: 0.40,
        newWorldAcquisition: 0.60,
        oldWorldCivilian: 0.35,
        newWorldCivilian: 0.65,
      );
    case 12:
      return const PhasePriorityWeights(
        oldWorldConquest: 0.20,
        newWorldAcquisition: 0.80,
        oldWorldCivilian: 0.15,
        newWorldCivilian: 0.85,
      );
    default:
      return const PhasePriorityWeights(
        oldWorldConquest: 0.10,
        newWorldAcquisition: 0.90,
        oldWorldCivilian: 0.05,
        newWorldCivilian: 0.95,
      );
  }
}
