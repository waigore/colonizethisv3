// Topic-split case module (Refs #4602 Slice B).

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

void registerExpandPhasePlannerMilitaryPriorityEarlyCases() {
  group('planExpandMilitary', () {
    test('at quota (own OW = 10) -> defaultPlan', () {
      // EXPAND outer gate: `isBelowObserverConquestQuota` is false when
      // own OW reaches `kObserverConquestMinOwProvincesPerGp` (10), so
      // the planner short-circuits before reading invadable or owner
      // state. A regression that dropped the outer gate would surface
      // a non-default plan for an at-quota GP.
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-military',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = buildExpandSnapshot(
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
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-military',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = buildExpandSnapshot(
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
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-military',
      );
      final snapshot = buildExpandSnapshot(
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
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-military',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = buildExpandSnapshot(
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
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-military',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
          Province(id: 'oldWorld|m1_b', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [MinorNation(id: _minor1, displayName: 'M1')],
      );
      final snapshot = buildExpandSnapshot(
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
      final game = buildExpandGame(
        gameIdLabel: 'expand-phase-planner-military',
        oldWorldProvinces: const [
          Province(id: 'oldWorld|m1_a', regionId: 'oldWorld', ownerId: _minor1),
        ],
        minorNations: const [
          MinorNation(id: _minor1, displayName: 'M1'),
          MinorNation(id: _minor2, displayName: 'M2'),
        ],
      );
      final snapshot = buildExpandSnapshot(
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
  });
}
