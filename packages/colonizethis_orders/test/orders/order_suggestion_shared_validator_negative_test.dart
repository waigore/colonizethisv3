import 'package:colonizethis_test/test.dart';

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_shared_validator_negative_scenarios.dart';

void main() {
  suppressLogsForTests();

  runLabeledScenarioGroup(
    'shared validator playerId mismatch is rejected',
    orderSuggestionSharedValidatorNegativeMismatchScenarios(),
    runRunnableScenario,
  );

  runLabeledScenarioGroup(
    'generateOrdersWithSimpleHeuristics still produces the same orders',
    orderSuggestionSharedValidatorNegativeSmokeScenarios(),
    runRunnableScenario,
  );
}
