// Table-driven military-strength scenarios (Refs #3865, #4196 slice B).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'military_strength_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> militaryStrengthPlayerMultiplierScenarios() => [
  RunnableScenario(
    scenarioId: 'ms-medal-multipliers',
    label: 'applies medal multiplier correctly (0-4 medals)',
    run: () {
      final game = militaryStrengthGame(
        oldWorldUnits: [
          testUnit(id: 'u0', type: 'musketeers', locationProvinceId: 'p0'),
          testUnit(
            id: 'u1',
            type: 'musketeers',
            locationProvinceId: 'p1',
            medals: 1,
          ),
          testUnit(
            id: 'u2',
            type: 'musketeers',
            locationProvinceId: 'p2',
            medals: 2,
          ),
          testUnit(
            id: 'u3',
            type: 'musketeers',
            locationProvinceId: 'p3',
            medals: 3,
          ),
          testUnit(
            id: 'u4',
            type: 'musketeers',
            locationProvinceId: 'p4',
            medals: 4,
          ),
          testUnit(
            id: 'u5',
            type: 'musketeers',
            locationProvinceId: 'p5',
            medals: 10,
          ),
        ],
        players: const [franceGreatPower],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'france');
      expect(strength, closeTo(66.6, 0.1));
    },
  ),
  RunnableScenario(
    scenarioId: 'ms-deterministic',
    label: 'is deterministic - same inputs produce same output',
    run: () {
      final game = militaryStrengthGame(
        oldWorldUnits: [testUnit(id: 'u1', type: 'grenadiers', medals: 3)],
        players: const [franceGreatPower],
      );

      final strength1 = aggregateMilitaryStrengthForPlayer(game, 'france');
      final strength2 = aggregateMilitaryStrengthForPlayer(game, 'france');
      final strength3 = aggregateMilitaryStrengthForPlayer(game, 'france');

      expect(strength1, equals(strength2));
      expect(strength2, equals(strength3));
    },
  ),
  RunnableScenario(
    scenarioId: 'ms-non-negative',
    label: 'returns non-negative value',
    run: () {
      final game = militaryStrengthGame(players: const [franceGreatPower]);

      final strength = aggregateMilitaryStrengthForPlayer(game, 'france');
      expect(strength, greaterThanOrEqualTo(0.0));
    },
  ),
];
