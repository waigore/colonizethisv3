// Consolidated merchant purchase-land candidate tile keys runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/scenario_runner.dart';
import 'support/suggestion/merchant_purchase_land_candidate_tile_keys_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'merchantPurchaseLandCandidateTileKeys',
    merchantPurchaseLandCandidateTileKeysScenarios(),
    runRunnableScenario,
  );
}
