// Case bodies for `expand_phase_planner_military_test.dart` (Refs #4104 Slice C).

import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'expand_phase_planner_military_support.dart';
import 'test_game_factories.dart';

const String _gp2 = expandMilitaryGp2;
const String _gp3 = expandMilitaryGp3;
const String _minor1 = expandMilitaryMinor1;
const String _minor2 = expandMilitaryMinor2;
const String _tribe1 = expandMilitaryTribe1;

void registerExpandPhasePlannerMilitarySuppressionCases() {
  group('planExpandMilitary', () {
    test(
      'declared-war target wins over at-war fallback (priority 1 over 2)',
      () {
        // Both arms could fire (target owns invadable AND another at-war
        // faction owns invadable), but priority 1 (declare-war target)
        // takes precedence and excludes the at-war non-target from the
        // owner list.
        final game = buildExpandGame(
          gameIdLabel: 'expand-phase-planner-military',
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
        final snapshot = buildExpandSnapshot(
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
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-military',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = buildExpandSnapshot(
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
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-military',
        tribes: const [Tribe(id: _tribe1, displayName: 'T1')],
      );
      final snapshot = buildExpandSnapshot(
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
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-military',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = buildExpandSnapshot(
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
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-military',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
          Province(id: 'oldWorld|m1_b', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = buildExpandSnapshot(
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
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-military',
        oldWorldProvinces: const [
          // gp3 owns this — at war but should be ignored because not
          // the declared target.
          Province(id: 'oldWorld|gp3_0', regionId: 'oldWorld', ownerId: _gp3),
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = buildExpandSnapshot(
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
