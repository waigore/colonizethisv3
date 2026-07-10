// Consolidated diplomacy-filter suggestion runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_diplomacy_filter_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'getProvinceOwnerMap reads ProvinceOwnerCache (slice 6)',
    getProvinceOwnerMapProvinceOwnerCacheScenarios(),
    runRunnableScenario,
  );
  runLabeledScenarioGroup(
    'filterMoveOrdersByDiplomacy and getProvinceOwnerMap',
    filterMoveOrdersByDiplomacyScenarios(),
    runRunnableScenario,
  );
}
