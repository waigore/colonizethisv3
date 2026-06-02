/// Phase-planner peace-target extraction for orchestrator wiring (Refs #2509 S5).
///
/// Maps a [PhasePlanOutcome] from [runPhasePlanners] to the sorted GP peace
/// target list the diplomacy planner should `offerPeace` toward this turn.
/// Used by `domain_planner_orchestrator.dart` on every player turn since the
/// S5 orchestrator wiring landed — `_stalledPeacePlannerResultIfNeeded`
/// reads [gpPeaceTargetsFromPhasePlan] in place of the legacy
/// `collectStalledGreatPowerPeaceTargets` whenever a `phasePlan` is
/// threaded through (the canonical post-S5 path).
/// `collectStalledGreatPowerPeaceTargets` is retained at its canonical
/// home in `observer_goal_phase.dart` as the no-`phasePlan` fallback for
/// the unit-test fixtures that still construct orchestrator state without
/// the dispatched phase plan; the legacy
/// `diplomacy_planner_peace_targets.dart` host was deleted in S1.
library;

import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';

/// Returns the phase-specific Great Power peace targets for [outcome].
///
/// EXPAND and COLONIAL-lite use [PhasePlanOutcome.expandPeaceTargetFactionIdsSorted].
/// COLONIAL uses [PhasePlanOutcome.colonialPeaceTargetFactionIdsSorted].
/// DEVELOP uses [PhasePlanOutcome.developPeaceTargetFactionIdsSorted].
///
/// The list is already ascending-sorted by the underlying planner functions.
List<String> gpPeaceTargetsFromPhasePlan(PhasePlanOutcome outcome) {
  switch (outcome.phase) {
    case ObserverGoalPhase.expand:
    case ObserverGoalPhase.colonialLite:
      return outcome.expandPeaceTargetFactionIdsSorted;
    case ObserverGoalPhase.colonial:
      return outcome.colonialPeaceTargetFactionIdsSorted;
    case ObserverGoalPhase.develop:
      return outcome.developPeaceTargetFactionIdsSorted;
  }
}
