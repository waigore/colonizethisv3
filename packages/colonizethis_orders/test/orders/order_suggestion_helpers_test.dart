// Consolidated order suggestion helpers runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_helpers_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'filterArmyMoveOrdersByDiplomacy',
    filterArmyMoveOrdersByDiplomacyScenarios(),
    runRunnableScenario,
  );
}
