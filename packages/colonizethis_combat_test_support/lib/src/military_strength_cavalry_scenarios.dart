// Table-driven military-strength scenarios (Refs #3865, #4196 slice B).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'military_strength_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> cavalryFractionScenarios() => [
  RunnableScenario(
    scenarioId: 'cf-empty',
    label: 'returns 0 when unit list is empty',
    run: () {
      expect(cavalryFraction([], {}), equals(0.0));
    },
  ),
  RunnableScenario(
    scenarioId: 'cf-share',
    label: 'counts cavalry share over all unit ids',
    run: () {
      final unitsById = {
        'u1': testUnit(id: 'u1', type: 'squires', locationProvinceId: 'p1'),
        'u2': testUnit(id: 'u2', type: 'musketeers', locationProvinceId: 'p2'),
      };

      expect(cavalryFraction(['u1', 'u2'], unitsById), equals(0.5));
    },
  ),
  RunnableScenario(
    scenarioId: 'cf-missing-denominator',
    label: 'missing units still count toward denominator',
    run: () {
      final unitsById = {
        'u1': testUnit(id: 'u1', type: 'squires', locationProvinceId: 'p1'),
      };

      expect(cavalryFraction(['u1', 'missing'], unitsById), equals(0.5));
    },
  ),
];
