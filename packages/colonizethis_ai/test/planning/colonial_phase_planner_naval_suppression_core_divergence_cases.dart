// Topic-split case module (Refs #3997 Phase 8).
// Registered from the thin contract / barrel for this family.
// Pin/row coverage is preserved 1:1 from the former combined cases file.

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/colonial_phase_planner_test_support.dart';

void registerColonialPhasePlannerNavalSuppressionCoreDivergenceCases() {
  group('planColonialNaval', () {
    test('orphan NW invadable id with no owner -> silently skipped', () {
      // Defensive pin: an invadable province whose owner is missing
      // from the world (orphan / mid-transition) is silently skipped
      // rather than crashing. Tests the `if (owner == null) continue`
      // branch in the at-war fallback arm.
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
        // Include an unknown id that won't be in provinceOwner map.
        invadableNw: const ['newWorld|tribe1_a', 'newWorld|ghost'],
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
            'Orphan NW invadable id with no owner is silently '
            'skipped; the rest of the priority 2 scan still produces '
            'a valid plan.',
      );
    });

    test(
      'Refs #2509 Must-have #7 determinism: identical inputs -> identical plan',
      () {
        // Determinism pin (issue #2509 Must-have #7). Mixed-input
        // fixture exercises priority 1 with two destinations; the
        // same plan must come out twice in a row.
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
          atWarWith: const [kColonialPhaseTribe1, kColonialPhaseGp2],
          invadableNw: const ['newWorld|tribe1_b', 'newWorld|tribe1_a'],
        );
        final first = planColonialNaval(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: kColonialPhaseTribe1,
        );
        final second = planColonialNaval(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: kColonialPhaseTribe1,
        );
        expect(second, equals(first), reason: 'Same inputs -> same plan.');
      },
    );

    test('AC divergence from planColonialLiteNaval: declared colonial target '
        'GP owns NW invadable -> included in invasion-transport plan', () {
      // Explicit divergence from [planColonialLiteNaval]: COLONIAL
      // allows invasion (declareWar + transport) against any
      // faction class -- tribes, minor nations, AND Great Powers
      // blocking the colonial frontier (issue #2509 §
      // planColonialAcquisition step 3). A GP-owned NW invadable
      // province MUST surface in the plan when the declared
      // colonial target is that GP. The COLONIAL-lite sibling, by
      // contrast, filters GP-owned NW invadable out entirely.
      final game = buildColonialPhaseGame(
        newWorldProvinces: const [
          Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: kColonialPhaseGp2),
        ],
      );
      final snapshot = buildColonialPhaseSnapshot(
        atWarWith: const [kColonialPhaseGp2],
        invadableNw: const ['newWorld|gp2_a'],
      );
      expect(
        planColonialNaval(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: kColonialPhaseGp2,
        ),
        const ColonialNavalPlan(
          priorityInvasionTransportProvinceIdsSorted: <String>[
            'newWorld|gp2_a',
          ],
          priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseGp2],
        ),
        reason:
            'COLONIAL allows invasion against GP colonial blockers '
            '(declareWar acquisition method 3). A GP-owned NW '
            'invadable province surfaces in the invasion-transport '
            'plan when that GP is the declared colonial target. '
            'COLONIAL-lite would filter this out structurally; '
            'COLONIAL must not.',
      );
    });

    test(
      'GP-owned NW invadable via at-war fallback (priority 2) -> included',
      () {
        // Mirror branch from priority 2: a GP at war owning an NW
        // invadable province contributes that province to the
        // invasion-transport plan even without an explicit
        // colonialDeclaredWarTargetFactionId. Pins the structural
        // divergence from [planColonialLiteNaval] from the at-war
        // fallback side.
        final game = buildColonialPhaseGame(
          newWorldProvinces: const [
            Province(id: 'newWorld|gp2_a', regionId: 'newWorld', ownerId: kColonialPhaseGp2),
          ],
        );
        final snapshot = buildColonialPhaseSnapshot(
          atWarWith: const [kColonialPhaseGp2],
          invadableNw: const ['newWorld|gp2_a'],
        );
        expect(
          planColonialNaval(game: game, snapshot: snapshot),
          const ColonialNavalPlan(
            priorityInvasionTransportProvinceIdsSorted: <String>[
              'newWorld|gp2_a',
            ],
            priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseGp2],
          ),
          reason:
              'COLONIAL at-war fallback admits GP owners. An at-war '
              'GP owning an NW invadable province is a legitimate '
              'invasion-transport target (the GP colonial blocker '
              'scenario from issue #2509 § primaryColonialGpBlocker).',
        );
      },
    );

    test('multi-player game: invadable filter is owner-scoped, not '
        'active-player-scoped', () {
      // Isolation pin: the active player is gp1 but the planner is
      // filtering invadable provinces by their OWNER (the enemy
      // faction). gp1's own province ownership is irrelevant to
      // the filter -- what matters is whether the invadable list
      // contains provinces owned by the declared target / at-war
      // factions.
      final game = buildColonialPhaseGame(
        newWorldProvinces: const [
          // gp3 owns this -- at war but should be ignored because
          // not the declared target.
          Province(id: 'newWorld|gp3_0', regionId: 'newWorld', ownerId: kColonialPhaseGp3),
          Province(
            id: 'newWorld|tribe1_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseTribe1,
          ),
        ],
        tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
      );
      final snapshot = buildColonialPhaseSnapshot(
        atWarWith: const [kColonialPhaseGp3, kColonialPhaseTribe1],
        invadableNw: const ['newWorld|gp3_0', 'newWorld|tribe1_a'],
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
            'Priority 1 restricts ONLY to the declared target. gp3 '
            'is also at war and also owns an NW invadable province '
            'but is correctly excluded because the planner is keyed '
            'on owner == colonialDeclaredWarTargetFactionId.',
      );
    });

    test('input order shuffled -> ascending sort recovers', () {
      // Defensive determinism pin: even if a future builder
      // regression delivers the invadable list reversed, the
      // planner's trailing `destinations.sort()` recovers ascending
      // order for both priority arms.
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
          Province(
            id: 'newWorld|minor1_a',
            regionId: 'newWorld',
            ownerId: kColonialPhaseMinor1,
          ),
        ],
        tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
        minorNations: const [MinorNation(id: kColonialPhaseMinor1, displayName: 'M1')],
      );
      final snapshot = buildColonialPhaseSnapshot(
        // Reversed input order across both owners.
        atWarWith: const [kColonialPhaseTribe1, kColonialPhaseMinor1],
        invadableNw: const [
          'newWorld|tribe1_b',
          'newWorld|tribe1_a',
          'newWorld|minor1_a',
        ],
      );
      final plan = planColonialNaval(game: game, snapshot: snapshot);
      expect(
        plan.priorityInvasionTransportProvinceIdsSorted,
        const <String>[
          'newWorld|minor1_a',
          'newWorld|tribe1_a',
          'newWorld|tribe1_b',
        ],
        reason:
            'Trailing sort recovers ascending province order across '
            'reversed input.',
      );
      expect(
        plan.priorityTargetOwnerFactionIdsSorted,
        const <String>[kColonialPhaseMinor1, kColonialPhaseTribe1],
        reason: 'Owner list also sorted ascending across the dedup set.',
      );
    });
  });
}
