/// Phase-planner naval directive resolver for orchestrator wiring
/// (Refs #2509 S5; #4602 Slice A).
///
/// Cite `SPEC/ai/phase-planner-dispatch.md` (adapter helpers / naval rows)
/// rather than restating the suppression matrix here.
library;

import 'package:colonizethis_data/colonizethis_data.dart';

import 'colonial_phase_planner.dart'
    show ColonialLiteNavalPlan, ColonialNavalPlan;
import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';
import 'phase_planner_naval_plans.dart';
import 'planning_helpers.dart'
    show
        resolveFromPhasePlan,
        resolvePhaseNewWorldAcquisitionWeight,
        scaleWeightedBonus;

/// Outcome of [resolvePhaseNavalDirective] for one player turn.
class PhaseNavalDirectiveResolution {
  const PhaseNavalDirectiveResolution({
    this.colonialPreferenceActive = false,
    this.priorityNwProvinceIdsSorted = const <String>[],
  });

  /// When `true`, callers apply the colonial-pressure naval weight boost
  /// and ranking pass (today driven by `hasColonialAcquisitionTargets`).
  /// Active for [ObserverGoalPhase.colonial] and
  /// [ObserverGoalPhase.colonialLite]; suppressed structurally for
  /// [ObserverGoalPhase.expand] and [ObserverGoalPhase.develop].
  final bool colonialPreferenceActive;

  /// Phase-plan-derived NW province priority list this turn.
  /// Populated from [colonialNavalPlanFromPhasePlan] under COLONIAL
  /// (invasion-transport priority targets) and from
  /// [colonialLiteNavalPlanFromPhasePlan] under COLONIAL-lite
  /// (tribe / minor-only exploration + cargo focus). Empty for EXPAND,
  /// DEVELOP, and the COLONIAL / COLONIAL-lite fallthrough where the
  /// underlying plan is `defaultPlan` (no declared target arm fired
  /// and no at-war owner arm fired). Sorted ascending so identical
  /// inputs always yield identical lists (Refs #2509 Must-have #7).
  final List<String> priorityNwProvinceIdsSorted;

  /// Reusable "no override" resolution returned for EXPAND, DEVELOP,
  /// and the COLONIAL / COLONIAL-lite phases where both naval adapters
  /// return their `defaultPlan` (no priority arm fired this turn).
  static const PhaseNavalDirectiveResolution defaultResolution =
      PhaseNavalDirectiveResolution();
}

/// Resolves the naval directive for [phasePlan].
///
/// Pure and deterministic -- identical inputs always yield identical
/// resolutions (Refs #2509 Must-have #7). Performs no I/O, no logging,
/// no order emission.
PhaseNavalDirectiveResolution resolvePhaseNavalDirective({
  required PhasePlanOutcome phasePlan,
}) => resolveFromPhasePlan(
  phasePlan: phasePlan,
  defaultResolution: PhaseNavalDirectiveResolution.defaultResolution,
  project: (plan) {
    switch (plan.phase) {
      case ObserverGoalPhase.expand:
      case ObserverGoalPhase.develop:
        return null;
      case ObserverGoalPhase.colonial:
        final ColonialNavalPlan colonialPlan = colonialNavalPlanFromPhasePlan(
          plan,
        );
        return PhaseNavalDirectiveResolution(
          colonialPreferenceActive: true,
          priorityNwProvinceIdsSorted:
              colonialPlan.priorityInvasionTransportProvinceIdsSorted,
        );
      case ObserverGoalPhase.colonialLite:
        final ColonialLiteNavalPlan colonialLitePlan =
            colonialLiteNavalPlanFromPhasePlan(plan);
        return PhaseNavalDirectiveResolution(
          colonialPreferenceActive: true,
          priorityNwProvinceIdsSorted:
              colonialLitePlan.priorityNwProvinceIdsSorted,
        );
    }
  },
);

/// Returns the soft-phase NW acquisition weight that drives the naval
/// planner's colonial-pressure bonus and minimum-weight floor (Refs
/// #2847 Phase 3 naval colonial-pressure floor wiring).
///
/// Today reads `phasePlan.priorityWeights.newWorldAcquisition` directly
/// — the slot the dispatcher computes via [computePhasePriorityWeights]
/// from the active player's `(AIWorldSnapshot, Game, ExpandEconomyPlan)`
/// triple. The Phase 3 naval-planner wiring slice multiplies the existing
/// hard `kColonialNavalWeightBonus` and `kColonialNavalMinWeightWhenPressure`
/// magnitudes by this weight so the colonial-pressure naval boost scales
/// continuously with the active NW acquisition priority instead of
/// switching on/off at the EXPAND→COLONIAL boundary via the existing
/// boolean [resolvePhaseNavalDirective] `colonialPreferenceActive` flag.
///
/// Pure and deterministic (Refs #2509 Must-have #7). Reads only
/// `phasePlan.priorityWeights`.
double resolvePhaseNavalColonialPressureWeight({
  required PhasePlanOutcome phasePlan,
}) => resolvePhaseNewWorldAcquisitionWeight(phasePlan);

