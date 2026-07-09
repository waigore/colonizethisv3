// Consolidated orders_application helpers / clearUnit / mineral eligibility
// runners (Refs #3949 wave 3).
//
// Merges former helpers, helpers_mineral_eligible, and clear_unit_current_work
// suites into one ≤400-line family runner with scenarios in support/.

import 'package:colonizethis_test/test.dart';

import 'support/application/application_helpers_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  group('orders_application helpers', () {
    runLabeledScenarios(
      applicationHelpersScenarios(),
      runApplicationHelpersScenario,
    );
  });
}
