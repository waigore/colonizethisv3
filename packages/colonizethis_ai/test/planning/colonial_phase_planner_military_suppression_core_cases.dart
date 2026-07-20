// Topic-split case module (Refs #3997 Phase 8).
// Registered from the thin contract / barrel for this family.
// Pin/row coverage is preserved 1:1 from the former combined cases file.

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/colonial_phase_planner_test_support.dart';

void registerColonialPhasePlannerMilitarySuppressionCoreCases() {
  group('planColonialMilitary', () {
    test('AC: no declared target, at-war tribe owns NW invadable -> '
        'restrict to those provinces + sorted at-war owners', () {
      // Priority 2 fires when no declared target is given and at
      // least one at-war faction owns an NW invadable province. The
      // plan restricts to the union of those provinces and lists the
      // at-war owners sorted ascending. Tribes are first-class
      // colonial targets per issue #2509 § planColonialAcquisition.
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
        planColonialMilitary(game: game, snapshot: snapshot),
        const ColonialMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
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
        planColonialMilitary(game: game, snapshot: snapshot),
        ColonialMilitaryPlan(
          priorityDestinationProvinceIdsSorted: List<String>.unmodifiable(
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

    test('at-war owner with no NW invadable contribution is dropped from owner '
        'list', () {
      // An at-war faction that does NOT own any NW invadable province
      // must NOT appear in priorityTargetOwnerFactionIdsSorted. This
      // pins the "owner list mirrors actual destinations" contract so
      // a downstream orchestrator never sees a phantom target.
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
        // tribe2 is at war but owns nothing in NW invadable, so should
        // be dropped from the owner list.
        atWarWith: const [kColonialPhaseTribe1, kColonialPhaseTribe2],
        invadableNw: const ['newWorld|tribe1_a'],
      );
      expect(
        planColonialMilitary(game: game, snapshot: snapshot),
        const ColonialMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
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
        // tribe2 is at war but does NOT own the invadable province.
        atWarWith: const [kColonialPhaseTribe2],
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
        final game = buildColonialPhaseGame(
          newWorldProvinces: const [
            Province(
              id: 'newWorld|tribe1_a',
              regionId: 'newWorld',
              ownerId: kColonialPhaseTribe1,
            ),
            Province(
              id: 'newWorld|tribe2_a',
              regionId: 'newWorld',
              ownerId: kColonialPhaseTribe2,
            ),
          ],
          tribes: const [
            Tribe(id: kColonialPhaseTribe1, displayName: 'T1'),
            Tribe(id: kColonialPhaseTribe2, displayName: 'T2'),
          ],
        );
        final snapshot = buildColonialPhaseSnapshot(
          atWarWith: const [kColonialPhaseTribe1, kColonialPhaseTribe2],
          invadableNw: const ['newWorld|tribe1_a', 'newWorld|tribe2_a'],
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
      final game = buildColonialPhaseGame(
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|minor1_a',
            regionId: 'oldWorld',
            ownerId: kColonialPhaseMinor1,
          ),
        ],
        newWorldProvinces: const [
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
          priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
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
      final game = buildColonialPhaseGame(
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|minor1_a',
            regionId: 'oldWorld',
            ownerId: kColonialPhaseMinor1,
          ),
        ],
        minorNations: const [MinorNation(id: kColonialPhaseMinor1, displayName: 'M1')],
      );
      final snapshot = buildColonialPhaseSnapshot(
        atWarWith: const [kColonialPhaseMinor1],
        invadableNw: const [],
        invadableOw: const ['oldWorld|minor1_a'],
      );
      expect(
        planColonialMilitary(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: kColonialPhaseMinor1,
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
        planColonialMilitary(game: game, snapshot: snapshot),
        const ColonialMilitaryPlan(
          priorityDestinationProvinceIdsSorted: <String>['newWorld|tribe1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
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
      final first = planColonialMilitary(
        game: game,
        snapshot: snapshot,
        colonialDeclaredWarTargetFactionId: kColonialPhaseTribe1,
      );
      final second = planColonialMilitary(
        game: game,
        snapshot: snapshot,
        colonialDeclaredWarTargetFactionId: kColonialPhaseTribe1,
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
      final game = buildColonialPhaseGame(
        newWorldProvinces: const [
          // gp3 owns this — at war but should be ignored because not
          // the declared target.
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
            'Priority 1 restricts ONLY to the declared target. gp3 '
            'is also at war and also owns an NW invadable province '
            'but is correctly excluded because the planner is keyed '
            'on owner == colonialDeclaredWarTargetFactionId.',
      );
    });

  });
}
