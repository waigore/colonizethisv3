// Pins the canonical `isBelowQuotaPeaceTreasuryRecovery` composite in
// `expand_phase_planner.dart` (Refs #2509 S1).
//
// This composite is the three-arm EXPAND-trap below-quota peace
// treasury-recovery decision used by the cargo-preference boost in
// `economy_planner.dart` (legacy path) and the orchestrator's
// `_appendEconomyBuildOrders` build-rebuild-trap slice via the phase-derived
// equivalents
// `resolvePhaseEconomyExpandBelowQuotaPeaceZeroRegimentsRebuildActive` and
// `resolvePhaseEconomyExpandBelowQuotaPeaceInsufficientRegimentsActive`
// (`phase_planner_economy_filter.dart`, Refs #2509 S5).
//
// Arm A short-circuits to `true` when
// `isBelowQuotaPeaceZeroRegimentsRebuild` fires (canonical Arm A,
// `expand_phase_planner.dart`). Arm B requires
// `isBelowQuotaPeaceInsufficientRegiments` (canonical Arm B,
// `expand_phase_planner.dart`) AND an effective treasury
// `treasury + pendingRichesTreasuryDelta(stockpile)` strictly below
// `cheapestRegimentBuildTreasuryCost()` (canonical affordability gate,
// `expand_phase_planner.dart`). All three sub-helpers are canonical in
// `expand_phase_planner.dart`; this composite sits on top so the
// EXPAND-trap rebuild/recovery story is fully co-located.
//
// `colonial_pressure.dart` was deleted in S1 of #2509; the canonical
// helper lives in `expand_phase_planner.dart` and this test pins it
// directly. Cross-arm composition (Arm A short-circuit + Arm B +
// affordability gate) is the focus here; legacy-callsite branch coverage
// belongs to the planner-specific tests under
// `packages/colonizethis_ai/test/planning/`.
//
// Behavioral invariants pinned here (all deterministic):
//
//   1. Arm A short-circuit: when
//      `isBelowQuotaPeaceZeroRegimentsRebuild` returns `true` the composite
//      returns `true` regardless of `treasury` / `stockpile`. A regression
//      that re-ordered the arms or duplicated the affordability check ahead
//      of Arm A would surface here.
//   2. Arm B + affordability: when Arm A fails but Arm B holds the composite
//      returns `true` iff effective treasury is strictly below
//      `cheapestRegimentBuildTreasuryCost()`. Boundary at
//      `effectiveTreasury == cheapest` is `false` (afford one build, exit
//      recovery); one-below is `true` (stay in recovery). This pins the
//      `<` vs `<=` comparison the legacy composite carried.
//   3. Arm B precondition fall-through: when Arm B fails (any of the five
//      `isBelowQuotaPeaceInsufficientRegiments` disqualifiers) the composite
//      returns `false` regardless of treasury / stockpile inputs. Guards
//      against a regression that re-ordered the affordability check before
//      the precondition.
//   4. Effective-treasury composition: cash + riches both contribute via
//      `pendingRichesTreasuryDelta`. A regression that dropped either
//      addend would still pass the legacy zero-treasury cases but would
//      mishandle mixed cash + riches GP states.
//   5. Determinism (Must-have #7): two identical calls inside the same
//      isolate return the same `bool` (no rng, no hidden mutation).

import 'package:colonizethis_test/test.dart';

import 'expand_phase_planner_below_quota_peace_treasury_recovery_arm_cases.dart';
import 'expand_phase_planner_below_quota_peace_treasury_recovery_guard_cases.dart';

void main() {
  registerExpandPhasePlannerBelowQuotaPeaceTreasuryRecoveryArmCases();
  registerExpandPhasePlannerBelowQuotaPeaceTreasuryRecoveryGuardCases();
}
