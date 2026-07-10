// Consolidated faction-membership diplomatic sub-validator runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.
// Refs #2394 — O(1) classification on per-candidate probe paths.

import '../../support/scenario_runner.dart';
import '../../support/validators/diplomatic/diplomatic_sub_validators_faction_membership_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'allianceSubValidator factionMembership',
    allianceSubValidatorFactionMembershipScenarios(),
    runDiplomaticSubValidatorsFactionMembershipScenario,
  );
  runLabeledScenarioGroup(
    'establishOvertureSubValidator factionMembership',
    establishOvertureSubValidatorFactionMembershipScenarios(),
    runDiplomaticSubValidatorsFactionMembershipScenario,
  );
  runLabeledScenarioGroup(
    'DiplomaticOrderValidator factionMembership',
    diplomaticOrderValidatorFactionMembershipScenarios(),
    runDiplomaticSubValidatorsFactionMembershipScenario,
  );
}
