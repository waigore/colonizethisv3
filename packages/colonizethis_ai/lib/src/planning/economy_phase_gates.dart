import 'package:colonizethis_data/colonizethis_data.dart'
    show kBelowQuotaPeaceMinRegimentsBeforeDeclareWar;

import '../perception/perception_snapshot.dart';
import 'expand_phase_planner.dart' show ExpandEconomyPlan;
import 'phase_planner_dispatch.dart';
import 'phase_planner_economy_filter.dart';
import 'phase_planner_expand_economy.dart' show expandEconomyPlanFromPhasePlan;

/// Phase-derived economy orchestrator gates computed once per
/// [runDomainPlannersWithOutcome] pass (Refs #3822 Phase 3). Runtime-dependent
/// arms expose helpers that reuse the precomputed structural flags.
class EconomyPhaseGates {
  const EconomyPhaseGates({
    required this.developActive,
    required this.colonialPressureActive,
    required this.colonialPressureWeight,
    required this.expandQuotaPressure,
    required this.expandGpBlockerFocusActive,
    required this.colonialBuildOrderThresholdCap,
    required this.expandEconomy,
  });

  factory EconomyPhaseGates.fromPhasePlan({
    required PhasePlanOutcome phasePlan,
    required AIWorldSnapshot snapshot,
  }) {
    return EconomyPhaseGates(
      developActive: resolvePhaseEconomyDevelopActive(phasePlan: phasePlan),
      colonialPressureActive: resolvePhaseEconomyColonialPressureActive(
        phasePlan: phasePlan,
      ),
      colonialPressureWeight: resolvePhaseEconomyColonialPressureWeight(
        phasePlan: phasePlan,
      ),
      expandQuotaPressure: resolvePhaseEconomyExpandQuotaPressureActive(
        phasePlan: phasePlan,
      ),
      expandGpBlockerFocusActive:
          resolvePhaseEconomyExpandGpBlockerFocusActive(phasePlan: phasePlan),
      colonialBuildOrderThresholdCap:
          resolvePhaseEconomyColonialBuildOrderThresholdCap(
            phasePlan: phasePlan,
            colonial: snapshot.colonial,
          ),
      expandEconomy: expandEconomyPlanFromPhasePlan(phasePlan),
    );
  }

  final bool developActive;
  final bool colonialPressureActive;
  final double colonialPressureWeight;
  final bool expandQuotaPressure;
  final bool expandGpBlockerFocusActive;
  final int? colonialBuildOrderThresholdCap;
  final ExpandEconomyPlan expandEconomy;

  bool belowQuotaPeaceInsufficientRegiments({
    required int regimentCount,
    required bool atWarWithAnyGreatPower,
    required bool hasInvadableProvinces,
  }) {
    if (!expandQuotaPressure) {
      return false;
    }
    if (atWarWithAnyGreatPower) {
      return false;
    }
    if (regimentCount <= 0 ||
        regimentCount >= kBelowQuotaPeaceMinRegimentsBeforeDeclareWar) {
      return false;
    }
    return hasInvadableProvinces;
  }

  bool belowQuotaPeaceZeroRegimentsRebuild({
    required int regimentCount,
    required bool hasInvadableProvinces,
  }) {
    if (!expandQuotaPressure) {
      return false;
    }
    return regimentCount == 0 && hasInvadableProvinces;
  }
}
