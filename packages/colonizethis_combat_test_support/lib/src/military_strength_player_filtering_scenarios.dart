// Table-driven military-strength scenarios (Refs #3865, #4196 slice B).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'military_strength_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> militaryStrengthPlayerFilteringScenarios() => [
  RunnableScenario(
    scenarioId: 'ms-unknown-regiment',
    label: 'skips units with unknown regiment types',
    run: () {
      final game = militaryStrengthGame(
        oldWorldUnits: [
          testUnit(id: 'u1', type: 'unknown_unit_type'),
          testUnit(id: 'u2', type: 'musketeers'),
        ],
        players: const [franceGreatPower],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'france');
      expect(strength, equals(9.0));
    },
  ),
  RunnableScenario(
    scenarioId: 'ms-ow-nw',
    label: 'aggregates units from both Old World and New World',
    run: () {
      final game = militaryStrengthGame(
        oldWorldUnits: [testUnit(id: 'u1', type: 'musketeers')],
        newWorldUnits: [
          testUnit(
            id: 'u2',
            type: 'musketeers',
            locationProvinceId: 'new_york',
          ),
        ],
        players: const [franceGreatPower],
      );

      final strength = aggregateMilitaryStrengthForPlayer(game, 'france');
      expect(strength, equals(18.0));
    },
  ),
  RunnableScenario(
    scenarioId: 'ms-owner-filter',
    label: 'only includes units owned by the specified player',
    run: () {
      final game = militaryStrengthGame(
        oldWorldUnits: [
          testUnit(id: 'u1', type: 'musketeers'),
          testUnit(
            id: 'u2',
            type: 'musketeers',
            ownerId: 'prussia',
            locationProvinceId: 'berlin',
          ),
        ],
        players: const [
          franceGreatPower,
          Player(id: 'prussia', displayName: 'Prussia', isHuman: false),
        ],
      );

      final franceStrength = aggregateMilitaryStrengthForPlayer(game, 'france');
      expect(franceStrength, equals(9.0));

      final prussiaStrength = aggregateMilitaryStrengthForPlayer(
        game,
        'prussia',
      );
      expect(prussiaStrength, equals(9.0));
    },
  ),
];
