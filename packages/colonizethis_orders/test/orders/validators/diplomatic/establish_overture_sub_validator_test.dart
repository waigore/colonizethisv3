// Consolidated establishOverture sub-validator runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.
// Refs #2391 AC10, #2560. SPEC/program/orders.md § Diplomatic orders / overtures.

import '../../support/scenario_runner.dart';
import '../../support/validators/diplomatic/establish_overture_sub_validator_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'establishOvertureSubValidator',
    establishOvertureSubValidatorScenarios(),
    runRunnableScenario,
  );
}
