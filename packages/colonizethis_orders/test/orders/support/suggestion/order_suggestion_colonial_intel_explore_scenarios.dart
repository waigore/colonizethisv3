// Table-driven colonial intel explore scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_colonial_intel_explore_expectations.dart';

/// One row in [orderSuggestionColonialIntelExploreScenarios].
class OrderSuggestionColonialIntelExploreScenario implements RefsScenario {
  const OrderSuggestionColonialIntelExploreScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionColonialIntelExploreTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionColonialIntelExploreScenario(
  OrderSuggestionColonialIntelExploreScenario scenario,
) {
  runOrderSuggestionColonialIntelExploreExpectation(scenario.target);
}

List<OrderSuggestionColonialIntelExploreScenario>
    orderSuggestionColonialIntelExploreScenarios() => const [
          OrderSuggestionColonialIntelExploreScenario(
            label: 'colonialIntelExploreProvinceIdsSorted lists sea-reachable NW',
            target: OrderSuggestionColonialIntelExploreTarget.listsSeaReachableNw,
          ),
        ];
