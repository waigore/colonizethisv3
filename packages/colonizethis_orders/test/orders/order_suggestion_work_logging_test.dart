// Consolidated suggestWorkOrders logging runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'package:colonizethis_test/test.dart';

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_work_logging_scenarios.dart';

void main() {
  suppressLogsForTests();
  runLabeledScenarioGroup(
    'suggestWorkOrders structured logging',
    orderSuggestionWorkLoggingScenarios(),
    runRunnableScenario,
  );
}
