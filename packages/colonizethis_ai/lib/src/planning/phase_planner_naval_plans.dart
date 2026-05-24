/// Phase-planner naval-plan extraction for orchestrator wiring (Refs
/// #2509 S5 slice — companion to `phase_planner_peace_targets.dart`,
/// `phase_planner_declare_war_targets.dart`,
/// `phase_planner_civilian_work_orders.dart`,
/// `phase_planner_expand_economy.dart`, and
/// `phase_planner_military_plans.dart`).
///
/// Maps a [PhasePlanOutcome] from [runPhasePlanners] to the naval
/// directive (`{Colonial|ColonialLite}NavalPlan`) the orchestrator
/// should apply to `colonial_naval_scoring.dart` this turn. Two
/// adapters are exposed because the issue spec partitions NW naval
/// directives across the two NW-active phases:
///
///   - [colonialNavalPlanFromPhasePlan] returns the full-COLONIAL
///     invasion-transport directive from `planColonialNaval`. Only
///     [ObserverGoalPhase.colonial] outcomes surface the slot;
///     EXPAND, COLONIAL-lite, and DEVELOP route to
///     [ColonialNavalPlan.defaultPlan]. COLONIAL-lite explicitly
///     suppresses NW invasion transport per the safeguard spec
///     (issue #2509 § COLONIAL-lite scope summary: "Suppressed: NW
///     invasion transport, NW army staging"), so even a future
///     regression that populated `colonialNavalPlan` under
///     COLONIAL-lite would be filtered at this adapter layer.
///
///   - [colonialLiteNavalPlanFromPhasePlan] returns the COLONIAL-lite
///     tribe / minor naval focus directive from
///     `planColonialLiteNaval`. Only [ObserverGoalPhase.colonialLite]
///     outcomes surface the slot; EXPAND, COLONIAL, and DEVELOP route
///     to [ColonialLiteNavalPlan.defaultPlan]. The COLONIAL route
///     defends against any future regression that would populate the
///     COLONIAL-lite slot in the full-COLONIAL phase: full COLONIAL
///     drives invasion transport through `colonialNavalPlan`, not the
///     COLONIAL-lite tribe / minor-only filter.
///
/// Both adapters are pure functions of the [PhasePlanOutcome] alone
/// and never re-invoke the underlying planners; the orchestrator pays
/// the planner cost once via [runPhasePlanners] and consumes the
/// adapters' outputs repeatedly. Identical inputs always yield
/// identical outputs (Refs #2509 Must-have #7 determinism). Neither
/// adapter performs I/O or logging.
///
/// Suppression matrix (mirrors `SPEC/ai/phase-planner-dispatch.md` §
/// Adapter helpers):
///
/// | Phase | colonialNavalPlanFromPhasePlan | colonialLiteNavalPlanFromPhasePlan |
/// |---|---|---|
/// | [ObserverGoalPhase.expand] | [ColonialNavalPlan.defaultPlan] | [ColonialLiteNavalPlan.defaultPlan] |
/// | [ObserverGoalPhase.colonialLite] | [ColonialNavalPlan.defaultPlan] | [PhasePlanOutcome.colonialLiteNavalPlan] |
/// | [ObserverGoalPhase.colonial] | [PhasePlanOutcome.colonialNavalPlan] | [ColonialLiteNavalPlan.defaultPlan] |
/// | [ObserverGoalPhase.develop] | [ColonialNavalPlan.defaultPlan] | [ColonialLiteNavalPlan.defaultPlan] |
///
/// The off-phase routes return `*.defaultPlan` constants rather than
/// reading the dispatcher slot so the structural COLONIAL vs
/// COLONIAL-lite naval separation holds even when a future regression
/// starts populating the wrong slot for an active phase. The two
/// directives are mutually exclusive at this layer: a single
/// [PhasePlanOutcome] surfaces at most one non-default naval plan
/// across both adapters.
library;

import 'colonial_phase_planner.dart'
    show ColonialLiteNavalPlan, ColonialNavalPlan;
import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';

/// Returns the phase-specific [ColonialNavalPlan] invasion-transport
/// directive for [outcome].
///
/// See the library docstring for the full suppression matrix; the
/// short version is: COLONIAL surfaces
/// [PhasePlanOutcome.colonialNavalPlan]; EXPAND, COLONIAL-lite, and
/// DEVELOP route to [ColonialNavalPlan.defaultPlan] (no override).
/// COLONIAL-lite intentionally suppresses NW invasion transport per
/// the safeguard spec (issue #2509 § COLONIAL-lite scope summary:
/// "Never suggest invasion transport or NW army staging here"), so
/// the COLONIAL-lite route returns the default plan even if a future
/// regression starts populating `colonialNavalPlan` under that
/// phase.
///
/// The returned plan is already deterministically composed by
/// `planColonialNaval`; the adapter never reorders list contents or
/// substitutes a different plan instance.
ColonialNavalPlan colonialNavalPlanFromPhasePlan(PhasePlanOutcome outcome) {
  switch (outcome.phase) {
    case ObserverGoalPhase.expand:
    case ObserverGoalPhase.colonialLite:
    case ObserverGoalPhase.develop:
      return ColonialNavalPlan.defaultPlan;
    case ObserverGoalPhase.colonial:
      return outcome.colonialNavalPlan;
  }
}

/// Returns the phase-specific [ColonialLiteNavalPlan] tribe / minor
/// naval focus directive for [outcome].
///
/// See the library docstring for the full suppression matrix; the
/// short version is: COLONIAL-lite surfaces
/// [PhasePlanOutcome.colonialLiteNavalPlan]; EXPAND, COLONIAL, and
/// DEVELOP route to [ColonialLiteNavalPlan.defaultPlan] (no
/// override). The COLONIAL route defends against any future
/// regression that would populate the COLONIAL-lite slot in the
/// full-COLONIAL phase — full COLONIAL drives invasion transport
/// through [colonialNavalPlanFromPhasePlan], not through the
/// tribe / minor-only COLONIAL-lite filter.
///
/// The returned plan is already deterministically composed by
/// `planColonialLiteNaval`; the adapter never reorders list contents
/// or substitutes a different plan instance.
ColonialLiteNavalPlan colonialLiteNavalPlanFromPhasePlan(
  PhasePlanOutcome outcome,
) {
  switch (outcome.phase) {
    case ObserverGoalPhase.expand:
    case ObserverGoalPhase.colonial:
    case ObserverGoalPhase.develop:
      return ColonialLiteNavalPlan.defaultPlan;
    case ObserverGoalPhase.colonialLite:
      return outcome.colonialLiteNavalPlan;
  }
}
