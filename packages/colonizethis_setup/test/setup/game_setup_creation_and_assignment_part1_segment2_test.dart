// Ported from colonizethis_logic (Refs #4090 Slice C).
import 'package:colonizethis_test/test.dart';

import 'support/game_setup_creation_and_assignment_part1_segment2_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  group('GameSetup', () {
    runLabeledScenarios(
      gameSetupCreationAndAssignmentPart1Segment2Scenarios(),
      runRunnableScenario,
    );
  });
}
