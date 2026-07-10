// Consolidated validator-bundle runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.


import 'support/scenario_runner.dart';
import 'support/validators/validator_bundle_scenarios.dart';

void main() {
  runLabeledScenarios(validatorBundleScenarios(), runRunnableScenario);
}
