// Case bodies for `colonial_phase_planner_colonial_lite_naval_test.dart`
// (Refs #3997 Phase 8). Registered from the thin contract; pin coverage
// preserved 1:1 from the former inline suite.

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_phase_planner_test_support.dart';
import 'colonial_phase_planner_colonial_lite_naval_core_cases_tail_cases.dart';


void registerColonialPhasePlannerColonialLiteNavalCoreCases() {
  group('planColonialLiteNaval', () {
    test('missing active player -> defaultPlan', () {
      // Defensive guard pin: snapshots pointing at a non-existent
      // player must not crash; the planner returns the default plan.
      // Matches the symmetric guard in [planColonialLiteOvertures] and
      // [planColonialMilitary].
      final game = buildColonialLiteNavalGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseTribe1,
          ),
        ],
        tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
      );
      final snapshot = buildColonialLiteNavalSnapshot(
        invadableNw: const ['newWorld|tribe1_a'],
        playerId: 'ghost-player',
      );
      expect(
        planColonialLiteNaval(game: game, snapshot: snapshot),
        same(ColonialLiteNavalPlan.defaultPlan),
        reason:
            'Active player is missing from the game roster; the planner '
            'must short-circuit before reading any owner state and return '
            'the shared defaultPlan instance.',
      );
    });

    test('empty NW invadable -> defaultPlan', () {
      // No NW frontier means there is no province to filter; the
      // function must short-circuit before any owner scan so an empty
      // constraint never leaks to the orchestrator.
      final game = buildColonialLiteNavalGame();
      final snapshot = buildColonialLiteNavalSnapshot(invadableNw: const []);
      expect(
        planColonialLiteNaval(game: game, snapshot: snapshot),
        same(ColonialLiteNavalPlan.defaultPlan),
      );
    });

    test('AC: single tribe-owned NW invadable -> restrict to that province '
        '+ tribe as sole owner', () {
      // Canonical happy path from the spec: a single tribe-owned NW
      // invadable province surfaces in the plan as the exploration
      // focus. A regression that filtered tribes structurally
      // would show empty here.
      final game = buildColonialLiteNavalGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseTribe1,
          ),
        ],
        tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
      );
      final snapshot = buildColonialLiteNavalSnapshot(
        invadableNw: const ['newWorld|tribe1_a'],
      );
      expect(
        planColonialLiteNaval(game: game, snapshot: snapshot),
        const ColonialLiteNavalPlan(
          priorityNwProvinceIdsSorted: <String>['newWorld|tribe1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
        ),
        reason:
            'Canonical COLONIAL-lite naval focus: single tribe-owned NW '
            'invadable -> plan restricts to that province and lists the '
            'tribe as the sole priority owner.',
      );
    });

    test('single minor-owned NW invadable -> restrict to that province + minor '
        'as sole owner', () {
      // Mirror branch from the minor-owner side. Tribes and minors are
      // both first-class COLONIAL-lite naval targets per issue #2509
      // § COLONIAL-lite "establishOverture toward visible NW tribe /
      // minor owners".
      final game = buildColonialLiteNavalGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|minor1_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseMinor1,
          ),
        ],
        minorNations: const [
          MinorNation(id: kColonialPhaseMinor1, displayName: 'M1'),
        ],
      );
      final snapshot = buildColonialLiteNavalSnapshot(
        invadableNw: const ['newWorld|minor1_a'],
      );
      expect(
        planColonialLiteNaval(game: game, snapshot: snapshot),
        const ColonialLiteNavalPlan(
          priorityNwProvinceIdsSorted: <String>['newWorld|minor1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseMinor1],
        ),
        reason:
            'Minors are first-class COLONIAL-lite naval targets (same '
            'class as tribes); the planner does not discriminate '
            'between Tribe and MinorNation entries.',
      );
    });

    test('multiple tribe-owned NW invadable -> all those provinces, '
        'sorted ascending', () {
      // Multiple tribe-owned NW invadable provinces: the COLONIAL-lite
      // naval focus keeps ALL of them, sorted ascending, regardless
      // of the input order. Defensive determinism against future
      // builder changes (Refs #2509 Must-have #7).
      final game = buildColonialLiteNavalGame(
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
      final snapshot = buildColonialLiteNavalSnapshot(
        invadableNw: const ['newWorld|tribe1_b', 'newWorld|tribe1_a'],
      );
      expect(
        planColonialLiteNaval(game: game, snapshot: snapshot),
        const ColonialLiteNavalPlan(
          priorityNwProvinceIdsSorted: <String>[
            'newWorld|tribe1_a',
            'newWorld|tribe1_b',
          ],
          priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
        ),
        reason:
            'COLONIAL-lite naval focus keeps ALL tribe-owned NW invadable '
            'provinces, sorted ascending. Output order is independent of '
            'the input invadable list order.',
      );
    });
  });

  registerColonialPhasePlannerColonialLiteNavalCoreCasesTail();
}
