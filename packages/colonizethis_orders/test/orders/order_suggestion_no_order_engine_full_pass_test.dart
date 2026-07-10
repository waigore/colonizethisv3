// Consolidated no-OrderEngine-full-pass runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_no_order_engine_full_pass_scenarios.dart';

void main() {
  suppressLogsForTests();
  group('Suggestion enumeration skips OrderEngine full-pass (Refs #2237)', () {
    tearDown(() {
      setOrderEngineValidatePlayerOrdersWithContextTrackingForTests(false);
    });

    runLabeledScenarios(
      orderSuggestionNoOrderEngineFullPassScenarios(),
      runRunnableScenario,
    );
  });
}
