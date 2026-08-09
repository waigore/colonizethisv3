// Table-driven military-strength scenarios (Refs #3865, #4196 slice B).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'military_strength_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> effectiveEraForFactionScenarios() => [
  RunnableScenario(
    scenarioId: 'eef-gp',
    label: 'returns 4 for Great Power',
    run: () {
      final game = militaryStrengthGame(
        players: const [franceGreatPower],
      );

      expect(effectiveEraForFaction(game, 'france'), equals(4));
    },
  ),
  RunnableScenario(
    scenarioId: 'eef-minor',
    label: 'returns effectiveMilitaryLevel for Minor Nation',
    run: () {
      final game = militaryStrengthGame(
        minorNations: const [
          MinorNation(
            id: 'minor1',
            displayName: 'Minor',
            effectiveMilitaryLevel: 2,
          ),
        ],
      );

      expect(effectiveEraForFaction(game, 'minor1'), equals(2));
    },
  ),
  RunnableScenario(
    scenarioId: 'eef-tribe',
    label: 'returns effectiveMilitaryLevel for Tribe (capped at 1 in-game)',
    run: () {
      final game = militaryStrengthGame(
        tribes: const [
          Tribe(
            id: 'tribe1',
            displayName: 'Tribe',
            effectiveMilitaryLevel: 1,
          ),
        ],
      );

      expect(effectiveEraForFaction(game, 'tribe1'), equals(1));
    },
  ),
  RunnableScenario(
    scenarioId: 'eef-unknown',
    label: 'returns 4 for unknown faction',
    run: () {
      final game = militaryStrengthGame();

      expect(effectiveEraForFaction(game, 'unknown'), equals(4));
    },
  ),
];
