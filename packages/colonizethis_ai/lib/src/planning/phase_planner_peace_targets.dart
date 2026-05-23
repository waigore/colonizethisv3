/// Phase-planner peace-target extraction for orchestrator wiring (Refs #2509 S5).
///
/// Maps a [PhasePlanOutcome] from [runPhasePlanners] to the sorted GP peace
/// target list the diplomacy planner should `offerPeace` toward this turn.
/// Replaces `collectStalledGreatPowerPeaceTargets` on the orchestrator path
/// once S5 wiring is active; the legacy collector remains for function-unit
/// pins until S1 deletes `diplomacy_planner_peace_targets.dart`.
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
