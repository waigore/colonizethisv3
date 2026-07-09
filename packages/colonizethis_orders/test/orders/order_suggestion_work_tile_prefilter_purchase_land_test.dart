// Consolidated purchase_land prefilter runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_work_tile_prefilter_purchase_land_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'rawCandidateTilesForWorkTarget (purchase_land)',
    orderSuggestionWorkTilePrefilterPurchaseLandScenarios(),
    runOrderSuggestionWorkTilePrefilterPurchaseLandScenario,
  );
}
