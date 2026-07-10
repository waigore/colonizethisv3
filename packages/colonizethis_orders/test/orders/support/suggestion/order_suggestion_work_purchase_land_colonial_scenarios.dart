// Table-driven embassy-stage NW purchase_land colonial scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_work_purchase_land_colonial_expectations.dart';

/// One row in [orderSuggestionWorkPurchaseLandColonialScenarios].
class OrderSuggestionWorkPurchaseLandColonialScenario implements RefsScenario {
  const OrderSuggestionWorkPurchaseLandColonialScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionWorkPurchaseLandColonialTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionWorkPurchaseLandColonialScenario(
  OrderSuggestionWorkPurchaseLandColonialScenario scenario,
) {
  runOrderSuggestionWorkPurchaseLandColonialExpectation(scenario.target);
}

List<OrderSuggestionWorkPurchaseLandColonialScenario>
    orderSuggestionWorkPurchaseLandColonialScenarios() => const [
          OrderSuggestionWorkPurchaseLandColonialScenario(
            label: 'embassy-stage NW tribe: suggestWorkOrders surfaces purchase_land for Merchant',
            target: OrderSuggestionWorkPurchaseLandColonialTarget
                .embassySurfacesPurchaseLand,
            refs: '#2509',
          ),
          OrderSuggestionWorkPurchaseLandColonialScenario(
            label: 'embassy-stage NW tribe: suggestWorkOrders is deterministic for repeated calls',
            target: OrderSuggestionWorkPurchaseLandColonialTarget
                .deterministicAcrossRepeatedCalls,
            refs: '#2509',
          ),
          OrderSuggestionWorkPurchaseLandColonialScenario(
            label: 'no embassy with NW tribe: suggestWorkOrders omits purchase_land for Merchant',
            target: OrderSuggestionWorkPurchaseLandColonialTarget
                .noEmbassyOmitsPurchaseLand,
            refs: '#2509',
          ),
        ];
