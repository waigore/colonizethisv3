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

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _tribe1 = 'tribe1';
const String _tribe2 = 'tribe2';
const String _minor1 = 'minor1';

/// Game scaffold for COLONIAL-phase military tests. New World provinces,
/// players, tribes, and minors are passed in so each test can shape
/// ownership independently. Old World defaults to empty because the
/// planner does not query OW state (the OW summary is read only for
/// the outer quota gate, not the destination filter).
Game _colonialGame({
  int turnNumber = 130,
  List<Province> newWorldProvinces = const [],
  List<Province> oldWorldProvinces = const [],
  List<Player> players = const [
    Player(id: _gp1, displayName: 'GP1', isHuman: false, treasury: 9999),
    Player(id: _gp2, displayName: 'GP2', isHuman: false, treasury: 9999),
    Player(id: _gp3, displayName: 'GP3', isHuman: false, treasury: 9999),
  ],
  List<Tribe> tribes = const [],
  List<MinorNation> minorNations = const [],
}) {
  return Game(
    id: 'g-2509-colonial-phase-planner-military-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: RegionData(provinces: oldWorldProvinces),
      newWorld: RegionData(provinces: newWorldProvinces),
    ),
    players: players,
    tribes: tribes,
    minorNations: minorNations,
  );
}

