// Consolidated prospect location province priority runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.
// Refs #2847: prospect province sweep is capped at kMaxExploreProvinceProbesPerUnit
// (4). On seed-scale maps the co-located feedstock province sorts after many
// world provinces and was never probed despite a co-located idle Explorer.

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_prospect_location_province_priority_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'suggestWorkOrders prospect probes explorer location province first '
    '(Refs #2847 H8-extraction)',
    suggestWorkOrdersProspectLocationProvincePriorityScenarios(),
    runRunnableScenario,
  );
}
