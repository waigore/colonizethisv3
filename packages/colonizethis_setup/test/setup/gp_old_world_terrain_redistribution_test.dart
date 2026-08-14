// Ported from colonizethis_logic (Refs #4090 Slice C).
import 'package:colonizethis_test/test.dart';

import 'support/gp_old_world_terrain_redistribution_preserves_scenarios.dart';
import 'support/gp_old_world_terrain_redistribution_skip_and_balance_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  group('applyGreatPowerOldWorldTerrainRedistribution', () {
    runLabeledScenarios([
      ...gpOldWorldTerrainRedistributionPreservesScenarios(),
      ...gpOldWorldTerrainRedistributionSkipAndBalanceScenarios(),
    ], runRunnableScenario);
  });
}
