// Case bodies for `colonial_phase_planner_naval_test.dart` (Refs #3977 Phase 6).
// Registered from the thin contract file of the same stem.
// Pin/row coverage is preserved 1:1 from the former inline suite.

// Unit tests for `planColonialNaval` in
// `packages/colonizethis_ai/lib/src/planning/colonial_phase_planner.dart`
// (Refs #2509 S3).
//
// Spec contract (issue #2509 § COLONIAL phase planner § planColonialNaval):
//
//   "Colonial naval missions:
//      → Transport regiments to NW invasion staging.
//      → Explore unrevealed NW tiles.
//      → Cargo routing for overseas extraction."
//
// This planner covers the **invasion-transport** arm of that contract.
// The exploration + cargo arms are satisfied at the orchestrator layer
// (#2509 S5) by the existing `colonial_naval_scoring.dart` helpers, so
// `defaultPlan` means "no invasion-transport directive this turn" --
// the legacy free-choice colonial naval pipeline continues to emit
// exploration / cargo moves as before.
//
// Mirrors the test pattern established for [planColonialMilitary] in
// `colonial_phase_planner_military_test.dart`: small synthetic
// fixtures, one branch arm per test, in-module pin (the planner module
// never re-checks phase, so these tests stay scoped to the priority-arm
// branches plus the structural OW suppression and the defensive
// guards). The shared `colonialDeclaredWarTargetFactionId` parameter
// also mirrors `planColonialMilitary` so the orchestrator (#2509 S5)
// can pair the army-move plan with the naval-transport plan against
// the same colonial declare-war target with no shape mismatch.
//
// `planColonialNaval` tests:
//
//   1. **Below quota (own OW = 9) -> defaultPlan:** outer COLONIAL
//      guard pin -- the planner refuses to act for a GP that has not
//      yet reached the EXPAND -> COLONIAL transition threshold even
//      when NW invadable provinces and at-war owners are present.
//   2. **Player not in game -> defaultPlan:** defensive guard pin
//      (matches [planColonialMilitary] / [planColonialPeace] /
//      [planColonialLiteNaval] for snapshots pointing at non-existent
//      players).
//   3. **Empty NW invadable -> defaultPlan:** structural empty-list
//      short-circuit so an empty constraint never leaks to the
//      orchestrator.
//   4. **AC: declared colonial target owns one NW invadable -> restrict
//      to that province + target as sole owner:** canonical priority-1
//      happy path (issue #2509 § planColonialNaval "Transport regiments
//      to NW invasion staging").
//   5. **Declared colonial target owns multiple NW invadable ->
//      sorted-ascending province list:** priority 1 keeps all
//      target-owned provinces; output order is independent of input
//      order.
//   6. **Declared colonial target owns no NW invadable -> defaultPlan:**
//      priority-1 fall-back so the orchestrator can fall back to the
//      legacy free-choice exploration / cargo pipeline rather than
//      receive an empty constraint.
//   7. **AC: no declared target, at-war tribe owns NW invadable ->
//      restrict to those provinces + sorted at-war owners:** priority-2
//      fallback canonical case (tribes are first-class colonial
//      invasion targets per issue #2509 § planColonialAcquisition).
//   8. **No declared target, multiple at-war owners (tribe + minor) ->
//      union of provinces + sorted owners:** priority-2 union across
//      faction classes (tribes, minors, GPs all valid invasion
//      targets in COLONIAL).
//   9. **At-war owner with no NW invadable contribution dropped from
//      owner list:** pins the "owner list mirrors actual destinations"
//      contract so the orchestrator never sees a phantom target.
//  10. **No declared target, no at-war owners hold NW invadable ->
//      defaultPlan:** both priority arms exhausted.
//  11. **Declared colonial target wins over at-war fallback (priority 1
//      over 2):** explicit priority pin to prevent re-ordering
//      regressions; mirrors the symmetric pin in
//      [planColonialMilitary].
//  12. **OW invadable structurally suppressed:** even with an at-war
//      faction owning an OW invadable province in the conquest summary
//      and a NW invadable in the colonial summary, the plan must NOT
//      pick up the OW province -- the planner only reads the NW
//      invadable list.
//  13. **Declared target on OW-only invadable -> defaultPlan:**
//      symmetric OW-suppression pin from the priority-1 side (target
//      owns nothing in NW invadable so the plan falls back to default
//      rather than reaching into OW).
//  14. **Orphan NW invadable id with no owner -> silently skipped:**
//      defensive pin for the `if (owner == null) continue` branch in
//      the at-war fallback arm.
//  15. **Determinism (Must-have #7):** identical inputs yield
//      identical plans across repeated calls.
//  16. **GP-owned NW invadable NOT structurally filtered:** explicit
//      divergence from [planColonialLiteNaval]. COLONIAL allows
//      invasion against any faction class (issue #2509 §
//      planColonialAcquisition step 3), so a declared colonial target
//      that is a GP owning NW invadable surfaces in the plan as the
//      invasion-transport focus.
//  17. **GP-owned NW invadable via at-war fallback:** mirror branch
//      from the priority-2 side -- a GP at war owning NW invadable
//      contributes its provinces to the invasion-transport plan in
//      COLONIAL (whereas it would be filtered out in COLONIAL-lite).
//  18. **Multi-player game: filter is owner-scoped, not
//      active-player-scoped:** isolation pin -- the active player's
//      own ownership has no effect on the destination filter.
//  19. **ColonialNavalPlan value equality + defaultPlan equals
//      explicit all-empty instance:** value-class pin so tests in the
//      orchestrator wiring slice (#2509 S5) can compare planner output
//      against the shared default OR a fresh `const ColonialNavalPlan(...)`.
//  20. **Input order shuffled -> ascending sort recovers:** defensive
//      determinism pin against future snapshot-builder regressions.
//
// The "invasion-transport order envelope" itself (transport-ship
// pairing, sea-zone routing via topology, beachhead staging) lives at
// the orchestrator layer (#2509 S5) and the existing
// `colonial_naval_scoring.dart` helpers; it is intentionally out of
// scope for this in-module pin -- the unit pins the deterministic
// destination filter (NW invadable provinces to land transport at)
// that the orchestrator consumes.

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/colonial_phase_planner_test_support.dart';

