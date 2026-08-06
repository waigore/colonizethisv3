// Ported from colonizethis_logic (Refs #4090 Slice C).
import 'package:colonizethis_test/test.dart';

import 'support/gp_old_world_terrain_redistribution_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  group('applyGreatPowerOldWorldTerrainRedistribution', () {
    runLabeledScenarios(
      gpOldWorldTerrainRedistributionScenarios(),
      runRunnableScenario,
    );
  });
}
