// Table-driven colonial discovery declare-war scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_declare_war_colonial_discovery_expectations.dart';

/// One row in [orderSuggestionDeclareWarColonialDiscoveryScenarios].
class OrderSuggestionDeclareWarColonialDiscoveryScenario
    implements RefsScenario {
  const OrderSuggestionDeclareWarColonialDiscoveryScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionDeclareWarColonialDiscoveryTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionDeclareWarColonialDiscoveryScenario(
  OrderSuggestionDeclareWarColonialDiscoveryScenario scenario,
) {
  runOrderSuggestionDeclareWarColonialDiscoveryExpectation(scenario.target);
}

List<OrderSuggestionDeclareWarColonialDiscoveryScenario>
    orderSuggestionDeclareWarColonialDiscoveryScenarios() => const [
          OrderSuggestionDeclareWarColonialDiscoveryScenario(
            label: 'suggestDeclareWarOrders excludes sea-reachable tribe without NW tile visibility (#3620 first-contact gate)',
            target: OrderSuggestionDeclareWarColonialDiscoveryTarget
                .excludesSeaReachableTribeWithoutNwVisibility,
            refs: '#3620',
          ),
        ];
