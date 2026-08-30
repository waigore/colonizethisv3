// Priority-1 declared-colonial-target pins for `planColonialMilitary` (Refs #2509 S3).

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/colonial_phase_planner_test_support.dart';

void registerColonialPhasePlannerMilitaryPriorityDeclaredTargetCases() {
  group('planColonialMilitary', () {
    test('AC: declared colonial target owns one NW invadable -> restrict to '
        'that province + target as sole owner', () {
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
      );
    });

    test('declared colonial target owns multiple NW invadable -> all those '
        'provinces, sorted ascending', () {
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
      );
    });

    test('declared colonial target owns no NW invadable -> defaultPlan', () {
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
      );
    });
  });
}
