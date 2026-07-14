// Case bodies for `colonial_phase_planner_military_test.dart` (Refs #3977 Phase 6).
// Registered from the thin contract file of the same stem.
// Pin/row coverage is preserved 1:1 from the former inline suite.

// Unit tests for `planColonialMilitary` in
// `packages/colonizethis_ai/lib/src/planning/colonial_phase_planner.dart`
// (Refs #2509 S3 / S10).
//
// Spec contract (issue #2509 § COLONIAL phase planner § planColonialMilitary):
//
//   "NW army moves toward the primary colonial target's provinces.
//      → Use runConquestArmyMovePlanner with NW destination filter
//        (targets in invadableNewWorldProvinceIdsSorted owned by the
//        declare-war target faction).
//      → OW defend/regiment rebuild allowed."
//
// Mirrors the test pattern established for the EXPAND-phase military
// planner in `expand_phase_planner_military_test.dart` and the existing
// COLONIAL-phase pin in `colonial_phase_planner_test.dart`: small
// synthetic fixtures, one branch arm per test, in-module pin (the
// planner module never re-checks phase, so these tests stay scoped to
// the priority-arm branches plus the structural OW suppression and the
// defensive guards).
//
// `planColonialMilitary` tests:
//
//   1. **Below quota (own OW = 9) -> defaultPlan:** outer COLONIAL
//      guard pin — the planner refuses to act for a GP that has not
//      yet reached the EXPAND -> COLONIAL transition threshold even
//      when NW invadable provinces and at-war owners are present.
//   2. **Player not in game -> defaultPlan:** defensive guard pin
//      (matches `planColonialPeace` and `planExpandMilitary` defensive
//      behaviour for snapshots pointing at non-existent players).
//   3. **Empty NW invadable -> defaultPlan:** structural empty-list
//      short-circuit so an empty constraint never leaks to the
//      orchestrator.
//   4. **AC: declared colonial target owns one NW invadable -> restrict
//      to that province + target as sole owner:** canonical priority-1
//      happy path (issue #2509 § planColonialMilitary).
//   5. **Declared colonial target owns multiple NW invadable ->
//      sorted-ascending province list:** priority 1 keeps all
//      target-owned provinces; output order is independent of input
//      order.
//   6. **Declared colonial target owns no NW invadable -> defaultPlan:**
//      priority-1 fall-back so the orchestrator can choose freely
//      rather than receive an empty constraint.
//   7. **AC: no declared target, at-war tribe owns NW invadable ->
//      restrict to those provinces + sorted at-war owners:** priority-2
//      fallback canonical case (tribes are first-class colonial
//      targets per issue #2509 § planColonialAcquisition).
//   8. **No declared target, multiple at-war owners (tribe + minor) ->
//      union of provinces + sorted owners:** priority-2 union across
//      faction classes (tribes, minors, GPs all valid colonial
//      targets).
//   9. **At-war owner with no NW invadable contribution dropped from
//      owner list:** pins the "owner list mirrors actual destinations"
//      contract so the orchestrator never sees a phantom target.
//  10. **No declared target, no at-war owners hold NW invadable ->
//      defaultPlan:** both priority arms exhausted.
//  11. **Declared colonial target wins over at-war fallback (priority 1
//      over 2):** explicit priority pin to prevent re-ordering
//      regressions.
//  12. **OW invadable structurally suppressed:** even with an at-war
//      faction owning an OW invadable province in the conquest summary
//      and a NW invadable in the colonial summary, the plan must NOT
//      pick up the OW province — the planner only reads the NW
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
//  16. **Multi-player game: filter is owner-scoped, not
//      active-player-scoped:** isolation pin — the active player's own
//      ownership has no effect on the destination filter.
//  17. **ColonialMilitaryPlan value equality + defaultPlan equals
//      explicit all-empty instance:** value-class pin so tests in the
//      orchestrator wiring slice (#2509 S5) can compare planner output
//      against the shared default OR a fresh `const ColonialMilitaryPlan`.
//
// The "runConquestArmyMovePlanner" wiring + actual ArmyMoveOrder
// emission live at the orchestrator layer (#2509 S5) and are
// intentionally out of scope for this in-module pin — the unit pins
// the deterministic destination filter that the orchestrator consumes.

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/colonial_phase_planner_test_support.dart';

void registerColonialPhasePlannerMilitaryPriorityCases() {
  group('planColonialMilitary', () {
    test('below quota (own OW = 9) -> defaultPlan', () {
      // COLONIAL outer gate: `isBelowObserverConquestQuota` is true when
      // own OW is strictly below `kObserverConquestMinOwProvincesPerGp`
      // (10). The planner short-circuits before reading invadable or
      // owner state so a mis-dispatched EXPAND-territory call cannot
      // leak NW destinations.
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
        planColonialMilitary(game: game, snapshot: snapshot),
        same(ColonialMilitaryPlan.defaultPlan),
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
      // Matches the equivalent guard in `planExpandMilitary` and the
      // implicit `game.playerById` filter in `planColonialPeace`.
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
        planColonialMilitary(game: game, snapshot: snapshot),
        ColonialMilitaryPlan.defaultPlan,
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
        planColonialMilitary(game: game, snapshot: snapshot),
        same(ColonialMilitaryPlan.defaultPlan),
      );
    });

    test('AC: declared colonial target owns one NW invadable -> restrict to '
        'that province + target as sole owner', () {
      // Acceptance criterion (issue #2509 § COLONIAL phase planner §
      // planColonialMilitary): priority 1 fires when the declared
      // colonial target owns at least one invadable NW province. The
      // plan restricts conquest to exactly that province and lists
      // only the target as the priority owner.
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
        planColonialMilitary(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: kColonialPhaseTribe1,
        ),
        const ColonialMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
        ),
        reason:
            'Priority 1: declared colonial target owns one NW invadable '
            'province -> plan restricts to that province and lists '
            'only the target as the priority owner.',
      );
    });

    test('declared colonial target owns multiple NW invadable -> all those '
        'provinces, sorted ascending', () {
      // Multiple invadable provinces under the same declared colonial
      // target: the plan keeps all of them, sorted ascending,
      // regardless of the input order in
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
        planColonialMilitary(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: kColonialPhaseTribe1,
        ),
        const ColonialMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>[
            'newWorld|tribe1_a',
            'newWorld|tribe1_b',
          ],
          priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
        ),
        reason:
            'Priority 1 keeps ALL NW invadable provinces owned by the '
            'declared colonial target, sorted ascending. Output order '
            'is independent of the input invadable list order.',
      );
    });

    test('declared colonial target owns no NW invadable -> defaultPlan', () {
      // Priority 1 fails when the declared target owns nothing in NW
      // invadable. Per the spec the orchestrator should fall back to
      // its existing free-choice behaviour, so the planner returns
      // the default plan rather than an empty constraint.
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
        planColonialMilitary(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: kColonialPhaseTribe2,
        ),
        same(ColonialMilitaryPlan.defaultPlan),
        reason:
            'When the declared colonial target owns nothing in NW '
            'invadable, the plan falls back to defaultPlan so the '
            'orchestrator can pick freely (legacy behaviour). An '
            'empty constraint must never leak.',
      );
    });

  });
}
