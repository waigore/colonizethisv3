import 'package:colonizethis_test/test.dart';

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_naval_validator_reuse_scenarios.dart';

void main() {
  suppressLogsForTests();

  runLabeledScenarioGroup(
    'naval suggestion sharedCandidateValidator (Refs #2394)',
    orderSuggestionNavalValidatorReuseScenarios(),
    runRunnableScenario,
  );
}
