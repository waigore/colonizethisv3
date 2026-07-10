// Consolidated boycott / revokeBoycott validator runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.
// Refs #3753 R6. SPEC/program/orders.md § Diplomatic orders;
// SPEC/game/diplomacy.md § GP–Tribe Rules (Boycott).

import '../../support/scenario_runner.dart';
import '../../support/validators/diplomatic/boycott_validator_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'boycottSubValidator',
    boycottSubValidatorScenarios(),
    runBoycottValidatorScenario,
  );
  runLabeledScenarioGroup(
    'revokeBoycottSubValidator',
    revokeBoycottSubValidatorScenarios(),
    runBoycottValidatorScenario,
  );
  runLabeledScenarioGroup(
    'DiplomaticOrderValidator boycott dispatch',
    diplomaticOrderValidatorBoycottScenarios(),
    runBoycottValidatorScenario,
  );
}
