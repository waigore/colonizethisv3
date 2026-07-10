// Consolidated OrderEngine validator-injection runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.


import 'support/engine/order_engine_validator_injection_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  runLabeledScenarios(
    orderEngineValidatorInjectionScenarios(),
    runRunnableScenario,
  );
}
