// Unit tests for the phase planner dispatcher in
// `packages/colonizethis_ai/lib/src/planning/phase_planner_dispatch.dart`
// (Refs #2509 S5 foundation / S6 phase-planner-architecture sub-spec).
//
// Spec contract (issue #2509 § Design § Single-goal replacement;
// SPEC/ai/phase-planner-architecture.md § Orchestrator dispatch):
//
//   "Each phase dispatches to a self-contained planner module that makes
//    one primary decision per domain. No scores are aggregated across
//    phases."
//
// The dispatcher is the missing wiring between `observerGoalPhaseFor`
// and the four per-phase planner modules. It does not emit orders --
// the orchestrator translates `PhasePlanOutcome` into the legacy
// `runDiplomacyPlanner` / `runConquestArmyMovePlanner` / economy call
// chain in a later S5 slice. These tests pin:
//
//   1. Phase routing: `runPhasePlanners` returns each
//      `ObserverGoalPhase` value when the snapshot matches the
//      condition table (EXPAND below quota; COLONIAL-lite at quota=9
//      and turn>=120 with non-GP NW ownership; COLONIAL at quota with
//      colonial targets; DEVELOP at quota with no colonial targets).
//   2. EXPAND outcome composition: EXPAND-phase fields populate while
//      COLONIAL-lite / COLONIAL / DEVELOP fields stay at default. The
//      declare-war target picked by `planExpandDeclareWar` flows into
//      `planExpandMilitary` so the two plans target the same faction.
//   3. COLONIAL-lite outcome composition: both EXPAND fields and
//      COLONIAL-lite fields populate (OW push continues during the
//      safeguard); full-COLONIAL and DEVELOP slots stay default.
//   4. COLONIAL outcome composition: COLONIAL slots populate; EXPAND
//      / COLONIAL-lite / DEVELOP slots stay default. When acquisition
//      resolves to `declareWar`, the target factionId flows into both
//      `planColonialMilitary` and `planColonialNaval`. When
//      acquisition is `null` (no method reachable), the military /
//      naval pair fall back to their at-war arms with no declared
//      target.
//   5. DEVELOP outcome composition: only DEVELOP fields populate.
//   6. Determinism: identical inputs produce field-equal outcomes
//      (Must-have #7).
//
// Fixture style mirrors the existing per-planner tests
// (`expand_phase_planner_test.dart`, `colonial_phase_planner_test.dart`,
// `develop_phase_planner_test.dart`): minimal `Game` scaffolds tuned
// per scenario, no live AI invocation, no orchestrator wiring. The
// dispatcher is a thin composition layer so the assertions focus on
// the routing matrix rather than re-pinning each planner's internal
// branches.
//
// Thin contract for `runPhasePlanners` pin suite (Refs #4310 Slice D).
// Case bodies live in sibling `*_cases.dart` modules.

import 'package:colonizethis_test/test.dart';

import 'ai_planner_fixtures.dart';
import 'phase_planner_dispatch_cases.dart';

void main() {
  // Sanity-pin the regiment-cost helper so a regression in
  // `RegimentEconomyCatalog.byId` that bumped every cost above the
  // EXPAND fixture's default treasury (9999) would surface here rather
  // than silently failing later assertions about `planExpandDeclareWar`
  // not returning `null` from the treasury gate.
  setUpAll(() {
    final cheapest = cheapestRegimentBuildCost();
    expect(cheapest, lessThanOrEqualTo(9999), reason: 'Treasury gate fixture');
  });

  registerPhasePlannerDispatchCases();
}
