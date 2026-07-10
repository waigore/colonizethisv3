import 'package:colonizethis_test/test.dart';

import 'support/scenario_runner.dart';
import 'support/suggestion/simple_ai_validator_reuse_scenarios.dart';

void main() {
  suppressLogsForTests();

  runLabeledScenarioGroup(
    'generateOrdersWithSimpleHeuristics validator reuse (Refs #2394)',
    simpleAiValidatorReuseHeuristicScenarios(),
    runRunnableScenario,
  );

  runLabeledScenarioGroup(
    'generateOrdersForGame validator reuse (Refs #2394)',
    simpleAiValidatorReuseBatchScenarios(),
    runRunnableScenario,
  );
}
