// Consolidated breakAlliance validator runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.
// Refs #3753 R11. SPEC/program/orders.md § Diplomatic orders / break alliance.

import '../../support/scenario_runner.dart';
import '../../support/validators/diplomatic/break_alliance_validator_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'breakAllianceSubValidator',
    breakAllianceSubValidatorScenarios(),
    runRunnableScenario,
  );
  runLabeledScenarioGroup(
    'DiplomaticOrderValidator breakAlliance dispatch',
    diplomaticOrderValidatorBreakAllianceScenarios(),
    runRunnableScenario,
  );
}
