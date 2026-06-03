/// Phase-planner civilian work-order extraction for orchestrator wiring
/// (Refs #2509 S5 slice — companion to `phase_planner_peace_targets.dart`
/// and `phase_planner_declare_war_targets.dart`).
///
/// Maps a [PhasePlanOutcome] from [runPhasePlanners] to the
/// `List<WorkOrder>` the orchestrator should append to the player's
/// economy work pass this turn for COLONIAL and DEVELOP phases. EXPAND
/// and COLONIAL-lite do not surface civilian work orders here — the
/// EXPAND planner publishes only the two [ExpandEconomyPlan] flags
/// (`forceCheapestRegimentBuild`, `boostTreasuryRecoveryCargo`), and
/// the COLONIAL-lite safeguard intentionally does not append any
/// civilian work orders so the OW push is not weakened by NW build
/// activity (issue #2509 § COLONIAL-lite: "Begin NW overture/naval
/// penetration without weakening OW push"). For those phases this
/// adapter returns an empty list so the orchestrator can call it
/// unconditionally without re-checking the active phase.
///
/// The adapter is pure and deterministic — identical inputs always
/// yield identical outputs (Refs #2509 Must-have #7 determinism). It
/// performs no I/O, no logging, and never re-invokes the underlying
/// planners; `runPhasePlanners` already paid the planner cost once.
///
/// Suppression matrix (mirrors
/// `SPEC/ai/phase-planner-dispatch.md` § Suppression matrix):
///
/// | Phase | Returned list |
/// |---|---|
/// | [ObserverGoalPhase.expand] | `const <WorkOrder>[]` |
/// | [ObserverGoalPhase.colonialLite] | `const <WorkOrder>[]` |
/// | [ObserverGoalPhase.colonial] | [PhasePlanOutcome.colonialCivilianWorkOrders] |
/// | [ObserverGoalPhase.develop] | [PhasePlanOutcome.developCivilianWorkOrders] |
///
/// The COLONIAL-lite return is `const <WorkOrder>[]` (not the EXPAND
/// civilian work — there is none) so a future regression that started
/// populating `colonialCivilianWorkOrders` under the COLONIAL-lite
/// safeguard would still be filtered out at this adapter layer,
/// defending the structural NW-acquisition suppression the safeguard
/// enforces by spec.
library;

import 'package:colonizethis_models/colonizethis_models.dart' show WorkOrder;

import 'observer_goal_phase.dart';
import 'phase_planner_dispatch.dart';

/// Returns the phase-specific civilian work orders for [outcome].
///
/// See the library docstring for the full suppression matrix; the
/// short version is: COLONIAL returns
/// [PhasePlanOutcome.colonialCivilianWorkOrders], DEVELOP returns
/// [PhasePlanOutcome.developCivilianWorkOrders], and the EXPAND /
/// COLONIAL-lite phases return an empty list because their planner
/// sets do not surface civilian work orders.
///
/// The list is already deterministically ordered by the underlying
/// planner functions (`planColonialCivilian` /
/// `planDevelopCivilian`); the adapter never reorders or filters
/// entries.
List<WorkOrder> civilianWorkOrdersFromPhasePlan(PhasePlanOutcome outcome) {
  if (phasePlanFullColonialOutputsActive(outcome)) {
    return outcome.colonialCivilianWorkOrders;
  }
  if (outcome.phase == ObserverGoalPhase.develop) {
    return outcome.developCivilianWorkOrders;
  }
  return const <WorkOrder>[];
}
