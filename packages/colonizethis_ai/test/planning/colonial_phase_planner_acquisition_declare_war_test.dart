// Unit tests for the `declareWar` arm (Acquisition method 3) of
// `planColonialAcquisition` in
// `packages/colonizethis_ai/lib/src/planning/colonial_phase_planner.dart`
// (Refs #2509 S3).
//
// Spec contract (issue #2509 § COLONIAL phase planner §
// planColonialAcquisition, Acquisition method 3):
//
//   "declareWar + invade
//      → Conditions: treasury ≥ regiment build cost, regiments
//        available, tribe/minor is sea-reachable.
//      → Generate declareWar(tribe) + NW army move.
//      → From turn 110: deprioritize war behind Join Empire and
//        purchase_land (fewer turns to complete)."
//
// The planner's `declareWar` arm runs only when both the Join Empire
// pass (Acquisition method 1) and the `purchase_land` pass
// (Acquisition method 2) yield no target. The arm enforces the spec's
// outer "treasury ≥ regiment build cost, regiments available"
// preconditions plus per-province validator parity with the
// order-engine `declareWarSubValidator` in
// `packages/colonizethis_logic/lib/src/orders/validators/diplomatic/`
// `declare_war_validator.dart` (rejects "Already at war with that
// faction" when [RelationState.atWar]).
//
// Outer gates pinned here:
//
//   - **Zero standing regiments -> null.** The active player must
//     hold at least one regiment across Home + field armies; without
//     any units the spec's "Generate declareWar(tribe) + NW army
//     move" follow-up has no army to commit.
//   - **Treasury below cheapest regiment build cost -> null.** The
//     active player must be able to afford at least one new regiment
//     so the order pair is sustainable; mirrors the symmetric
//     `_cheapestRegimentBuildTreasuryCost` gate in
//     `planExpandDeclareWar`.
//
// Per-province gates pinned here:
//
//   - **GP-owned NW province -> skip.** Validator-style structural
//     skip; same `game.playerById(ownerId) != null` partition used by
//     the Join Empire and `purchase_land` arms. declareWar against a
//     GP is COLONIAL's `planColonialMilitary` declared-target / at-war
//     fallback arm, not an acquisition decision.
//   - **At-war tribe / minor -> skip.** Validator rejects with
//     "Already at war with that faction" when [DiplomacyRelation.atWar]
//     is true; the planner mirrors that gate by skipping rows where
//     `relation.atWar == true`. Already-at-war factions are pursued by
//     `planColonialMilitary`'s declared-target / at-war fallback arms
//     instead.
//
// Sea reachability is structurally satisfied by the iteration: every
// candidate appears in
// `ColonialSummary.invadableNewWorldProvinceIdsSorted`, which the
// perception-snapshot builder restricts to provinces reachable from
// owned anchors via `reachableNonOwnedProvinceIdsViaSeas` (see
// `perception_snapshot_builders.dart`). No separate topology probe
// is required at the planner level.
//
// `planColonialAcquisition` declareWar tests:
//
//   1. **Zero regiments -> null:** outer guard pin. Even with
//      treasury and a valid tribe-owned NW invadable province, no
//      standing regiments suppresses the declareWar arm so the
//      conquest army-move pass would have nothing to commit.
//   2. **Treasury below cheapest regiment build cost -> null:**
//      outer guard pin using the deterministic
//      `RegimentEconomyCatalog` minimum (`peasantLevies` at 2000).
//      Treasury 1999 with at least one regiment present still trips
//      the gate.
//   3. **GP-owned NW invadable province -> skip:** structural pin;
//      `game.playerById(ownerId) != null` for the second GP keeps
//      declareWar off the GP target so the COLONIAL acquisition
//      decision stays tribe / minor only.
//   4. **At-war tribe -> skip:** validator-side
//      `relation.atWar == true` rejection. Even with regiments +
//      treasury, the at-war gate must reject the candidate so the
//      planner never re-declares war on an existing front (that
//      pursuit is owned by `planColonialMilitary`).
//   5. **No JE / PL paths, tribe + regiments + treasury ->
//      declareWar target:** canonical happy path. Acceptance
//      criterion #2509 § "(COLONIAL acquisition — declareWar)":
//      "Given a GP in COLONIAL with treasury ≥ regiment build cost
//      and a visible tribe owning a sea-reachable NW province where
//      Join Empire and purchase_land are unavailable, when
//      planColonialAcquisition runs, then the return value is
//      `(tribeFactionId, AcquisitionMethod.declareWar)`."
//   6. **Null relation row (no prior diplomacy) -> declareWar
//      fires:** validator framing `relation == null || relation.atPeace`
//      accepts a missing diplomacy row as at-peace; the planner
//      mirrors that semantics so first-contact tribes are not
//      excluded from the declareWar arm.
//   7. **Join Empire reachable -> Join Empire wins (declareWar
//      suppressed):** priority pin. Even with regiments + treasury
//      sufficient for declareWar, a satisfying Join Empire candidate
//      ends the function in the first pass.
//   8. **purchase_land reachable -> purchase_land wins (declareWar
//      suppressed):** priority pin. Even with regiments + treasury
//      sufficient for declareWar, a satisfying purchase_land
//      candidate ends the function in the second pass.
//   9. **Two valid tribe candidates -> first sorted invadable NW
//      province wins:** deterministic iteration over
//      `ColonialSummary.invadableNewWorldProvinceIdsSorted` (Refs
//      #2509 Must-have #7) — same tiebreak rule as the Join Empire /
//      `purchase_land` arms.
//  10. **Determinism (Must-have #7):** identical inputs produce
//      identical `ColonialAcquisitionTarget`s across repeated calls.
//
// All tests use synthetic Game/AIWorldSnapshot fixtures with one
// active GP (`gp1`), candidate tribes (`tribe1` / `tribe2`), an
// optional GP-owned NW province for the GP-skip pin, and explicit
// army composition so `regimentCountForPlayer` returns a known
// value. The fixtures intentionally omit overture state for tribes
// targeted by the declareWar happy paths -- declareWar does not gate
// on overture stage, so the absence of an overture row is sufficient
// to suppress the Join Empire and `purchase_land` passes.

import 'colonial_phase_planner_acquisition_declare_war_cases.dart';
import 'colonial_phase_planner_acquisition_declare_war_path_e_cases.dart';

void main() {
  registerColonialPhasePlannerAcquisitionDeclareWarCases();
  registerColonialPhasePlannerAcquisitionDeclareWarPathECases();
}
