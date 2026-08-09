import 'package:colonizethis_data/colonizethis_data.dart'
    hide cheapestRegimentBuildTreasuryCost;

import 'phase_filter_common.dart';
import 'phase_planner_dispatch.dart';
import 'planning_helpers.dart'
    show
        clampPhaseWeightUpperUnit,
        resolvePhaseNewWorldAcquisitionWeight,
        resolvePhaseNewWorldCivilianWeight,
        resolvePhaseOldWorldCivilianWeight;

/// Returns the economy-pass civilian-work threshold cap scaled by the
/// soft-phase NW acquisition weight (Refs #2847 Phase 3 economy
/// civilian-work threshold cap wiring).
int economyColonialPressureCivilianWorkThresholdCap({
  required double colonialPressureWeight,
  required int uncappedThreshold,
}) {
  if (colonialPressureWeight <= 0.0) {
    return uncappedThreshold;
  }
  final clamped = clampPhaseWeightUpperUnit(colonialPressureWeight);
  final span = uncappedThreshold - kColonialCivilianWorkThresholdCap;
  return (uncappedThreshold - span * clamped).round();
}

/// Returns the economy-pass build-order threshold cap scaled by the
/// soft-phase NW acquisition weight (Refs #2847 Phase 3 economy
/// build-order threshold cap wiring).
int? economyColonialPressureBuildOrderThresholdCap({
  required double colonialPressureWeight,
}) {
  if (colonialPressureWeight <= 0.0) {
    return null;
  }
  final clamped = clampPhaseWeightUpperUnit(colonialPressureWeight);
  return (kColonialBuildOrderThresholdWhenOwnedNwUnderPressure * clamped)
      .round();
}

/// Advisory `[0.0, 1.0]` multiplier for the OW civilian-work bias.
double resolvePhaseEconomyOldWorldCivilianWeight({
  required PhasePlanOutcome phasePlan,
}) => resolvePhaseOldWorldCivilianWeight(phasePlan);

/// Advisory `[0.0, 1.0]` multiplier for the NW civilian-work bias.
double resolvePhaseEconomyNewWorldCivilianWeight({
  required PhasePlanOutcome phasePlan,
}) => resolvePhaseNewWorldCivilianWeight(phasePlan);
