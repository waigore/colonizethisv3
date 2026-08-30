// Guard + structural pins for `planColonialMilitary` priority filter (Refs #2509 S3).

import 'package:colonizethis_ai/src/planning/colonial_phase_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../support/colonial_phase_planner_test_support.dart';

void registerColonialPhasePlannerMilitaryPriorityGuardCases() {
  group('planColonialMilitary', () {
    test('below quota (own OW = 9) -> defaultPlan', () {
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
        oldWorldProvincesOwned: 9,
      );
      expect(
        planColonialMilitary(game: game, snapshot: snapshot),
        same(ColonialMilitaryPlan.defaultPlan),
      );
    });

    test('player not in game -> defaultPlan (defensive guard)', () {
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
        playerId: 'ghost-player',
      );
      expect(
        planColonialMilitary(game: game, snapshot: snapshot),
        ColonialMilitaryPlan.defaultPlan,
      );
    });

    test('empty NW invadable -> defaultPlan', () {
      final game = buildColonialPhaseGame();
      final snapshot = buildColonialPhaseSnapshot(
        atWarWith: const [kColonialPhaseTribe1],
        invadableNw: const [],
      );
      expect(
        planColonialMilitary(game: game, snapshot: snapshot),
        same(ColonialMilitaryPlan.defaultPlan),
      );
    });
  });
}
