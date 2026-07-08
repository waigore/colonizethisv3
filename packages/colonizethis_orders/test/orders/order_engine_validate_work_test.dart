// Consolidated OrderEngine validateWork runners (Refs #3949 wave 3).
//
// Merges former order_engine_validate_work_*_test.dart into one
// ≤400-line family runner with scenarios in support/.

import 'package:colonizethis_test/test.dart';

import 'support/engine/order_engine_validate_work_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  group('OrderEngine validateWork', () {
    runLabeledScenarios(
      orderEngineValidateWorkScenarios(),
      runOrderEngineValidateWorkScenario,
    );
  });
}
