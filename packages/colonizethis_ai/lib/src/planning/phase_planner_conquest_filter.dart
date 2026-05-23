/// Phase-planner conquest destination filter for orchestrator wiring
/// (Refs #2509 S5 slice — companion to `phase_planner_military_plans.dart`).
///
/// Resolves which invadable province ids `runConquestArmyMovePlanner` may
/// consider this turn from a single [PhasePlanOutcome]. When a non-default
/// [ExpandMilitaryPlan] or [ColonialMilitaryPlan] is active, the conquest
/// pass restricts to that plan's `priorityDestinationProvinceIdsSorted`
/// instead of the legacy union of OW invadable plus optionally NW invadable.
/// When both military adapters return default plans, the resolution falls
/// back to the legacy invadable set with optional structural NW suppression
/// under EXPAND / COLONIAL-lite (issue #2509 § EXPAND NW suppression).
/// DEVELOP routes to [PhaseConquestInvadableResolution.skipConquestPass]
/// because the phase planner emits no invasion army moves (issue #2509 §
/// DEVELOP suppressions).
library;

import 'colonial_phase_planner.dart' show ColonialMilitaryPlan;
import 'expand_phase_planner.dart' show ExpandMilitaryPlan;
import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';
import 'phase_planner_military_plans.dart';

/// Outcome of [resolvePhaseConquestInvadable] for one player turn.
class PhaseConquestInvadableResolution {
  const PhaseConquestInvadableResolution({
    this.useLegacyInvadable = false,
    this.phasePlanInvadableSorted = const <String>[],
    this.structuralNewWorldSuppressed = false,
    this.skipConquestPass = false,
  });

  /// When `true`, callers build the invadable set from
  /// [ConquestSummary] / [ColonialSummary] using the legacy path.
  /// When `false`, [phasePlanInvadableSorted] is authoritative.
  final bool useLegacyInvadable;

  /// Non-empty only when [useLegacyInvadable] is `false`.
  final List<String> phasePlanInvadableSorted;

  /// When [useLegacyInvadable] is `true`, exclude NW invadable provinces
  /// from the legacy union (EXPAND / COLONIAL-lite structural suppression).
  final bool structuralNewWorldSuppressed;

  /// When `true`, `runConquestArmyMovePlanner` returns without emitting
  /// orders (DEVELOP phase).
  final bool skipConquestPass;
}

/// Resolves the conquest destination filter for [phasePlan].
///
/// Pure and deterministic — identical inputs always yield identical
/// resolutions (Refs #2509 Must-have #7).
PhaseConquestInvadableResolution resolvePhaseConquestInvadable({
  required PhasePlanOutcome phasePlan,
}) {
  if (phasePlan.phase == ObserverGoalPhase.develop) {
    return const PhaseConquestInvadableResolution(skipConquestPass: true);
  }

  final expandPlan = expandMilitaryPlanFromPhasePlan(phasePlan);
  if (expandPlan.priorityDestinationProvinceIdsSorted.isNotEmpty) {
    return PhaseConquestInvadableResolution(
      phasePlanInvadableSorted: expandPlan.priorityDestinationProvinceIdsSorted,
    );
  }

  final colonialPlan = colonialMilitaryPlanFromPhasePlan(phasePlan);
  if (colonialPlan.priorityDestinationProvinceIdsSorted.isNotEmpty) {
    return PhaseConquestInvadableResolution(
      phasePlanInvadableSorted: colonialPlan.priorityDestinationProvinceIdsSorted,
    );
  }

  final suppressNewWorld = phasePlan.phase == ObserverGoalPhase.expand ||
      phasePlan.phase == ObserverGoalPhase.colonialLite;

  return PhaseConquestInvadableResolution(
    useLegacyInvadable: true,
    structuralNewWorldSuppressed: suppressNewWorld,
  );
}
