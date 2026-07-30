// Naval battle resolution scenarios (Refs #4196 slice C).

import 'package:colonizethis_combat/colonizethis_combat.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'naval_combat_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> navalInterceptProbabilityScenarios() => [
  RunnableScenario(
    scenarioId: 'nip-patrol',
    label: 'Patrol uses mission-factor * ratio',
    run: () {
      expect(
        navalInterceptProbability(
          interceptorScore: 5,
          targetFleeScore: 5,
          isBlockade: false,
        ),
        0.25,
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'nip-blockade',
    label: 'Blockade uses mission-factor * ratio',
    run: () {
      expect(
        navalInterceptProbability(
          interceptorScore: 8,
          targetFleeScore: 2,
          isBlockade: true,
        ),
        closeTo(0.72, 1e-9),
      );
    },
  ),
  RunnableScenario(
    scenarioId: 'nip-clamped',
    label: 'result is clamped 0.05-0.85',
    run: () {
      expect(
        navalInterceptProbability(
          interceptorScore: 0,
          targetFleeScore: 100,
          isBlockade: false,
        ),
        greaterThanOrEqualTo(0.05),
      );
      expect(
        navalInterceptProbability(
          interceptorScore: 100,
          targetFleeScore: 0,
          isBlockade: true,
        ),
        lessThanOrEqualTo(0.85),
      );
    },
  ),
];
