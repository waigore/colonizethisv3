// Table-driven purchase_land prefilter scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_work_tile_prefilter_purchase_land_run_rows.dart';

/// One row in [orderSuggestionWorkTilePrefilterPurchaseLandScenarios].
class OrderSuggestionWorkTilePrefilterPurchaseLandScenario
    implements RefsScenario {
  const OrderSuggestionWorkTilePrefilterPurchaseLandScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runOrderSuggestionWorkTilePrefilterPurchaseLandScenario(
  OrderSuggestionWorkTilePrefilterPurchaseLandScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionWorkTilePrefilterPurchaseLandScenario>
orderSuggestionWorkTilePrefilterPurchaseLandScenarios() => const [
  OrderSuggestionWorkTilePrefilterPurchaseLandScenario(
    label:
        'includes resource tiles in minor-owned provinces, excludes GP-owned',
    run: oswtplRunIncludesMinorExcludesGpOwned,
  ),
  OrderSuggestionWorkTilePrefilterPurchaseLandScenario(
    label: 'includes resource tiles in tribe-owned provinces',
    run: oswtplRunIncludesTribeOwnedProvinces,
  ),
  OrderSuggestionWorkTilePrefilterPurchaseLandScenario(
    label:
        'playerOwnedProvinceIds yields same candidates as internal scan (build_road)',
    run: oswtplRunPlayerOwnedProvinceIdsMatchesDefaultPath,
  ),
];
