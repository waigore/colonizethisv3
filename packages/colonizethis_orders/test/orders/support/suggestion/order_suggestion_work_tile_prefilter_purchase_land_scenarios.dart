// Table-driven purchase_land prefilter scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_work_tile_prefilter_purchase_land_expectations.dart';

/// One row in [orderSuggestionWorkTilePrefilterPurchaseLandScenarios].
class OrderSuggestionWorkTilePrefilterPurchaseLandScenario
    implements RefsScenario {
  const OrderSuggestionWorkTilePrefilterPurchaseLandScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionWorkTilePrefilterPurchaseLandTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionWorkTilePrefilterPurchaseLandScenario(
  OrderSuggestionWorkTilePrefilterPurchaseLandScenario scenario,
) {
  runOrderSuggestionWorkTilePrefilterPurchaseLandExpectation(scenario.target);
}

List<OrderSuggestionWorkTilePrefilterPurchaseLandScenario>
    orderSuggestionWorkTilePrefilterPurchaseLandScenarios() => const [
          OrderSuggestionWorkTilePrefilterPurchaseLandScenario(
            label: 'includes resource tiles in minor-owned provinces, excludes GP-owned',
            target: OrderSuggestionWorkTilePrefilterPurchaseLandTarget
                .includesMinorExcludesGpOwned,
          ),
          OrderSuggestionWorkTilePrefilterPurchaseLandScenario(
            label: 'includes resource tiles in tribe-owned provinces',
            target: OrderSuggestionWorkTilePrefilterPurchaseLandTarget
                .includesTribeOwnedProvinces,
          ),
          OrderSuggestionWorkTilePrefilterPurchaseLandScenario(
            label: 'playerOwnedProvinceIds yields same candidates as internal scan (build_road)',
            target: OrderSuggestionWorkTilePrefilterPurchaseLandTarget
                .playerOwnedProvinceIdsMatchesDefaultPath,
          ),
        ];
