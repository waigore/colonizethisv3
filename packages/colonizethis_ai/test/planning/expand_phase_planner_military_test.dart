// Unit tests for `planExpandMilitary` in
// `packages/colonizethis_ai/lib/src/planning/expand_phase_planner.dart`
// (Refs #2509 S2 / S10).
//
// Spec contract (issue #2509 § EXPAND phase planner § planExpandMilitary):
//
//   "Conquest army moves toward OW invadable provinces only.
//      → Source: invadableProvinceIdsSorted, filtered to provinces owned
//        by the declare-war target (or any at-war owner if no target).
//      → Use existing runConquestArmyMovePlanner with EXPAND-only
//        destination filter.
//      → No NW army moves (structural — planner never queries colonial
//        summary)."
//
// Mirrors the test pattern established for the other EXPAND-phase
// planner contracts (`expand_phase_planner_test.dart`,
// `expand_phase_planner_declare_war_test.dart`,
// `expand_phase_planner_economy_test.dart`): small synthetic fixtures,
// one branch arm per test, in-module pin (the planner module never
// re-checks phase, so these tests stay scoped to the priority-arm
// branches plus the structural NW suppression).
//
// The "runConquestArmyMovePlanner" wiring + actual ArmyMoveOrder
// emission live at the orchestrator layer (#2509 S5) and are
// intentionally out of scope for this in-module pin — the unit pins
// the deterministic destination filter that the orchestrator consumes.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const String _gp1 = 'gp1';
const String _gp2 = 'gp2';
const String _gp3 = 'gp3';
const String _minor1 = 'minor1';
const String _minor2 = 'minor2';
const String _tribe1 = 'tribe1';

/// Game scaffold for EXPAND-phase military tests. Old World provinces,
/// players, minors, and tribes are passed in so each test can shape
/// ownership independently. The planner does not read armies or
/// treasury for the destination filter, but defaulting to a populated
/// player roster keeps the defensive `playerById` guard satisfied.
Game _expandGame({
  int turnNumber = 50,
  List<Province> oldWorldProvinces = const [],
  List<Player> players = const [
    Player(id: _gp1, displayName: 'GP1', isHuman: false, treasury: 9999),
    Player(id: _gp2, displayName: 'GP2', isHuman: false, treasury: 9999),
    Player(id: _gp3, displayName: 'GP3', isHuman: false, treasury: 9999),
  ],
  List<MinorNation> minorNations = const [],
  List<Tribe> tribes = const [],
}) {
  return Game(
    id: 'g-2509-expand-phase-planner-military-t$turnNumber',
    worldState: WorldState(
      turnState: TurnState(turnNumber: turnNumber, phase: TurnPhase.orders),
      oldWorld: RegionData(provinces: oldWorldProvinces),
      newWorld: const RegionData(),
    ),
    players: players,
    minorNations: minorNations,
    tribes: tribes,
  );
}

/// Snapshot tuned for EXPAND. Defaults to OW=8 (below quota of 10) with
/// `playerId = gp1`. Tests shape `atWarWith`, `invadableOw`,
/// `invadableNw`, and `oldWorldProvincesOwned` to exercise specific
/// priority arms and the structural NW suppression.
AIWorldSnapshot _expandSnapshot({
  required List<String> atWarWith,
  List<String> invadableOw = const [],
  List<String> invadableNw = const [],
  int oldWorldProvincesOwned = 8,
  String playerId = _gp1,
}) {
  return AIWorldSnapshot(
    playerId: playerId,
    threats: ThreatSummary(atWarWith: atWarWith),
    opportunities: const OpportunitySummary(),
    conquest: ConquestSummary(
      oldWorldProvincesOwned: oldWorldProvincesOwned,
      provincesToVictory: kObserverConquestMinOwProvincesPerGp * 3,
      invadableProvinceIdsSorted: invadableOw,
    ),
    colonial: ColonialSummary(invadableNewWorldProvinceIdsSorted: invadableNw),
    economy: const EconomySummary(),
    relations: const {},
  );
}