/// Snapshot tuned for COLONIAL: own OW defaults to 10 (at quota — the
/// EXPAND -> COLONIAL transition has fired). Tests shape `atWarWith`,
/// `invadableNw`, `invadableOw`, and `oldWorldProvincesOwned` to
/// exercise specific priority arms and the structural OW suppression.
/// The planner does not re-check the phase so the values are still
/// consistent with COLONIAL only so debugging traces stay coherent.
AIWorldSnapshot _colonialSnapshot({
  required List<String> atWarWith,
  List<String> invadableNw = const [],
  List<String> invadableOw = const [],
  int oldWorldProvincesOwned = 10,
  String playerId = _gp1,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: 31,
      invadableProvinceIdsSorted: invadableOw,
    ),
    colonial: ColonialSummary(invadableNewWorldProvinceIdsSorted: invadableNw),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group('planColonialMilitary', () {
    test('below quota (own OW = 9) -> defaultPlan', () {
      // COLONIAL outer gate: `isBelowObserverConquestQuota` is true when
      // own OW is strictly below `kObserverConquestMinOwProvincesPerGp`
      // (10). The planner short-circuits before reading invadable or
      // owner state so a mis-dispatched EXPAND-territory call cannot
      // leak NW destinations.
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_tribe1],
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
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_tribe1],
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
      final game = _colonialGame();
      final snapshot = _colonialSnapshot(
        atWarWith: const [_tribe1],
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
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [],
        invadableNw: const ['newWorld|tribe1_a'],
      );
      expect(
        planColonialMilitary(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: _tribe1,
        ),
        const ColonialMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
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
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
          Province(
            id: 'newWorld|tribe1_b',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [],
        invadableNw: const ['newWorld|tribe1_b', 'newWorld|tribe1_a'],
      );
      expect(
        planColonialMilitary(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: _tribe1,
        ),
        const ColonialMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>[
            'newWorld|tribe1_a',
            'newWorld|tribe1_b',
          ],
          priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
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
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [
          Tribe(id: _tribe1, displayName: 'T1'),
          Tribe(id: _tribe2, displayName: 'T2'),
        ],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [],
        invadableNw: const ['newWorld|tribe1_a'],
      );
      expect(
        planColonialMilitary(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: _tribe2,
        ),
        same(ColonialMilitaryPlan.defaultPlan),
        reason:
            'When the declared colonial target owns nothing in NW '
            'invadable, the plan falls back to defaultPlan so the '
            'orchestrator can pick freely (legacy behaviour). An '
            'empty constraint must never leak.',
      );
    });

    test('AC: no declared target, at-war tribe owns NW invadable -> '
        'restrict to those provinces + sorted at-war owners', () {
      // Priority 2 fires when no declared target is given and at
      // least one at-war faction owns an NW invadable province. The
      // plan restricts to the union of those provinces and lists the
      // at-war owners sorted ascending. Tribes are first-class
      // colonial targets per issue #2509 § planColonialAcquisition.
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_tribe1],
        invadableNw: const ['newWorld|tribe1_a'],
      );
      expect(
        planColonialMilitary(game: game, snapshot: snapshot),
        const ColonialMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
        ),
        reason:
            'Priority 2 (at-war fallback): no declare-war target + '
            'an at-war tribe owns one NW invadable -> plan restricts '
            'to that province and lists the at-war owner.',
      );
    });

    test('no declared target, multiple at-war owners (tribe + minor) -> '
        'union of their invadable + sorted owners', () {
      // At-war fallback covers any faction class (GP, minor, tribe).
      // Two at-war owners contribute provinces; the plan unions them
      // and lists both owners sorted ascending.
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|minor1_a',
            regionId: 'newWorld',
            ownerId: _minor1,
          ),
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_tribe1, _minor1],
        invadableNw: const ['newWorld|tribe1_a', 'newWorld|minor1_a'],
      );
      expect(
        planColonialMilitary(game: game, snapshot: snapshot),
        ColonialMilitaryPlan(
          priorityDestinationProvinceIdsSorted: List<String>.unmodifiable(
            const <String>['newWorld|minor1_a', 'newWorld|tribe1_a'],
          ),
          priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(
            const <String>[_minor1, _tribe1],
          ),
        ),
        reason:
            'Priority 2 unions provinces across all at-war owners '
            '(tribe + minor). Provinces and owners are both sorted '
            'ascending in the plan output.',
      );
    });

    test('at-war owner with no NW invadable contribution is dropped from owner '
        'list', () {
      // An at-war faction that does NOT own any NW invadable province
      // must NOT appear in priorityTargetOwnerFactionIdsSorted. This
      // pins the "owner list mirrors actual destinations" contract so
      // a downstream orchestrator never sees a phantom target.
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [
          Tribe(id: _tribe1, displayName: 'T1'),
          Tribe(id: _tribe2, displayName: 'T2'),
        ],
      );
      final snapshot = _colonialSnapshot(
        // tribe2 is at war but owns nothing in NW invadable, so should
        // be dropped from the owner list.
        atWarWith: const [_tribe1, _tribe2],
        invadableNw: const ['newWorld|tribe1_a'],
      );
      expect(
        planColonialMilitary(game: game, snapshot: snapshot),
        const ColonialMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
        ),
        reason:
            'Only at-war owners that actually contribute an NW '
            'invadable province appear in priorityTargetOwnerFactionIdsSorted. '
            'tribe2 is at war but contributes nothing so it is dropped.',
      );
    });

    test('no declared target, no at-war owners hold NW invadable -> '
        'defaultPlan', () {
      // Priority 2 fails when no at-war faction owns an invadable NW
      // province. Both priority arms exhausted -> defaultPlan; the
      // orchestrator falls back to legacy free-choice conquest.
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [
          Tribe(id: _tribe1, displayName: 'T1'),
          Tribe(id: _tribe2, displayName: 'T2'),
        ],
      );
      final snapshot = _colonialSnapshot(
        // tribe2 is at war but does NOT own the invadable province.
        atWarWith: const [_tribe2],
        invadableNw: const ['newWorld|tribe1_a'],
      );
      expect(
        planColonialMilitary(game: game, snapshot: snapshot),
        same(ColonialMilitaryPlan.defaultPlan),
        reason:
            'No declared colonial target + no at-war faction owning '
            'an NW invadable -> defaultPlan (the orchestrator falls '
            'back to the legacy free-choice colonial-conquest '
            'behaviour).',
      );
    });

    test(
      'declared colonial target wins over at-war fallback (priority 1 over 2)',
      () {
        // Both arms could fire (target owns invadable AND another
        // at-war faction owns invadable), but priority 1 (declared
        // colonial target) takes precedence and excludes the at-war
        // non-target from the owner list.
        final game = _colonialGame(
          newWorldProvinces: const [
            Province(
              id: 'newWorld|tribe1_a',
              regionId: 'newWorld',
              ownerId: _tribe1,
            ),
            Province(
              id: 'newWorld|tribe2_a',
              regionId: 'newWorld',
              ownerId: _tribe2,
            ),
          ],
          tribes: const [
            Tribe(id: _tribe1, displayName: 'T1'),
            Tribe(id: _tribe2, displayName: 'T2'),
          ],
        );
        final snapshot = _colonialSnapshot(
          atWarWith: const [_tribe1, _tribe2],
          invadableNw: const ['newWorld|tribe1_a', 'newWorld|tribe2_a'],
        );
        expect(
          planColonialMilitary(
            game: game,
            snapshot: snapshot,
            colonialDeclaredWarTargetFactionId: _tribe1,
          ),
          const ColonialMilitaryPlan(
            priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
            priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
          ),
          reason:
              'Priority 1 (declared colonial target) wins over '
              'priority 2 (at-war fallback). tribe2 is at war and '
              'also owns an NW invadable province but is correctly '
              'excluded from the plan because a declared target is '
              'given.',
        );
      },
    );

    test('AC: OW invadable structurally suppressed (#2509 OW suppression)', () {
      // Acceptance criterion (issue #2509 § COLONIAL phase planner
      // § planColonialMilitary "Use runConquestArmyMovePlanner with NW
      // destination filter"): given an at-war minor owning an OW
      // invadable province that appears in
      // ConquestSummary.invadableProvinceIdsSorted, the plan must
      // NOT include the OW province. The planner only reads the NW
      // invadable list — OW suppression is structural, not
      // predicate-based.
      final game = _colonialGame(
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|minor1_a',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_tribe1, _minor1],
        invadableNw: const ['newWorld|tribe1_a'],
        // Even though the minor is at war AND owns an OW invadable
        // province in the conquest summary, the plan must not pick
        // up the OW province.
        invadableOw: const ['oldWorld|minor1_a'],
      );
      expect(
        planColonialMilitary(game: game, snapshot: snapshot),
        const ColonialMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
        ),
        reason:
            'COLONIAL OW suppression: the planner only reads '
            'snapshot.colonial.invadableNewWorldProvinceIdsSorted '
            '(NW-only). The OW invadable province must NOT leak into '
            'the plan even when an at-war owner is mentioned in the '
            'conquest summary.',
      );
    });

    test('declared target on OW-only invadable -> defaultPlan (structural OW '
        'suppression)', () {
      // Even with a declared target that owns ONLY OW invadable
      // provinces, the planner must return defaultPlan because the
      // target owns nothing in NW invadable. Combined with the
      // previous test this pins the structural OW suppression from
      // both sides.
      final game = _colonialGame(
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|minor1_a',
            regionId: 'oldWorld',
            ownerId: _minor1,
          ),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_minor1],
        invadableNw: const [],
        invadableOw: const ['oldWorld|minor1_a'],
      );
      expect(
        planColonialMilitary(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: _minor1,
        ),
        same(ColonialMilitaryPlan.defaultPlan),
        reason:
            'NW invadable list is empty -> the outer guard fires '
            'and returns defaultPlan regardless of any OW invadable '
            'state. COLONIAL OW suppression is structural at the '
            'planner level.',
      );
    });

    test('unowned NW invadable province is skipped (defensive)', () {
      // Defensive pin: an invadable province whose owner is missing
      // from the world (orphan / mid-transition) is silently skipped
      // rather than crashing. Tests the `if (owner == null) continue`
      // branch in the at-war fallback arm.
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_tribe1],
        // Include an unknown id that won't be in provinceOwner map.
        invadableNw: const ['newWorld|tribe1_a', 'newWorld|ghost'],
      );
      expect(
        planColonialMilitary(game: game, snapshot: snapshot),
        const ColonialMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
        ),
        reason:
            'Orphan NW invadable id with no owner is silently '
            'skipped; the rest of the priority 2 scan still produces '
            'a valid plan.',
      );
    });

    test('Refs #2509 Must-have #7 determinism: identical inputs -> identical '
        'plan', () {
      // Determinism pin (issue #2509 Must-have #7). Mixed-input
      // fixture exercises priority 1 with two destinations; the
      // same plan must come out twice in a row.
      final game = _colonialGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
          Province(
            id: 'newWorld|tribe1_b',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_tribe1, _gp2],
        invadableNw: const ['newWorld|tribe1_b', 'newWorld|tribe1_a'],
      );
      final first = planColonialMilitary(
        game: game,
        snapshot: snapshot,
        colonialDeclaredWarTargetFactionId: _tribe1,
      );
      final second = planColonialMilitary(
        game: game,
        snapshot: snapshot,
        colonialDeclaredWarTargetFactionId: _tribe1,
      );
      expect(second, first, reason: 'Same inputs -> same plan.');
    });

    test('multi-player game: invadable filter is owner-scoped, not '
        'active-player-scoped', () {
      // Isolation pin: the active player is gp1 but the planner is
      // filtering invadable provinces by their OWNER (the enemy
      // faction). gp1's own province ownership is irrelevant to the
      // filter — what matters is whether the invadable list contains
      // provinces owned by the declared target / at-war factions.
      final game = _colonialGame(
        newWorldProvinces: const [
          // gp3 owns this — at war but should be ignored because not
          // the declared target.
          Province(id: 'newWorld|gp3_0', regionId: 'newWorld', ownerId: _gp3),
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: _tribe1,
          ),
        ],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _colonialSnapshot(
        atWarWith: const [_gp3, _tribe1],
        invadableNw: const ['newWorld|gp3_0', 'newWorld|tribe1_a'],
      );
      expect(
        planColonialMilitary(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: _tribe1,
        ),
        const ColonialMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
        ),
        reason:
            'Priority 1 restricts ONLY to the declared target. gp3 '
            'is also at war and also owns an NW invadable province '
            'but is correctly excluded because the planner is keyed '
            'on owner == colonialDeclaredWarTargetFactionId.',
      );
    });

    test('ColonialMilitaryPlan value equality: same fields compare equal', () {
      // Value-class pin: `==` and `hashCode` must compare by list
      // contents so tests can assert against literal constructions
      // without relying on object identity.
      const a = ColonialMilitaryPlan(
        priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
        priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
      );
      const b = ColonialMilitaryPlan(
        priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
        priorityTargetOwnerFactionIdsSorted: <String>[_tribe1],
      );
      const c = ColonialMilitaryPlan(
        priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe2_a'],
        priorityTargetOwnerFactionIdsSorted: <String>[_tribe2],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test(
      'ColonialMilitaryPlan.defaultPlan equals explicit all-empty instance',
      () {
        // Default-plan pin: tests in the orchestrator wiring slice
        // (#2509 S5) may compare planner output against the shared
        // default instance OR a fresh `const ColonialMilitaryPlan(...)`.
        // Both must succeed.
        expect(
          ColonialMilitaryPlan.defaultPlan,
          const ColonialMilitaryPlan(
            priorityDestinationProvinceIdsSorted: <String>[],
            priorityTargetOwnerFactionIdsSorted: <String>[],
          ),
        );
      },
    );
  });
}
