// Declare-war target helpers barrel (Refs #2509; #4365 Slice A).
//
// Each top-level helper computes a single deterministic GP / minor / GP
// blocker declare-war target id for the legacy colonial-pressure ratchet path
// in `runDiplomacyPlannerWithResult`. The phase-planner dispatch path
// (`PhasePlanOutcome`) bypasses these helpers via
// `phase_planner_declare_war_targets.dart` adapters and is unchanged.

export 'diplomacy_planner_declare_war_targets_minor.dart';
export 'diplomacy_planner_declare_war_targets_gp.dart';