void main() {
  group('planExpandMilitary', () {
    test('at quota (own OW = 10) -> defaultPlan', () {
      // EXPAND outer gate: `isBelowObserverConquestQuota` is false when
      // own OW reaches `kObserverConquestMinOwProvincesPerGp` (10), so
      // the planner short-circuits before reading invadable or owner
      // state. A regression that dropped the outer gate would surface
      // a non-default plan for an at-quota GP.
      final game = _expandGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_minor1],
        invadableOw: const ['oldWorld|m1_a'],
        oldWorldProvincesOwned: 10,
      );
      expect(
        planExpandMilitary(game: game, snapshot: snapshot),
        same(ExpandMilitaryPlan.defaultPlan),
        reason:
            'GP at the observer OW quota is no longer EXPAND territory '
            'for this planner; the outer `isBelowObserverConquestQuota` '
            'gate must short-circuit before reading invadable state.',
      );
    });

    test('player not in game -> defaultPlan (defensive guard)', () {
      // Defensive guard pin: snapshots pointing at a non-existent
      // player must not crash; the planner returns the default plan.
      // Matches the equivalent guard in `planExpandDeclareWar` and
      // `planExpandEconomy`.
      final game = _expandGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_minor1],
        invadableOw: const ['oldWorld|m1_a'],
        playerId: 'ghost-player',
      );
      expect(
        planExpandMilitary(game: game, snapshot: snapshot),
        ExpandMilitaryPlan.defaultPlan,
      );
    });

    test('empty invadable -> defaultPlan', () {
      // No OW frontier means there is no province to filter; the
      // function must short-circuit before any priority-arm scan so
      // an empty constraint never leaks to the orchestrator.
      final game = _expandGame();
      final snapshot = _expandSnapshot(
        atWarWith: const [_gp2],
        invadableOw: const [],
      );
      expect(
        planExpandMilitary(game: game, snapshot: snapshot),
        same(ExpandMilitaryPlan.defaultPlan),
      );
    });

    test('AC: declared-war target owns one invadable OW -> restrict to that '
        'province + target only owner', () {
      // Acceptance criterion (issue #2509 Phase planner unit tests):
      // priority 1 fires when the declare-war target owns at least
      // one invadable OW province. The plan restricts conquest to
      // exactly that province and lists only the target as the
      // priority owner.
      final game = _expandGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [],
        invadableOw: const ['oldWorld|m1_a'],
      );
      expect(
        planExpandMilitary(
          game: game,
          snapshot: snapshot,
          declaredWarTargetFactionId: _minor1,
        ),
        const ExpandMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['oldWorld|m1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[_minor1],
        ),
        reason:
            'Priority 1: declare-war target owns one OW invadable '
            'province -> plan restricts to that province and lists '
            'only the target as the priority owner.',
      );
    });

    test('declared-war target owns multiple invadable OW -> all those '
        'provinces, sorted ascending', () {
      // Multiple invadable provinces under the same declared target:
      // the plan keeps all of them, sorted ascending, regardless of
      // the input order in invadableProvinceIdsSorted (defensive
      // determinism against future builder changes).
      final game = _expandGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
          Province(id: 'oldWorld|m1_b', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [],
        // Provide in reverse-sorted order to verify the sort.
        invadableOw: const ['oldWorld|m1_b', 'oldWorld|m1_a'],
      );
      expect(
        planExpandMilitary(
          game: game,
          snapshot: snapshot,
          declaredWarTargetFactionId: _minor1,
        ),
        const ExpandMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>[
            'oldWorld|m1_a',
            'oldWorld|m1_b',
          ],
          priorityTargetOwnerFactionIdsSorted: <String>[_minor1],
        ),
        reason:
            'Priority 1 keeps ALL invadable provinces owned by the '
            'declared target, sorted ascending. Output order is '
            'independent of the input invadable list order.',
      );
    });

    test('declared-war target owns no invadable -> defaultPlan', () {
      // Priority 1 fails when the declared target owns nothing in OW
      // invadable. Per the spec the orchestrator should fall back to
      // its existing free-choice behaviour, so the planner returns
      // the default plan rather than an empty constraint.
      final game = _expandGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [
          MinorNation(id: _minor1, displayName: 'M1'),
          MinorNation(id: _minor2, displayName: 'M2'),
        ],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [],
        invadableOw: const ['oldWorld|m1_a'],
      );
      expect(
        planExpandMilitary(
          game: game,
          snapshot: snapshot,
          // minor2 owns nothing in OW invadable.
          declaredWarTargetFactionId: _minor2,
        ),
        same(ExpandMilitaryPlan.defaultPlan),
        reason:
            'When the declared-war target owns nothing in OW '
            'invadable, the plan falls back to defaultPlan so the '
            'orchestrator can pick freely (legacy behaviour). An '
            'empty constraint must never leak.',
      );
    });

    test('AC: no declared-war target, at-war minor owns invadable OW -> '
        'restrict to those provinces + sorted at-war owners', () {
      // Priority 2 fires when no declared target is given and at
      // least one at-war faction owns an OW invadable province. The
      // plan restricts to the union of those provinces and lists the
      // at-war owners sorted ascending.
      final game = _expandGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_minor1],
        invadableOw: const ['oldWorld|m1_a'],
      );
      expect(
        planExpandMilitary(game: game, snapshot: snapshot),
        const ExpandMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['oldWorld|m1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[_minor1],
        ),
        reason:
            'Priority 2 (at-war fallback): no declare-war target + '
            'an at-war minor owns one OW invadable -> plan restricts '
            'to that province and lists the at-war owner.',
      );
    });

    test('no declared-war target, multiple at-war owners (GP + minor) -> '
        'union of their invadable + sorted owners', () {
      // At-war fallback covers any faction class (GP, minor, tribe).
      // Two at-war owners contribute provinces; the plan unions them
      // and lists both owners sorted ascending.
      final game = _expandGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|gp2_0', regionId: 'oldWorld', ownerId: _gp2),
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_gp2, _minor1],
        invadableOw: const ['oldWorld|m1_a', 'oldWorld|gp2_0'],
      );
      expect(
        planExpandMilitary(game: game, snapshot: snapshot),
        ExpandMilitaryPlan(
          priorityDestinationProvinceIdsSorted: List<String>.unmodifiable(
            const <String>['oldWorld|gp2_0', 'oldWorld|m1_a'],
          ),
          priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(
            const <String>[_gp2, _minor1],
          ),
        ),
        reason:
            'Priority 2 unions provinces across all at-war owners '
            '(GP + minor). Provinces and owners are both sorted '
            'ascending in the plan output.',
      );
    });

    test('at-war owner with no invadable contribution is dropped from owner '
        'list', () {
      // An at-war faction that does NOT own any invadable OW province
      // must NOT appear in priorityTargetOwnerFactionIdsSorted. This
      // pins the "owner list mirrors actual destinations" contract so
      // a downstream orchestrator never sees a phantom target.
      final game = _expandGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [
          MinorNation(id: _minor1, displayName: 'M1'),
          MinorNation(id: _minor2, displayName: 'M2'),
        ],
      );
      final snapshot = _expandSnapshot(
        // minor2 is at war but owns nothing in OW invadable, so should
        // be dropped from the owner list.
        atWarWith: const [_minor1, _minor2],
        invadableOw: const ['oldWorld|m1_a'],
      );
      expect(
        planExpandMilitary(game: game, snapshot: snapshot),
        const ExpandMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['oldWorld|m1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[_minor1],
        ),
        reason:
            'Only at-war owners that actually contribute an invadable '
            'province appear in priorityTargetOwnerFactionIdsSorted. '
            'minor2 is at war but contributes nothing so it is dropped.',
      );
    });

    test('no declared-war target, no at-war owners hold invadable -> '
        'defaultPlan', () {
      // Priority 2 fails when no at-war faction owns an invadable OW
      // province. Both priority arms exhausted -> defaultPlan; the
      // orchestrator falls back to legacy free-choice conquest.
      final game = _expandGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [
          MinorNation(id: _minor1, displayName: 'M1'),
          MinorNation(id: _minor2, displayName: 'M2'),
        ],
      );
      final snapshot = _expandSnapshot(
        // minor2 is at war but does NOT own the invadable province.
        atWarWith: const [_minor2],
        invadableOw: const ['oldWorld|m1_a'],
      );
      expect(
        planExpandMilitary(game: game, snapshot: snapshot),
        same(ExpandMilitaryPlan.defaultPlan),
        reason:
            'No declare-war target + no at-war faction owning an '
            'OW invadable -> defaultPlan (the orchestrator falls '
            'back to the legacy free-choice conquest behaviour).',
      );
    });

    test(
      'declared-war target wins over at-war fallback (priority 1 over 2)',
      () {
        // Both arms could fire (target owns invadable AND another at-war
        // faction owns invadable), but priority 1 (declare-war target)
        // takes precedence and excludes the at-war non-target from the
        // owner list.
        final game = _expandGame(
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|m1_a',
              regionId: 'oldWorld',
              ownerId: _minor1,
            ),
            Province(
              id: 'oldWorld|m2_a',
              regionId: 'oldWorld',
              ownerId: _minor2,
            ),
          ],
          minorNations: const [
            MinorNation(id: _minor1, displayName: 'M1'),
            MinorNation(id: _minor2, displayName: 'M2'),
          ],
        );
        final snapshot = _expandSnapshot(
          atWarWith: const [_minor1, _minor2],
          invadableOw: const ['oldWorld|m1_a', 'oldWorld|m2_a'],
        );
        expect(
          planExpandMilitary(
            game: game,
            snapshot: snapshot,
            declaredWarTargetFactionId: _minor1,
          ),
          const ExpandMilitaryPlan(
            priorityDestinationProvinceIdsSorted: <String>['oldWorld|m1_a'],
            priorityTargetOwnerFactionIdsSorted: <String>[_minor1],
          ),
          reason:
              'Priority 1 (declare-war target) wins over priority 2 '
              '(at-war fallback). minor2 is at war and owns an invadable '
              'province but is correctly excluded from the plan because '
              'a declare-war target is given.',
        );
      },
    );

    test('AC: NW invadable structurally suppressed (#2509 EXPAND NW '
        'suppression)', () {
      // Acceptance criterion (issue #2509 Phase planner unit tests §
      // "EXPAND NW suppression"): given an at-war tribe owning a New
      // World province that appears in
      // ColonialSummary.invadableNewWorldProvinceIdsSorted, the plan
      // must NOT include the NW province. The planner only reads the
      // OW invadable list — NW suppression is structural, not
      // predicate-based.
      final game = _expandGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_minor1, _tribe1],
        invadableOw: const ['oldWorld|m1_a'],
        // Even though the tribe is at war AND owns a NW invadable
        // province in the colonial summary, the plan must not pick
        // up the NW province.
        invadableNw: const ['newWorld|tribe1_a'],
      );
      expect(
        planExpandMilitary(game: game, snapshot: snapshot),
        const ExpandMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['oldWorld|m1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[_minor1],
        ),
        reason:
            'EXPAND NW suppression: the planner only reads '
            'snapshot.conquest.invadableProvinceIdsSorted (OW-only). '
            'The NW invadable province must NOT leak into the plan '
            'even when an at-war owner is mentioned in the colonial '
            'summary.',
      );
    });

    test('declared-war target on NW province -> defaultPlan (structural '
        'NW suppression)', () {
      // Even with a declared-war target that owns ONLY NW invadable
      // provinces, the planner must return defaultPlan because the
      // target owns nothing in OW invadable. Combined with the
      // previous test this pins the structural NW suppression from
      // both sides.
      final game = _expandGame(
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_tribe1],
        invadableOw: const [],
        invadableNw: const ['newWorld|tribe1_a'],
      );
      expect(
        planExpandMilitary(
          game: game,
          snapshot: snapshot,
          declaredWarTargetFactionId: _tribe1,
        ),
        same(ExpandMilitaryPlan.defaultPlan),
        reason:
            'OW invadable list is empty -> the outer guard fires '
            'and returns defaultPlan regardless of any NW invadable '
            'state. EXPAND NW suppression is structural at the '
            'planner level.',
      );
    });

    test('unowned invadable province is skipped (defensive)', () {
      // Defensive pin: an invadable province whose owner is missing
      // from the world (orphan / mid-transition) is silently skipped
      // rather than crashing. Tests the `if (owner == null) continue`
      // branch in the at-war fallback arm.
      final game = _expandGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_minor1],
        // Include an unknown id that won't be in provinceOwner map.
        invadableOw: const ['oldWorld|m1_a', 'oldWorld|ghost'],
      );
      expect(
        planExpandMilitary(game: game, snapshot: snapshot),
        const ExpandMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['oldWorld|m1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[_minor1],
        ),
        reason:
            'Orphan invadable id with no owner is silently skipped; '
            'the rest of the priority 2 scan still produces a valid '
            'plan.',
      );
    });

    test('Refs #2509 Must-have #7 determinism: identical inputs -> identical '
        'plan', () {
      // Determinism pin (issue #2509 Must-have #7). Mixed-input
      // fixture exercises both priority arms via a tie between
      // declare-war target and an additional at-war faction; the
      // same plan must come out twice in a row.
      final game = _expandGame(
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
          Province(id: 'oldWorld|m1_b', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_minor1, _gp2],
        invadableOw: const ['oldWorld|m1_b', 'oldWorld|m1_a'],
      );
      final first = planExpandMilitary(
        game: game,
        snapshot: snapshot,
        declaredWarTargetFactionId: _minor1,
      );
      final second = planExpandMilitary(
        game: game,
        snapshot: snapshot,
        declaredWarTargetFactionId: _minor1,
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
      final game = _expandGame(
        oldWorldProvinces: const [
          // gp3 owns this — at war but should be ignored because not
          // the declared target.
          Province(id: 'oldWorld|gp3_0', regionId: 'oldWorld', ownerId: _gp3),
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = _expandSnapshot(
        atWarWith: const [_gp3, _minor1],
        invadableOw: const ['oldWorld|gp3_0', 'oldWorld|m1_a'],
      );
      expect(
        planExpandMilitary(
          game: game,
          snapshot: snapshot,
          declaredWarTargetFactionId: _minor1,
        ),
        const ExpandMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['oldWorld|m1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[_minor1],
        ),
        reason:
            'Priority 1 restricts ONLY to the declared target. gp3 '
            'is also at war and also owns an invadable province but '
            'is correctly excluded because the planner is keyed on '
            'owner == declaredWarTargetFactionId.',
      );
    });

    test('ExpandMilitaryPlan value equality: same fields compare equal', () {
      // Value-class pin: `==` and `hashCode` must compare by list
      // contents so tests can assert against literal constructions
      // without relying on object identity.
      const a = ExpandMilitaryPlan(
        priorityDestinationProvinceIdsSorted: <String>['oldWorld|m1_a'],
        priorityTargetOwnerFactionIdsSorted: <String>[_minor1],
      );
      const b = ExpandMilitaryPlan(
        priorityDestinationProvinceIdsSorted: <String>['oldWorld|m1_a'],
        priorityTargetOwnerFactionIdsSorted: <String>[_minor1],
      );
      const c = ExpandMilitaryPlan(
        priorityDestinationProvinceIdsSorted: <String>['oldWorld|m2_a'],
        priorityTargetOwnerFactionIdsSorted: <String>[_minor2],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(equals(c)));
    });

    test(
      'ExpandMilitaryPlan.defaultPlan equals an explicit all-empty instance',
      () {
        // Default-plan pin: tests in the orchestrator wiring slice
        // (#2509 S5) may compare planner output against the shared
        // default instance OR a fresh `const ExpandMilitaryPlan(...)`.
        // Both must succeed.
        expect(
          ExpandMilitaryPlan.defaultPlan,
          const ExpandMilitaryPlan(
            priorityDestinationProvinceIdsSorted: <String>[],
            priorityTargetOwnerFactionIdsSorted: <String>[],
          ),
        );
      },
    );
  });
}
