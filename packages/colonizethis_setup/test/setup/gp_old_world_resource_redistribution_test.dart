// Ported from colonizethis_logic (Refs #4090 Slice C).
import 'package:colonizethis_test/test.dart';

import 'support/gp_old_world_resource_redistribution_capacity_scenarios.dart';
import 'support/gp_old_world_resource_redistribution_preserves_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  group('applyGreatPowerOldWorldResourceRedistribution', () {
    runLabeledScenarios([
      ...gpOldWorldResourceRedistributionPreservesScenarios(),
      ...gpOldWorldResourceRedistributionCapacityScenarios(),
    ], runRunnableScenario);
  });
}
