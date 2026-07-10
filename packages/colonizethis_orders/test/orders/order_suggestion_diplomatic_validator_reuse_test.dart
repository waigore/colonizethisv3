import 'package:colonizethis_test/test.dart';

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_diplomatic_validator_reuse_scenarios.dart';

void main() {
  suppressLogsForTests();

  runLabeledScenarioGroup(
    'suggestDiplomaticOrders validator reuse (Refs #2394)',
    orderSuggestionDiplomaticValidatorReuseScenarios(),
    runRunnableScenario,
  );
}
