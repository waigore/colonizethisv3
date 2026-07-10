// Consolidated feedstock new-world projection runner (Refs #3949 wave 3 slice 96).
//
// Refs #3393 Phase 6b (slice 5) — `_newWorldProvinceCountOwnedBy` reads
// `ProvinceOwnerCache.countOwnedByInRegion(playerId, kRegionNewWorld)`.

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_feedstock_new_world_projection_scenarios.dart';

void main() {
  runLabeledScenarios(
    orderSuggestionFeedstockNewWorldProjectionScenarios(),
    runRunnableScenario,
  );
}
