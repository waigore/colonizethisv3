import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';

import 'combat_engagement_snapshot_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'Combat engagement characterization',
    combatEngagementSnapshotScenarios(),
    (s) => s.run(),
  );
}
