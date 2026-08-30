// Naval resolver scenarios (Refs #4196 slice C).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'naval_combat_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> navalStrengthScenarios() => [
  RunnableScenario(
    scenarioId: 'ns-empty',
    label: 'returns 0 for empty list',
    run: () {
      expect(navalStrength([]), 0.0);
    },
  ),
  RunnableScenario(
    scenarioId: 'ns-weighted-formula',
    label: 'uses configured weighted formula including durability',
    run: () {
      final carrack = NavalStatsCatalog.get('carrack');
      final expected =
          carrack.firepower +
          (carrack.range * 0.4) +
          (carrack.armour * 0.15) +
          (carrack.hull * (1 + carrack.armour / 10.0)) +
          (carrack.movement * 0.1);
      expect(navalStrength(['carrack']), closeTo(expected, 1e-9));
    },
  ),
];
