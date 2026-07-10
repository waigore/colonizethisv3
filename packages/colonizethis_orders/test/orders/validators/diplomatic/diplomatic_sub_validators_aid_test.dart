// Consolidated grantAid / setSubsidy sub-validator runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.
// Refs #2391 AC10, #3753 R2/R3. SPEC/program/orders.md § Diplomatic orders / aid.

import '../../support/scenario_runner.dart';
import '../../support/validators/diplomatic/diplomatic_sub_validators_aid_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'grantAidSubValidator',
    grantAidSubValidatorScenarios(),
    runRunnableScenario,
  );
  runLabeledScenarioGroup(
    'setSubsidySubValidator (percent model, Refs #3753 R3)',
    setSubsidySubValidatorScenarios(),
    runRunnableScenario,
  );
}
