// Consolidated own-province prospect tile-cap runner (Refs #3949 wave 3 slice 96).
//
// Refs #2847: own-province prospect probes are exempt from the shared per-pass
// budget, but `_allAcceptedProspectTilesInProvince` still capped at
// `kMaxWorkProbeAttemptsPerUnitPerTarget` (4).

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_prospect_own_province_tile_cap_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'suggestWorkOrders own-province prospect reaches feedstock tile past '
    'per-target probe cap (Refs #2847)',
    orderSuggestionProspectOwnProvinceTileCapScenarios(),
    runRunnableScenario,
  );
}
