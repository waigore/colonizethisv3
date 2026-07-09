// Consolidated orderValidationPhasePlan runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'package:colonizethis_test/test.dart';

import 'support/engine/order_engine_validation_phase_plan_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  group('orderValidationPhasePlan (Refs #3543 AC2)', () {
    runLabeledScenarios(
      orderEngineValidationPhasePlanScenarios(),
      runOrderEngineValidationPhasePlanScenario,
    );
  });
}
