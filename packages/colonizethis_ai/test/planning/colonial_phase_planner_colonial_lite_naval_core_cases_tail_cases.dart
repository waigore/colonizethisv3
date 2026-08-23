// Case bodies for `colonial_phase_planner_colonial_lite_naval_test.dart`
// (Refs #3997 Phase 8). Registered from the thin contract; pin coverage
// preserved 1:1 from the former inline suite.

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_phase_planner_test_support.dart';


void registerColonialPhasePlannerColonialLiteNavalCoreCasesTail() {
  group('planColonialLiteNaval', () {
    test('GP-owned NW invadable filtered out (structural)', () {
      // GP-owned NW invadable must NOT appear in the plan. COLONIAL-lite
      // is the safeguard for tribe / minor NW penetration only;
      // GP-owned NW is structurally excluded because the spec suppresses
      // NW `declareWar` and `purchase_land` here (issue #2509
      // § COLONIAL-lite suppressed list).
      final game = buildColonialLiteNavalGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|gp2_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseGp2,
          ),
        ],
      );
      final snapshot = buildColonialLiteNavalSnapshot(
        invadableNw: const ['newWorld|gp2_a'],
      );
      expect(
        planColonialLiteNaval(game: game, snapshot: snapshot),
        same(ColonialLiteNavalPlan.defaultPlan),
        reason:
            'GP-owned NW invadable is structurally excluded from the '
            'COLONIAL-lite naval focus; with no tribe / minor contributing '
            'any province the plan falls back to defaultPlan.',
      );
    });

    test('mixed: tribe + minor + GP-owned NW invadable -> only tribe + minor '
        'returned, sorted ascending', () {
      // Composite filter pin (GP filter + multi-owner union). The
      // GP-owned province is dropped; the tribe and minor provinces
      // surface in `priorityNwProvinceIdsSorted` (sorted ascending),
      // and both owners appear in
      // `priorityTargetOwnerFactionIdsSorted` (sorted ascending,
      // deduplicated).
      final game = buildColonialLiteNavalGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseTribe1,
          ),
          Province(
            id: 'newWorld|minor1_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseMinor1,
          ),
          Province(
            id: 'newWorld|gp2_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseGp2,
          ),
        ],
        tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
        minorNations: const [
          MinorNation(id: kColonialPhaseMinor1, displayName: 'M1'),
        ],
      );
      final snapshot = buildColonialLiteNavalSnapshot(
        invadableNw: const [
          'newWorld|tribe1_a',
          'newWorld|minor1_a',
          'newWorld|gp2_a',
        ],
      );
      expect(
        planColonialLiteNaval(game: game, snapshot: snapshot),
        const ColonialLiteNavalPlan(
          priorityNwProvinceIdsSorted: <String>[
            'newWorld|minor1_a',
            'newWorld|tribe1_a',
          ],
          priorityTargetOwnerFactionIdsSorted: <String>[
            kColonialPhaseMinor1,
            kColonialPhaseTribe1,
          ],
        ),
        reason:
            'Composite filter: GP-owned NW invadable dropped; tribe + '
            'minor NW invadable surface in the plan with both lists '
            'sorted ascending. minor1 < tribe1 lexically so minor1 '
            'sorts first in both fields.',
      );
    });

    test('only GP-owned NW invadable -> defaultPlan', () {
      // Priority-arm fall-through pin: with no tribe / minor
      // contributing any NW invadable, the planner returns the default
      // plan and the orchestrator falls back to legacy free-choice
      // colonial naval behaviour.
      final game = buildColonialLiteNavalGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|gp2_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseGp2,
          ),
          Province(
            id: 'newWorld|gp3_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseGp3,
          ),
        ],
      );
      final snapshot = buildColonialLiteNavalSnapshot(
        invadableNw: const ['newWorld|gp2_a', 'newWorld|gp3_a'],
      );
      expect(
        planColonialLiteNaval(game: game, snapshot: snapshot),
        same(ColonialLiteNavalPlan.defaultPlan),
        reason:
            'Only GP-owned NW invadable + no tribe / minor contributor '
            '-> defaultPlan (the orchestrator falls back to the legacy '
            'free-choice colonial naval behaviour over the full NW '
            'invadable set).',
      );
    });

    test('orphan NW invadable id with no owner -> silently skipped', () {
      // A snapshot can list an invadable NW id that no longer maps to a
      // province (stale fixture, mid-resolution diff, etc.). The
      // planner must silently skip the orphan via the
      // `if (owner == null) continue` branch and not blow up.
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
        invadableNw: const ['newWorld|orphan', 'newWorld|tribe1_a'],
      );
      expect(
        planColonialLiteNaval(game: game, snapshot: snapshot),
        const ColonialLiteNavalPlan(
          priorityNwProvinceIdsSorted: <String>['newWorld|tribe1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
        ),
        reason:
            'Orphan invadable id (no province record) is silently '
            'skipped; the live tribe-owned province still surfaces in '
            'the plan.',
      );
    });

    test('determinism: identical inputs yield identical plans', () {
      // Pure-function determinism (Refs #2509 Must-have #7) -- the
      // planner is called twice with the same inputs and must return
      // equal plans across both calls.
      final game = buildColonialLiteNavalGame(
        newWorldProvinces: const [
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseTribe1,
          ),
          Province(
            id: 'newWorld|minor1_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseMinor1,
          ),
        ],
        tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
        minorNations: const [
          MinorNation(id: kColonialPhaseMinor1, displayName: 'M1'),
        ],
      );
      final snapshot = buildColonialLiteNavalSnapshot(
        invadableNw: const ['newWorld|tribe1_a', 'newWorld|minor1_a'],
      );
      final first = planColonialLiteNaval(game: game, snapshot: snapshot);
      final second = planColonialLiteNaval(game: game, snapshot: snapshot);
      expect(first, equals(second));
    });
  });
}
