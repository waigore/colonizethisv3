// Table-driven isCapitalSiege scenarios (Refs #3865).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_test/test.dart';

import 'combat_mode_selection_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> isCapitalSiegeScenarios() => [
  RunnableScenario(
    scenarioId: 'cms-not-siege-no-fort',
    label: 'returns false when not a siege (no fort)',
    run: () {
      final game = capitalSiegeFixtureGame();
      final ctx = capitalSiegeBattleContext(
        provinceId: 'capital',
        fortLevel: 0,
      );
      expect(isCapitalSiege(game, ctx), isFalse);
    },
  ),
  RunnableScenario(
    scenarioId: 'cms-siege-not-capital',
    label: 'returns false when siege but province is not a capital',
    run: () {
      final game = capitalSiegeFixtureGame();
      final ctx = capitalSiegeBattleContext(provinceId: 'other', fortLevel: 1);
      expect(isCapitalSiege(game, ctx), isFalse);
    },
  ),
  RunnableScenario(
    scenarioId: 'cms-siege-gp-capital',
    label: 'returns true when siege of GP capital',
    run: () {
      final game = capitalSiegeFixtureGame();
      final ctx = capitalSiegeBattleContext(
        provinceId: 'capital',
        fortLevel: 1,
      );
      expect(isCapitalSiege(game, ctx), isTrue);
    },
  ),
];