void registerColonialPhasePlannerNavalPriorityCases() {
  group('planColonialNaval', () {
    test('below quota (own OW = 9) -> defaultPlan', () {
      // COLONIAL outer gate: `isBelowObserverConquestQuota` is true
      // when own OW is strictly below `kObserverConquestMinOwProvincesPerGp`
      // (10). The planner short-circuits before reading invadable or
      // owner state so a mis-dispatched EXPAND-territory call cannot
      // leak NW invasion-transport destinations -- mirrors the
      // symmetric guard in [planColonialMilitary].
      final game = buildColonialPhaseGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseTribe1,
          ),
        ],
        tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
      );
      final snapshot = buildColonialPhaseSnapshot(
        atWarWith: const [kColonialPhaseTribe1],
        invadableNw: const ['newWorld|tribe1_a'],
        oldWorldProvincesOwned: 9,
      );
      expect(
        planColonialNaval(game: game, snapshot: snapshot),
        same(ColonialNavalPlan.defaultPlan),
        reason:
            'GP below the observer OW quota is still EXPAND territory '
            'for the phase-planner contract; the outer '
            '`isBelowObserverConquestQuota` guard must short-circuit '
            'before reading any NW invadable state.',
      );
    });

    test('player not in game -> defaultPlan (defensive guard)', () {
      // Defensive guard pin: snapshots pointing at a non-existent
      // player must not crash; the planner returns the default plan.
      // Matches the equivalent guard in [planColonialMilitary] and
      // [planColonialLiteNaval].
      final game = buildColonialPhaseGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseTribe1,
          ),
        ],
        tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
      );
      final snapshot = buildColonialPhaseSnapshot(
        atWarWith: const [kColonialPhaseTribe1],
        invadableNw: const ['newWorld|tribe1_a'],
        playerId: 'ghost-player',
      );
      expect(
        planColonialNaval(game: game, snapshot: snapshot),
        same(ColonialNavalPlan.defaultPlan),
      );
    });

    test('empty NW invadable -> defaultPlan', () {
      // No NW frontier means there is no province to filter; the
      // function must short-circuit before any priority-arm scan so
      // an empty constraint never leaks to the orchestrator.
      final game = buildColonialPhaseGame();
      final snapshot = buildColonialPhaseSnapshot(
        atWarWith: const [kColonialPhaseTribe1],
        invadableNw: const [],
      );
      expect(
        planColonialNaval(game: game, snapshot: snapshot),
        same(ColonialNavalPlan.defaultPlan),
      );
    });

    test('AC: declared colonial target owns one NW invadable -> restrict to '
        'that province + target as sole owner', () {
      // Acceptance criterion (issue #2509 § COLONIAL phase planner §
      // planColonialNaval "Transport regiments to NW invasion
      // staging"): priority 1 fires when the declared colonial
      // target owns at least one invadable NW province. The plan
      // restricts invasion-transport landing to exactly that
      // province and lists only the target as the priority owner.
      final game = buildColonialPhaseGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseTribe1,
          ),
        ],
        tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
      );
      final snapshot = buildColonialPhaseSnapshot(
        atWarWith: const [],
        invadableNw: const ['newWorld|tribe1_a'],
      );
      expect(
        planColonialNaval(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: kColonialPhaseTribe1,
        ),
        const ColonialNavalPlan(
          priorityInvasionTransportProvinceIdsSorted: <String>[
            'newWorld|tribe1_a',
          ],
          priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
        ),
        reason:
            'Priority 1: declared colonial target owns one NW '
            'invadable province -> plan restricts invasion-transport '
            'landing to that province and lists only the target as '
            'the priority owner.',
      );
    });

    test('declared colonial target owns multiple NW invadable -> all those '
        'provinces, sorted ascending', () {
      // Multiple invadable provinces under the same declared
      // colonial target: the plan keeps all of them, sorted
      // ascending, regardless of input order in
      // invadableNewWorldProvinceIdsSorted (defensive determinism
      // against future builder changes).
      final game = buildColonialPhaseGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseTribe1,
          ),
          Province(
            id: 'newWorld|tribe1_b',
            regionId: 'newWorld',
            ownerId: kColonialPhaseTribe1,
          ),
        ],
        tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
      );
      final snapshot = buildColonialPhaseSnapshot(
        atWarWith: const [],
        invadableNw: const ['newWorld|tribe1_b', 'newWorld|tribe1_a'],
      );
      expect(
        planColonialNaval(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: kColonialPhaseTribe1,
        ),
        const ColonialNavalPlan(
          priorityInvasionTransportProvinceIdsSorted: <String>[
            'newWorld|tribe1_a',
            'newWorld|tribe1_b',
          ],
          priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
        ),
        reason:
            'Priority 1 keeps ALL NW invadable provinces owned by '
            'the declared colonial target, sorted ascending. Output '
            'order is independent of the input invadable list order.',
      );
    });

    test('declared colonial target owns no NW invadable -> defaultPlan', () {
      // Priority 1 fails when the declared target owns nothing in NW
      // invadable. Per the spec the orchestrator should fall back to
      // its existing free-choice colonial naval pipeline (exploration
      // / cargo), so the planner returns the default plan rather than
      // an empty constraint.
      final game = buildColonialPhaseGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseTribe1,
          ),
        ],
        tribes: const [
          Tribe(id: kColonialPhaseTribe1, displayName: 'T1'),
          Tribe(id: kColonialPhaseTribe2, displayName: 'T2'),
        ],
      );
      final snapshot = buildColonialPhaseSnapshot(
        atWarWith: const [],
        invadableNw: const ['newWorld|tribe1_a'],
      );
      expect(
        planColonialNaval(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: kColonialPhaseTribe2,
        ),
        same(ColonialNavalPlan.defaultPlan),
        reason:
            'When the declared colonial target owns nothing in NW '
            'invadable, the plan falls back to defaultPlan so the '
            'orchestrator can run the legacy exploration / cargo '
            'pipeline freely. An empty constraint must never leak.',
      );
    });

    test('AC: no declared target, at-war tribe owns NW invadable -> '
        'restrict to those provinces + sorted at-war owners', () {
      // Priority 2 fires when no declared target is given and at
      // least one at-war faction owns an NW invadable province.
      // The plan restricts invasion-transport landing to the union
      // of those provinces and lists the at-war owners sorted
      // ascending. Tribes are first-class colonial invasion
      // targets per issue #2509 § planColonialAcquisition step 3.
      final game = buildColonialPhaseGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseTribe1,
          ),
        ],
        tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
      );
      final snapshot = buildColonialPhaseSnapshot(
        atWarWith: const [kColonialPhaseTribe1],
        invadableNw: const ['newWorld|tribe1_a'],
      );
      expect(
        planColonialNaval(game: game, snapshot: snapshot),
        const ColonialNavalPlan(
          priorityInvasionTransportProvinceIdsSorted: <String>[
            'newWorld|tribe1_a',
          ],
          priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
        ),
        reason:
            'Priority 2 (at-war fallback): no declare-war target + '
            'an at-war tribe owns one NW invadable -> plan restricts '
            'invasion-transport landing to that province and lists '
            'the at-war owner.',
      );
    });

    test('no declared target, multiple at-war owners (tribe + minor) -> '
        'union of their invadable + sorted owners', () {
      // At-war fallback covers any faction class (GP, minor, tribe).
      // Two at-war owners contribute provinces; the plan unions
      // them and lists both owners sorted ascending.
      final game = buildColonialPhaseGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|minor1_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseMinor1,
          ),
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseTribe1,
          ),
        ],
        tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: kColonialPhaseMinor1, displayName: 'M1')],
      );
      final snapshot = buildColonialPhaseSnapshot(
        atWarWith: const [kColonialPhaseTribe1, kColonialPhaseMinor1],
        invadableNw: const ['newWorld|tribe1_a', 'newWorld|minor1_a'],
      );
      expect(
        planColonialNaval(game: game, snapshot: snapshot),
        ColonialNavalPlan(
          priorityInvasionTransportProvinceIdsSorted: List<String>.unmodifiable(
            const <String>['newWorld|minor1_a', 'newWorld|tribe1_a'],
          ),
          priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(
            const <String>[kColonialPhaseMinor1, kColonialPhaseTribe1],
          ),
        ),
        reason:
            'Priority 2 unions provinces across all at-war owners '
            '(tribe + minor). Provinces and owners are both sorted '
            'ascending in the plan output.',
      );
    });

  });
}
