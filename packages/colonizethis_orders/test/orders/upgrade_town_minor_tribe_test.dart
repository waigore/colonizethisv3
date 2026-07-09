// Consolidated upgrade_town Minor/Tribe runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/scenario_runner.dart';
import 'support/validators/upgrade_town_minor_tribe_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'upgrade_town on Minor/Tribe towns (Refs #3872)',
    upgradeTownMinorTribeScenarios(),
    runUpgradeTownMinorTribeScenario,
  );
}
