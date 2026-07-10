// Consolidated propagate-road-to-adjacent-capital runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/scenario_runner.dart';
import 'support/application/propagate_road_to_adjacent_capital_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'propagateRoadToAdjacentCapitalOrPort',
    propagateRoadToAdjacentCapitalScenarios(),
    runPropagateRoadToAdjacentCapitalScenario,
  );
}
