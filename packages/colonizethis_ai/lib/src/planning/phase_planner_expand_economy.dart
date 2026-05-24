/// Phase-planner EXPAND-economy directive extraction for orchestrator
/// wiring (Refs #2509 S5 slice — companion to
/// `phase_planner_peace_targets.dart`,
/// `phase_planner_declare_war_targets.dart`, and
/// `phase_planner_civilian_work_orders.dart`).
///
/// Maps a [PhasePlanOutcome] from [runPhasePlanners] to the
/// [ExpandEconomyPlan] the orchestrator should consult on the active
/// player's economy build pass this turn. The plan carries two booleans
/// the orchestrator already understands:
///
/// - `forceCheapestRegimentBuild` — drop the build-pass economy
///   threshold to zero and pick the cheapest entry in
///   [RegimentEconomyCatalog] (military rebuild crisis arm).
/// - `boostTreasuryRecoveryCargo` — add the below-quota cargo boost so
///   overseas cargo preference rises even in EXPAND.
///
/// Only EXPAND and COLONIAL-lite surface a non-default plan here.
/// COLONIAL and DEVELOP intentionally route to
/// [ExpandEconomyPlan.defaultPlan] because their economy passes are
/// driven by `colonialCivilianWorkOrders` / `developCivilianWorkOrders`
/// (via `civilianWorkOrdersFromPhasePlan`) and the COLONIAL build cap;
/// the EXPAND regiment-rebuild crisis arm is structurally unreachable
/// once the player has exited EXPAND per the phase-planner
/// architecture (issue #2509 § EXPAND phase planner §
/// planExpandEconomy and § Phase transition guard).
///
/// COLONIAL-lite continues running the EXPAND planners alongside the
/// COLONIAL-lite safeguard ones so the OW push is not weakened by NW
/// overture / naval work (issue #2509 § COLONIAL-lite "Begin NW
/// overture/naval penetration without weakening OW push"). The adapter
/// mirrors that by surfacing the EXPAND economy plan under
/// [ObserverGoalPhase.colonialLite] as well.
///
/// The adapter is pure and deterministic — identical inputs always
/// yield identical outputs (Refs #2509 Must-have #7 determinism). It
/// performs no I/O, no logging, and never re-invokes the underlying
/// planners; `runPhasePlanners` already paid the planner cost once.
///
/// Suppression matrix (mirrors
/// `SPEC/ai/phase-planner-dispatch.md` § Adapter helpers):
///
/// | Phase | Returned plan |
/// |---|---|
/// | [ObserverGoalPhase.expand] | [PhasePlanOutcome.expandEconomyPlan] |
/// | [ObserverGoalPhase.colonialLite] | [PhasePlanOutcome.expandEconomyPlan] |
/// | [ObserverGoalPhase.colonial] | [ExpandEconomyPlan.defaultPlan] |
/// | [ObserverGoalPhase.develop] | [ExpandEconomyPlan.defaultPlan] |
///
/// The COLONIAL / DEVELOP routes return [ExpandEconomyPlan.defaultPlan]
/// (not [PhasePlanOutcome.expandEconomyPlan]) so a future regression
/// that started populating the EXPAND slot under a COLONIAL or DEVELOP
/// outcome would still be filtered out at this adapter layer,
/// defending the structural phase separation the dispatcher enforces
/// by spec.
library;

import 'expand_phase_planner.dart' show ExpandEconomyPlan;
import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';

/// Returns the phase-specific [ExpandEconomyPlan] directive for
/// [outcome].
///
/// See the library docstring for the full suppression matrix; the
/// short version is: EXPAND and COLONIAL-lite surface
/// [PhasePlanOutcome.expandEconomyPlan]; COLONIAL and DEVELOP route to
/// [ExpandEconomyPlan.defaultPlan] (no override). The COLONIAL-lite
/// pass-through preserves the EXPAND regiment-rebuild crisis arm
/// under the safeguard so the OW push is not weakened by NW
/// overture/naval activity (issue #2509 § COLONIAL-lite).
///
/// The returned plan is already deterministically composed by
/// `planExpandEconomy`; the adapter never mutates field values or
/// substitutes a different plan instance.
ExpandEconomyPlan expandEconomyPlanFromPhasePlan(PhasePlanOutcome outcome) {
  switch (outcome.phase) {
    case ObserverGoalPhase.expand:
    case ObserverGoalPhase.colonialLite:
      return outcome.expandEconomyPlan;
    case ObserverGoalPhase.colonial:
    case ObserverGoalPhase.develop:
      return ExpandEconomyPlan.defaultPlan;
  }
}
