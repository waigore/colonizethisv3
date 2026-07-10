// Consolidated WorkSuggestionPipeline runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'package:colonizethis_test/test.dart';

import 'support/scenario_runner.dart';
import 'support/suggestion/work_suggestion_pipeline_scenarios.dart';

void main() {
  suppressLogsForTests();
  runLabeledScenarioGroup(
    'WorkSuggestionPipeline',
    workSuggestionPipelineScenarios(),
    runRunnableScenario,
  );
}
