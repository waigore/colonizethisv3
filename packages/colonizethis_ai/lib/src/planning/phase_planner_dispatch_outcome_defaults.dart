import 'observer_goal_phase.dart';
import 'phase_planner_dispatch_outcome.dart';

/// Reusable short-circuit outcomes for [runPhasePlanners] (Refs #4310 Slice B).
const PhasePlanOutcome phasePlanOutcomeDefaultExpand = PhasePlanOutcome(
  phase: ObserverGoalPhase.expand,
);

const PhasePlanOutcome phasePlanOutcomeDefaultColonialLite = PhasePlanOutcome(
  phase: ObserverGoalPhase.colonialLite,
);

const PhasePlanOutcome phasePlanOutcomeDefaultColonial = PhasePlanOutcome(
  phase: ObserverGoalPhase.colonial,
);

const PhasePlanOutcome phasePlanOutcomeDefaultDevelop = PhasePlanOutcome(
  phase: ObserverGoalPhase.develop,
);
