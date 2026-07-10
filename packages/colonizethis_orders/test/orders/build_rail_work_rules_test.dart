// Consolidated build_rail work-rules runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/application/build_rail_work_rules_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  runLabeledScenarioGroup(
    'rejectionReasonForBuildRailOrder',
    rejectionReasonForBuildRailOrderScenarios(),
    runRejectionReasonForBuildRailOrderScenario,
  );
  runLabeledScenarioGroup(
    'terrainTypeForTileKey',
    terrainTypeForTileKeyScenarios(),
    runTerrainTypeForTileKeyScenario,
  );
}
