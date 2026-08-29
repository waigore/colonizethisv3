// Case bodies for `colonial_phase_planner_colonial_lite_naval_test.dart`
// (Refs #3997 Phase 8). Registered from the thin contract; pin coverage
// preserved 1:1 from the former inline suite.

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../support/colonial_phase_planner_test_support.dart';


void registerColonialPhasePlannerColonialLiteNavalSuppressionCases() {
    test('OW invadable structurally suppressed', () {
      // Even with an at-war tribe owning an OW invadable province in
      // the conquest summary and an empty NW invadable list in the
      // colonial summary, the plan must NOT pick up the OW province
      // -- the planner only reads
      // `colonial.invadableNewWorldProvinceIdsSorted`. This pins the
      // structural OW suppression from the spec ("Naval exploration of
      // unrevealed NW sea zones ...").
      final game = buildColonialLiteNavalGame(
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|tribe1_a',
            regionId: 'oldWorld',
            ownerId: kColonialPhaseTribe1,
          ),
        ],
        tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
      );
      final snapshot = buildColonialLiteNavalSnapshot(
        invadableNw: const [],
        invadableOw: const ['oldWorld|tribe1_a'],
        atWarWith: const [kColonialPhaseTribe1],
      );
      expect(
        planColonialLiteNaval(game: game, snapshot: snapshot),
        same(ColonialLiteNavalPlan.defaultPlan),
        reason:
            'OW invadable provinces must never appear in the COLONIAL-lite '
            'naval focus; the planner only reads the NW invadable list '
            'from the colonial summary.',
      );
    });

    test('at-war state is NOT a precondition for inclusion', () {
      // The COLONIAL-lite naval focus targets tribe / minor owners
      // regardless of war state. This is intentionally different from
      // [planColonialMilitary], where the at-war fallback arm gates on
      // `snapshot.threats.atWarWith`. COLONIAL-lite is structural
      // NW-acquisition seed work (exploration + cargo), not
      // retaliation -- the planner must surface tribes / minors even
      // when not yet at war with them.
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
        atWarWith: const [],
      );
      expect(
        planColonialLiteNaval(game: game, snapshot: snapshot),
        const ColonialLiteNavalPlan(
          priorityNwProvinceIdsSorted: <String>['newWorld|tribe1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
        ),
        reason:
            'COLONIAL-lite naval focus surfaces tribe / minor owners '
            'without requiring an at-war predicate (unlike '
            'planColonialMilitary). The COLONIAL-lite contract is '
            'pre-war seed work, not retaliation.',
      );
    });

    test('owner list mirrors province contributions (no phantom owners)', () {
      // A tribe with no NW invadable contribution must NOT appear in
      // `priorityTargetOwnerFactionIdsSorted`. This pins the
      // "owner list mirrors actual destinations" contract so a
      // downstream orchestrator never sees a phantom target.
      final game = buildColonialLiteNavalGame(
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
      final snapshot = buildColonialLiteNavalSnapshot(
        // tribe2's province is NOT in the snapshot invadable list, so
        // tribe2 must NOT surface as a priority owner.
        invadableNw: const ['newWorld|tribe1_a'],
      );
      expect(
        planColonialLiteNaval(game: game, snapshot: snapshot),
        const ColonialLiteNavalPlan(
          priorityNwProvinceIdsSorted: <String>['newWorld|tribe1_a'],
          priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
        ),
        reason:
            'Only tribes / minors that actually contribute an NW invadable '
            'province appear in priorityTargetOwnerFactionIdsSorted. '
            'tribe2 exists in the game roster but contributes nothing so '
            'it is absent from the plan.',
      );
    });

    test(
      'owner list deduplicates across multiple provinces from same tribe',
      () {
        // Two provinces owned by `tribe1` must surface `tribe1` only once
        // in `priorityTargetOwnerFactionIdsSorted`. The set-based owner
        // collection in the planner is responsible for the dedup.
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
            Province(
              id: 'newWorld|tribe1_c',
              regionId: 'newWorld',
              ownerId: kColonialPhaseTribe1,
            ),
          ],
          tribes: const [Tribe(id: kColonialPhaseTribe1, displayName: 'T1')],
        );
        final snapshot = buildColonialLiteNavalSnapshot(
          invadableNw: const [
            'newWorld|tribe1_a',
            'newWorld|tribe1_b',
            'newWorld|tribe1_c',
          ],
        );
        expect(
          planColonialLiteNaval(game: game, snapshot: snapshot),
          const ColonialLiteNavalPlan(
            priorityNwProvinceIdsSorted: <String>[
              'newWorld|tribe1_a',
              'newWorld|tribe1_b',
              'newWorld|tribe1_c',
            ],
            priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
          ),
          reason:
              'Three provinces owned by tribe1 surface tribe1 only once in '
              'priorityTargetOwnerFactionIdsSorted (set-based dedup).',
        );
      },
    );
}
