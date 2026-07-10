// Consolidated per-player work target selection cache runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'package:colonizethis_test/test.dart';

import 'support/per_player_work_target_selection_cache_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  suppressLogsForTests();

  runLabeledScenarioGroup(
    'PerPlayerWorkTargetSelectionCache',
    perPlayerWorkTargetSelectionCacheScenarios(),
    runPerPlayerWorkTargetSelectionCacheScenario,
  );
}
