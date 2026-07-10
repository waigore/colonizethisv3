// Table-driven colonial intel explore scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_colonial_intel_explore_run_rows.dart';

/// One row in [orderSuggestionColonialIntelExploreScenarios].
class OrderSuggestionColonialIntelExploreScenario implements RefsScenario {
  const OrderSuggestionColonialIntelExploreScenario({
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

void runOrderSuggestionColonialIntelExploreScenario(
  OrderSuggestionColonialIntelExploreScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionColonialIntelExploreScenario>
orderSuggestionColonialIntelExploreScenarios() => const [
  OrderSuggestionColonialIntelExploreScenario(
    label: 'colonialIntelExploreProvinceIdsSorted lists sea-reachable NW',
    run: oscieRunListsSeaReachableNw,
  ),
];
