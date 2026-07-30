// Table-driven military-strength scenarios (Refs #3865, #4196 slice B).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'military_strength_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> militaryStrengthPlayerFactionScenarios() => [
  RunnableScenario(
    scenarioId: 'ms-empty-army',
    label: 'returns 0 for empty army',
    run: () {
      final game = militaryStrengthGame(
        players: const [franceGreatPower],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'france');
      expect(strength, equals(0.0));
    },
  ),
  RunnableScenario(
    scenarioId: 'ms-gp-medals',
    label: 'calculates strength for Great Power units with medals',
    run: () {
      final game = militaryStrengthGame(
        oldWorldUnits: [
          testUnit(id: 'u1', type: 'grenadiers', medals: 2),
          testUnit(id: 'u2', type: 'musketeers'),
        ],
        players: const [franceGreatPower],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'france');
      expect(strength, closeTo(30.6, 0.1));
    },
  ),
  RunnableScenario(
    scenarioId: 'ms-minor-era',
    label: 'uses effective military level for Minor Nation',
    run: () {
      final game = militaryStrengthGame(
        oldWorldUnits: [
          testUnit(
            id: 'u1',
            type: 'peasant_levies',
            ownerId: 'minor1',
            locationProvinceId: 'p1',
          ),
        ],
        minorNations: const [
          MinorNation(
            id: 'minor1',
            displayName: 'Minor Nation',
            effectiveMilitaryLevel: 1,
          ),
        ],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'minor1');
      expect(strength, equals(3.0));
    },
  ),
  RunnableScenario(
    scenarioId: 'ms-tribe-era',
    label: 'uses effective military level for Tribe',
    run: () {
      final game = militaryStrengthGame(
        oldWorldUnits: [
          testUnit(
            id: 'u1',
            type: 'cossacks',
            ownerId: 'tribe1',
            locationProvinceId: 'p1',
          ),
        ],
        tribes: const [
          Tribe(
            id: 'tribe1',
            displayName: 'Tribe',
            effectiveMilitaryLevel: 1,
          ),
        ],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'tribe1');
      expect(strength, greaterThan(0.0));
    },
  ),
  RunnableScenario(
    scenarioId: 'ms-gp-era4',
    label: 'Great Power uses era 4 (does not downgrade era 3 units)',
    run: () {
      final game = militaryStrengthGame(
        oldWorldUnits: [
          testUnit(id: 'u1', type: 'grenadiers'),
        ],
        players: const [franceGreatPower],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'france');
      expect(strength, equals(18.0));
    },
  ),
];
