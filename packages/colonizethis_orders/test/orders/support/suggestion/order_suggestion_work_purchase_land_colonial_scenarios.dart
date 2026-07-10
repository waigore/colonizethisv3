// Table-driven embassy-stage NW purchase_land colonial scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_work_purchase_land_colonial_run_rows.dart';

/// One row in [orderSuggestionWorkPurchaseLandColonialScenarios].
class OrderSuggestionWorkPurchaseLandColonialScenario implements RefsScenario {
  const OrderSuggestionWorkPurchaseLandColonialScenario({
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

void runOrderSuggestionWorkPurchaseLandColonialScenario(
  OrderSuggestionWorkPurchaseLandColonialScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionWorkPurchaseLandColonialScenario>
orderSuggestionWorkPurchaseLandColonialScenarios() => const [
  OrderSuggestionWorkPurchaseLandColonialScenario(
    label:
        'embassy-stage NW tribe: suggestWorkOrders surfaces purchase_land for Merchant',
    run: oswplcRunEmbassySurfacesPurchaseLand,
    refs: '#2509',
  ),
  OrderSuggestionWorkPurchaseLandColonialScenario(
    label:
        'embassy-stage NW tribe: suggestWorkOrders is deterministic for repeated calls',
    run: oswplcRunDeterministicAcrossRepeatedCalls,
    refs: '#2509',
  ),
  OrderSuggestionWorkPurchaseLandColonialScenario(
    label:
        'no embassy with NW tribe: suggestWorkOrders omits purchase_land for Merchant',
    run: oswplcRunNoEmbassyOmitsPurchaseLand,
    refs: '#2509',
  ),
];
