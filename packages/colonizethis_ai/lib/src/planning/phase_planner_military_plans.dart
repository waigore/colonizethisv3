/// Phase-planner military-plan extraction for orchestrator wiring (Refs
/// #2509 S5 slice — companion to `phase_planner_peace_targets.dart`,
/// `phase_planner_declare_war_targets.dart`,
/// `phase_planner_civilian_work_orders.dart`, and
/// `phase_planner_expand_economy.dart`).
///
/// Maps a [PhasePlanOutcome] from [runPhasePlanners] to the conquest
/// destination filter (`{Expand|Colonial}MilitaryPlan`) the orchestrator
/// should apply to `runConquestArmyMovePlanner` this turn. Two adapters
/// are exposed because the issue spec splits conquest army-move
/// destinations between the EXPAND (Old World) and COLONIAL (New World)
/// phases. Each adapter returns the type-specific plan so the
/// orchestrator can compose both filters without re-checking the active
/// phase or down-casting between plan classes.
///
///   - [expandMilitaryPlanFromPhasePlan] returns the EXPAND-phase
///     conquest destination filter from `planExpandMilitary`. EXPAND
///     and COLONIAL-lite both surface the slot because the OW push
///     keeps running during the COLONIAL-lite safeguard (issue #2509 §
///     COLONIAL-lite: "Begin NW overture/naval penetration without
///     weakening OW push"). COLONIAL and DEVELOP route to
///     [ExpandMilitaryPlan.defaultPlan] so the EXPAND OW-conquest
///     filter cannot leak into phases whose military pass is driven by
///     `planColonialMilitary` (COLONIAL) or is structurally absent
///     (DEVELOP).
///
///   - [colonialMilitaryPlanFromPhasePlan] returns the COLONIAL-phase
///     NW conquest destination filter from `planColonialMilitary`.
///     Only [ObserverGoalPhase.colonial] outcomes surface the slot;
///     EXPAND, COLONIAL-lite, and DEVELOP route to
///     [ColonialMilitaryPlan.defaultPlan]. COLONIAL-lite explicitly
///     suppresses NW invasion army moves per the safeguard spec
///     (issue #2509 § COLONIAL-lite scope summary: "Suppressed: NW
///     invasion army moves"), so even a future regression that
///     populated `colonialMilitaryPlan` under COLONIAL-lite would be
///     filtered at this adapter layer.
///
/// Both adapters are pure functions of the [PhasePlanOutcome] alone and
/// never re-invoke the underlying planners; the orchestrator pays the
/// planner cost once via [runPhasePlanners] and consumes the adapters'
/// outputs repeatedly. Identical inputs always yield identical outputs
/// (Refs #2509 Must-have #7 determinism). Neither adapter performs I/O
/// or logging.
///
/// Suppression matrix (mirrors `SPEC/ai/phase-planner-dispatch.md` §
/// Adapter helpers):
///
/// | Phase | expandMilitaryPlanFromPhasePlan | colonialMilitaryPlanFromPhasePlan |
/// |---|---|---|
/// | [ObserverGoalPhase.expand] | [PhasePlanOutcome.expandMilitaryPlan] | [ColonialMilitaryPlan.defaultPlan] |
/// | [ObserverGoalPhase.colonialLite] | [PhasePlanOutcome.expandMilitaryPlan] | [ColonialMilitaryPlan.defaultPlan] |
/// | [ObserverGoalPhase.colonial] | [ExpandMilitaryPlan.defaultPlan] | [PhasePlanOutcome.colonialMilitaryPlan] |
/// | [ObserverGoalPhase.develop] | [ExpandMilitaryPlan.defaultPlan] | [ColonialMilitaryPlan.defaultPlan] |
///
/// The COLONIAL / DEVELOP / EXPAND off-phase routes return
/// `*.defaultPlan` constants rather than reading the dispatcher slot so
/// the structural OW-vs-NW conquest separation holds even when a
/// future regression starts populating the wrong slot for an active
/// phase.
library;

import 'colonial_phase_planner.dart' show ColonialMilitaryPlan;
import 'expand_phase_planner.dart' show ExpandMilitaryPlan;
import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';

/// Returns the phase-specific [ExpandMilitaryPlan] conquest destination
/// filter for [outcome].
///
/// See the library docstring for the full suppression matrix; the short
/// version is: EXPAND and COLONIAL-lite surface
/// [PhasePlanOutcome.expandMilitaryPlan]; COLONIAL and DEVELOP route to
/// [ExpandMilitaryPlan.defaultPlan] (no override). The COLONIAL-lite
/// pass-through preserves the EXPAND OW-conquest filter under the
/// safeguard so the OW push is not weakened by NW overture/naval
/// activity (issue #2509 § COLONIAL-lite).
///
/// The returned plan is already deterministically composed by
/// `planExpandMilitary`; the adapter never reorders list contents or
/// substitutes a different plan instance.
ExpandMilitaryPlan expandMilitaryPlanFromPhasePlan(PhasePlanOutcome outcome) {
  switch (outcome.phase) {
    case ObserverGoalPhase.expand:
    case ObserverGoalPhase.colonialLite:
      return outcome.expandMilitaryPlan;
    case ObserverGoalPhase.colonial:
    case ObserverGoalPhase.develop:
      return ExpandMilitaryPlan.defaultPlan;
  }
}

/// Returns the phase-specific [ColonialMilitaryPlan] NW conquest
/// destination filter for [outcome].
///
/// See the library docstring for the full suppression matrix; the short
/// version is: COLONIAL surfaces
/// [PhasePlanOutcome.colonialMilitaryPlan]; EXPAND, COLONIAL-lite, and
/// DEVELOP route to [ColonialMilitaryPlan.defaultPlan] (no override).
/// COLONIAL-lite intentionally suppresses NW invasion army moves per
/// the safeguard spec (issue #2509 § COLONIAL-lite scope summary), so
/// the COLONIAL-lite route returns the default plan even if a future
/// regression starts populating `colonialMilitaryPlan` under that
/// phase.
///
/// The returned plan is already deterministically composed by
/// `planColonialMilitary`; the adapter never reorders list contents or
/// substitutes a different plan instance.
ColonialMilitaryPlan colonialMilitaryPlanFromPhasePlan(
  PhasePlanOutcome outcome,
) {
  switch (outcome.phase) {
    case ObserverGoalPhase.expand:
    case ObserverGoalPhase.colonialLite:
    case ObserverGoalPhase.develop:
      return ColonialMilitaryPlan.defaultPlan;
    case ObserverGoalPhase.colonial:
      return outcome.colonialMilitaryPlan;
  }
}
