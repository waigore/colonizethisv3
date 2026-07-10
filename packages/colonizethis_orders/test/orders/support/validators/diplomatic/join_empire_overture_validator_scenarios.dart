// Table-driven validateJoinEmpireOverture scenarios (Refs #3949 wave 3).

import '../../scenario_runner.dart';
import 'join_empire_overture_validator_run_rows.dart';

class JoinEmpireOvertureValidatorScenario implements LabeledScenario {
  const JoinEmpireOvertureValidatorScenario({
    required this.label,
    required this.run,
  });

  @override
  final String label;
  final void Function() run;
}

void runJoinEmpireOvertureValidatorScenario(
  JoinEmpireOvertureValidatorScenario scenario,
) =>
    scenario.run();

List<JoinEmpireOvertureValidatorScenario> joinEmpireOvertureValidatorScenarios() =>
    const [
      JoinEmpireOvertureValidatorScenario(
        label: 'rejects when current stage is not NAP and preserves treasury (negative)',
        run: jeeRunRejectsWhenNotNap,
      ),
      JoinEmpireOvertureValidatorScenario(
        label: 'rejects when score below friendly threshold and preserves treasury (negative)',
        run: jeeRunRejectsWhenScoreBelowFriendly,
      ),
      JoinEmpireOvertureValidatorScenario(
        label: 'accepts minor target with funds at or above scaled cost and preserves treasury (positive)',
        run: jeeRunAcceptsMinorWithFunds,
      ),
      JoinEmpireOvertureValidatorScenario(
        label: 'rejects join empire toward GP without Empire Building tech (negative)',
        run: jeeRunRejectsGpWithoutEmpireBuilding,
      ),
    ];
