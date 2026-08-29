// Declared-target priority pins for `planColonialNaval` (Refs #2509 S3).

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/colonial_phase_planner_test_support.dart';

void registerColonialPhasePlannerNavalPriorityCasesPartB() {
  group('planColonialNaval', () {
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
        planColonialNaval(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: kColonialPhaseTribe1,
        ),
        const ColonialNavalPlan(
          priorityInvasionTransportProvinceIdsSorted: <String>[
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
        planColonialNaval(
          game: game,
          snapshot: snapshot,
          colonialDeclaredWarTargetFactionId: kColonialPhaseTribe2,
        ),
        same(ColonialNavalPlan.defaultPlan),
      );
    });
  });
}
