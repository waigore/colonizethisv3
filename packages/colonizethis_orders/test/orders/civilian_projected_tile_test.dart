// Consolidated civilian projected-tile runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/scenario_runner.dart';
import 'support/application/civilian_projected_tile_scenarios.dart';
import 'support/application/civilian_projected_tile_move_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'projectedCivilianTileKey',
    [
      ...civilianProjectedTileScenarios(),
      rs(
        'prefers pending move destination over work and tile',
        cptmRunPrefersPendingMoveDestination,
      ),
    ],
    runRunnableScenario,
  );
}
