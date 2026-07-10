// Consolidated diplomatic panel action runner (Refs #3949 wave 3).

import 'package:colonizethis_test/test.dart';

import 'support/diplomatic/diplomatic_panel_actions_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  suppressLogsForTests();

  runLabeledScenarioGroup(
    'diplomaticPanelActionCandidates',
    diplomaticPanelActionCandidatesScenarios(),
    runRunnableScenario,
  );

  runLabeledScenarioGroup(
    'enumerateDiplomaticPanelActionsForTarget',
    diplomaticPanelEnumerateScenarios(),
    runRunnableScenario,
  );
}
