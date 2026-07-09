// Consolidated relation-based diplomatic sub-validator runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.
// Refs #2391 AC10, #3811 AC10. SPEC/program/orders.md § Diplomatic orders.

import '../../support/scenario_runner.dart';
import '../../support/validators/diplomatic/diplomatic_sub_validators_relations_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'declareWarSubValidator',
    declareWarSubValidatorScenarios(),
    runDiplomaticSubValidatorsRelationsScenario,
  );
  runLabeledScenarioGroup(
    'offerPeaceSubValidator',
    offerPeaceSubValidatorScenarios(),
    runDiplomaticSubValidatorsRelationsScenario,
  );
  runLabeledScenarioGroup(
    'allianceSubValidator',
    allianceSubValidatorScenarios(),
    runDiplomaticSubValidatorsRelationsScenario,
  );
  runLabeledScenarioGroup(
    'post-break bilateral cooldown (Refs #3811 AC10)',
    postBreakBilateralCooldownScenarios(),
    runDiplomaticSubValidatorsRelationsScenario,
  );
}
