// Consolidated town-work prefilter runner (Refs #3949 wave 3 slice 95).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_work_tile_prefilter_town_work_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'rawCandidateTilesForWorkTarget (town work)',
    orderSuggestionWorkTilePrefilterTownWorkScenarios(),
    runOrderSuggestionWorkTilePrefilterTownWorkScenario,
  );
}
