// Ported from colonizethis_logic (Refs #4090 Slice C).
import 'package:colonizethis_test/test.dart';

import 'support/game_setup_creation_and_assignment_part2_fallback_scenarios.dart';
import 'support/game_setup_creation_and_assignment_part2_town_rank_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  group('GameSetup', () {
    runLabeledScenarios([
      ...gameSetupCreationAndAssignmentPart2TownRankScenarios(),
      ...gameSetupCreationAndAssignmentPart2FallbackScenarios(),
    ], runRunnableScenario);
  });
}
