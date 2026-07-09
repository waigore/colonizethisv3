// Table-driven validateJoinEmpireOverture scenarios (Refs #3949 wave 3).

import '../../scenario_runner.dart';
import 'join_empire_overture_validator_expectations.dart';

class JoinEmpireOvertureValidatorScenario implements LabeledScenario {
  const JoinEmpireOvertureValidatorScenario({
    required this.label,
    required this.target,
  });

  @override
  final String label;
  final JoinEmpireOvertureValidatorTarget target;
}

void runJoinEmpireOvertureValidatorScenario(
  JoinEmpireOvertureValidatorScenario scenario,
) {
  runJoinEmpireOvertureValidatorExpectation(scenario.target);
}

List<JoinEmpireOvertureValidatorScenario> joinEmpireOvertureValidatorScenarios() =>
    const [
      JoinEmpireOvertureValidatorScenario(
        label: 'rejects when current stage is not NAP and preserves treasury (negative)',
        target: JoinEmpireOvertureValidatorTarget.rejectsWhenNotNap,
      ),
      JoinEmpireOvertureValidatorScenario(
        label: 'rejects when score below friendly threshold and preserves treasury (negative)',
        target: JoinEmpireOvertureValidatorTarget.rejectsWhenScoreBelowFriendly,
      ),
      JoinEmpireOvertureValidatorScenario(
        label: 'accepts minor target with funds at or above scaled cost and preserves treasury (positive)',
        target: JoinEmpireOvertureValidatorTarget.acceptsMinorWithFunds,
      ),
      JoinEmpireOvertureValidatorScenario(
        label: 'rejects join empire toward GP without Empire Building tech (negative)',
        target: JoinEmpireOvertureValidatorTarget.rejectsGpWithoutEmpireBuilding,
      ),
    ];
