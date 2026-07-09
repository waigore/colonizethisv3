// Consolidated validateJoinEmpireOverture runner (Refs #3949 wave 3 slice 96).
//
// Direct unit tests for `validateJoinEmpireOverture` (Refs #2560).
// SPEC/program/orders.md § Diplomatic orders / overtures.

import '../../support/scenario_runner.dart';
import '../../support/validators/diplomatic/join_empire_overture_validator_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'validateJoinEmpireOverture (free function)',
    joinEmpireOvertureValidatorScenarios(),
    runJoinEmpireOvertureValidatorScenario,
  );
}
