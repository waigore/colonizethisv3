// Consolidated applyBuildAndWorkOrders work-order application runners (Refs #3949 wave 3).
//
// Merges former orders_application_work_order_application_part*_test.dart into one
// ≤400-line family runner with scenarios in support/.

import 'package:colonizethis_test/test.dart';

import 'support/application/work_order_application_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  group('applyBuildAndWorkOrders work order application', () {
    runLabeledScenarios(
      workOrderApplicationScenarios(),
      runWorkOrderApplicationScenario,
    );
  });
}
