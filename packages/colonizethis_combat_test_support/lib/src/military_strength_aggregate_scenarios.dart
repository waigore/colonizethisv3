// Table-driven military-strength scenarios (Refs #3865, #4196 slice B).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'military_strength_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> aggregateStrengthScenarios() => [
  RunnableScenario(
    scenarioId: 'as-list-units',
    label: 'aggregates strength for a list of units',
    run: () {
      final units = [
        testUnit(id: 'u1', type: 'musketeers', locationProvinceId: 'p1'),
        testUnit(id: 'u2', type: 'grenadiers', locationProvinceId: 'p2'),
      ];

      final strength = aggregateStrength(units, 4);
      expect(strength, equals(27.0));
    },
  ),
  RunnableScenario(
    scenarioId: 'as-era-downgrade',
    label: 'downgrades units when era exceeds effective era',
    run: () {
      final units = [
        testUnit(id: 'u1', type: 'grenadiers', locationProvinceId: 'p1'),
      ];

      final strength = aggregateStrength(units, 1);
      expect(strength, greaterThan(0.0));
    },
  ),
];
