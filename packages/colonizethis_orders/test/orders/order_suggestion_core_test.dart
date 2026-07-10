// Consolidated order_suggestion_core runners (Refs #3949 wave 3).
//
// Merges former order_suggestion_core_part*_test.dart into one
// ≤400-line family runner with scenarios in support/.

import 'package:colonizethis_test/test.dart';

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_core_scenarios.dart';

void main() {
  group('Order suggestion', () {
    runLabeledScenarios(orderSuggestionCoreScenarios(), runRunnableScenario);
  });
}