/// Returns the naval-planner colonial-pressure weight bonus scaled by
/// the soft-phase NW acquisition weight (Refs #2847 Phase 3 naval
/// colonial-pressure floor wiring).
///
/// `computeNavalRunGate` consumes this helper as the production source
/// of truth for the colonial-pressure weight bonus that previously
/// activated as a hard `weight += kColonialNavalWeightBonus` step when
/// the boolean [PhaseNavalDirectiveResolution.colonialPreferenceActive]
/// fired. The new helper scales that bonus linearly with
/// [colonialPressureWeight] so the bonus magnitude tracks the soft-phase
/// NW acquisition priority:
///
/// - `colonialPressureWeight <= 0.0` returns `0` (no bonus applied —
///   legacy EXPAND / DEVELOP suppression equivalent).
/// - `colonialPressureWeight == 1.0` returns
///   [kColonialNavalWeightBonus] exactly — identity-equal to the legacy
///   COLONIAL / COLONIAL-lite hard-phase bonus.
/// - Intermediate weights return
///   `round(kColonialNavalWeightBonus × colonialPressureWeight)`,
///   matching the continuous-scale contract used by the conquest
///   army-move colonial-pressure floor wiring
///   ([conquestColonialPressureMinWeightFloor] in
///   `phase_planner_conquest_filter.dart`), the goal-score floors,
///   the economy build-pick cargo bonus, and the diplomacy declare-war
///   carve-out (`SPEC/ai/phase-planner-architecture.md` § Phase 3
///   consumer wiring).
///
/// Pure and deterministic — identical [colonialPressureWeight] inputs
/// always yield identical `int` results (Refs #2509 Must-have #7).
/// Performs no I/O, no logging, no order emission. The function is a
/// projection of a single scalar input and never reads
/// `PhasePlanOutcome`, snapshot, or `Game` state. Clamps out-of-range
/// weights so external callers do not need to pre-clamp.
int navalColonialPressureWeightBonus({
  required double colonialPressureWeight,
}) => scaleWeightedBonus(colonialPressureWeight, kColonialNavalWeightBonus);

/// Returns the naval-planner colonial-pressure minimum weight floor
/// scaled by the soft-phase NW acquisition weight (Refs #2847 Phase 3
/// naval colonial-pressure floor wiring).
///
/// `computeNavalRunGate` consumes this helper as the production source
/// of truth for the colonial-pressure minimum-weight floor that
/// previously activated as a hard
/// `weight = kColonialNavalMinWeightWhenPressure` step when the boolean
/// [PhaseNavalDirectiveResolution.colonialPreferenceActive] fired. The
/// new helper scales that floor linearly with [colonialPressureWeight]
/// so the floor magnitude tracks the soft-phase NW acquisition priority:
///
/// - `colonialPressureWeight <= 0.0` returns `0` (no floor applied —
///   legacy EXPAND / DEVELOP suppression equivalent; the naval pass
///   keeps whatever upstream weight `resolveNavalBaseWeight` produced).
/// - `colonialPressureWeight == 1.0` returns
///   [kColonialNavalMinWeightWhenPressure] exactly — identity-equal to
///   the legacy COLONIAL / COLONIAL-lite hard-phase floor.
/// - Intermediate weights return
///   `round(kColonialNavalMinWeightWhenPressure × colonialPressureWeight)`,
///   matching the continuous-scale contract used by the conquest
///   army-move colonial-pressure floor wiring
///   ([conquestColonialPressureMinWeightFloor]) and the other Phase 3
///   consumer-wiring slices (`SPEC/ai/phase-planner-architecture.md` §
///   Phase 3 consumer wiring).
///
/// At the resource-need override floor (`newWorldAcquisition = 0.60`
/// when `treasury == 0 && newWorldProvincesOwned == 0 &&
/// boostTreasuryRecoveryCargo == true` per
/// `SPEC/ai/phase-planner-architecture.md` § Resource-need overrides),
/// the floor lifts the naval-planner run weight to
/// `round(kColonialNavalMinWeightWhenPressure × 0.60)` —
/// enough to clear `kNavalRunMinWeight` (25) and engage the naval
/// pass under EXPAND-lock recovery without the GP needing to reach
/// COLONIAL first.
///
/// Pure and deterministic — identical [colonialPressureWeight] inputs
/// always yield identical `int` results (Refs #2509 Must-have #7).
/// Performs no I/O, no logging, no order emission. Clamps out-of-range
/// weights so external callers do not need to pre-clamp.
int navalColonialPressureMinWeightFloor({
  required double colonialPressureWeight,
}) => scaleWeightedBonus(
  colonialPressureWeight,
  kColonialNavalMinWeightWhenPressure,
);
