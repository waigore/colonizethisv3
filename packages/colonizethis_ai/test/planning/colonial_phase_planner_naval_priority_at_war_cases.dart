// At-war fallback pins for `planColonialNaval` priority filter (Refs #2509 S3).

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/colonial_phase_planner_test_support.dart';

void registerColonialPhasePlannerNavalPriorityAtWarCases() {
  group('planColonialNaval', () {
    test('AC: no declared target, at-war tribe owns NW invadable -> '
        'restrict to those provinces + sorted at-war owners', () {
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
        planColonialNaval(game: game, snapshot: snapshot),
        const ColonialNavalPlan(
          priorityInvasionTransportProvinceIdsSorted: <String>[
            'newWorld|tribe1_a',
          ],
          priorityTargetOwnerFactionIdsSorted: <String>[kColonialPhaseTribe1],
        ),
      );
    });

    test('no declared target, multiple at-war owners (tribe + minor) -> '
        'union of their invadable + sorted owners', () {
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
        planColonialNaval(game: game, snapshot: snapshot),
        ColonialNavalPlan(
          priorityInvasionTransportProvinceIdsSorted: List<String>.unmodifiable(
            const <String>['newWorld|minor1_a', 'newWorld|tribe1_a'],
          ),
          priorityTargetOwnerFactionIdsSorted: List<String>.unmodifiable(
            const <String>[kColonialPhaseMinor1, kColonialPhaseTribe1],
          ),
        ),
      );
    });
  });
}
