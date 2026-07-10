// Table-driven colonial discovery declare-war scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_declare_war_colonial_discovery_run_rows.dart';

/// One row in [orderSuggestionDeclareWarColonialDiscoveryScenarios].
class OrderSuggestionDeclareWarColonialDiscoveryScenario
    implements RefsScenario {
  const OrderSuggestionDeclareWarColonialDiscoveryScenario({
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

void runOrderSuggestionDeclareWarColonialDiscoveryScenario(
  OrderSuggestionDeclareWarColonialDiscoveryScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionDeclareWarColonialDiscoveryScenario>
orderSuggestionDeclareWarColonialDiscoveryScenarios() => const [
  OrderSuggestionDeclareWarColonialDiscoveryScenario(
    label:
        'suggestDeclareWarOrders excludes sea-reachable tribe without NW tile visibility (#3620 first-contact gate)',
    run: osdwcdRunExcludesSeaReachableTribeWithoutNwVisibility,
    refs: '#3620',
  ),
];
