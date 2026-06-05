/// Phase-planner naval directive resolver for orchestrator wiring
/// (Refs #2509 S5 slice -- companion to `phase_planner_conquest_filter.dart`
/// and `phase_planner_naval_plans.dart`).
///
/// Resolves whether `runNavalPlanner` should engage the colonial-pressure
/// boost + ranking this turn, and surfaces the optional phase-plan-derived
/// priority province list, given a single [PhasePlanOutcome]. The resolver
/// is the wiring counterpart of the conquest filter: callers consume a
/// single struct and the structural NW suppression matrix is encoded in
/// one place rather than reproduced at every naval call site.
///
/// Suppression matrix (mirrors `SPEC/ai/phase-planner-dispatch.md` §
/// Adapter helpers, naval rows):
///
/// | Phase | Colonial naval pressure | Notes |
/// |---|---|---|
/// | [ObserverGoalPhase.expand] | `false` (structural) | EXPAND never advances NW activity; matches today's `shouldSuppressNewWorldColonialOrders` gate. |
/// | [ObserverGoalPhase.colonialLite] | `true` | COLONIAL-lite explicitly allows colonial naval + cargo per issue #2509 § COLONIAL-lite scope summary. |
/// | [ObserverGoalPhase.colonial] | `true` | Full COLONIAL drives invasion transport + exploration + cargo. |
/// | [ObserverGoalPhase.develop] | `false` (structural) | DEVELOP suppresses NW acquisition / new colonial objectives. |
///
/// The active-phase signal for COLONIAL / COLONIAL-lite is **structural**:
/// the resolver does not re-check whether visible NW invadable is
/// non-empty. The phase-planner dispatcher already gated entry to those
/// phases on the same precondition (`hasColonialAcquisitionTargets` for
/// COLONIAL, `globalNewWorldHasNonGpOwnership` for COLONIAL-lite -- see
/// `observerGoalPhaseFor`). Re-checking inside the naval pass would
/// duplicate that gate and could drift from the phase resolver.
///
/// Callers pair the boolean signal with the per-phase priority province
/// lists carried by the naval-plan adapters
/// ([colonialNavalPlanFromPhasePlan] / [colonialLiteNavalPlanFromPhasePlan]
/// in `phase_planner_naval_plans.dart`). Tighter ranking (preferring
/// naval moves toward priority NW sea zones) is layered separately and
/// remains out of scope for this resolver slice -- the resolver only
/// surfaces the priority province ids so future slices can consume them
/// without re-reading the dispatcher slots.
///
/// The resolver is pure and deterministic -- identical inputs always
/// yield identical resolutions (Refs #2509 Must-have #7). It performs no
/// I/O, no logging, and no order emission.
library;

import 'package:colonizethis_data/colonizethis_data.dart';

import 'colonial_phase_planner.dart'
    show ColonialLiteNavalPlan, ColonialNavalPlan;
import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';
import 'phase_planner_naval_plans.dart';
import 'planning_helpers.dart' show scaleWeightedBonus;

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
}) {
  switch (phasePlan.phase) {
    case ObserverGoalPhase.expand:
    case ObserverGoalPhase.develop:
      return PhaseNavalDirectiveResolution.defaultResolution;
    case ObserverGoalPhase.colonial:
      final ColonialNavalPlan plan = colonialNavalPlanFromPhasePlan(phasePlan);
      return PhaseNavalDirectiveResolution(
        colonialPreferenceActive: true,
        priorityNwProvinceIdsSorted:
            plan.priorityInvasionTransportProvinceIdsSorted,
      );
    case ObserverGoalPhase.colonialLite:
      final ColonialLiteNavalPlan plan = colonialLiteNavalPlanFromPhasePlan(
        phasePlan,
      );
      return PhaseNavalDirectiveResolution(
        colonialPreferenceActive: true,
        priorityNwProvinceIdsSorted: plan.priorityNwProvinceIdsSorted,
      );
  }
}

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
}) => phasePlan.priorityWeights.newWorldAcquisition;

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
