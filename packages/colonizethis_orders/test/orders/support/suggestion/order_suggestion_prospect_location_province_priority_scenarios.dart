// Table-driven prospect location province priority scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_prospect_location_province_priority_expectations.dart';

/// One row in prospect location province priority scenario tables.
class OrderSuggestionProspectLocationProvincePriorityScenario
    implements RefsScenario {
  const OrderSuggestionProspectLocationProvincePriorityScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionProspectLocationProvincePriorityTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionProspectLocationProvincePriorityScenario(
  OrderSuggestionProspectLocationProvincePriorityScenario scenario,
) {
  runOrderSuggestionProspectLocationProvincePriorityExpectation(
    scenario.target,
  );
}

/// Scenarios for suggestWorkOrders prospect location province priority.
List<OrderSuggestionProspectLocationProvincePriorityScenario>
    suggestWorkOrdersProspectLocationProvincePriorityScenarios() => const [
          OrderSuggestionProspectLocationProvincePriorityScenario(
            label: 'co-located Explorer in late-sorted province still receives a prospect suggestion for its iron tile',
            target: OrderSuggestionProspectLocationProvincePriorityTarget
                .coLocatedExplorerReceivesProspectInLateSortedProvince,
            refs: '#2847',
          ),
          OrderSuggestionProspectLocationProvincePriorityScenario(
            label: 'iron province without fogged visibility still yields no prospect (negative control)',
            target: OrderSuggestionProspectLocationProvincePriorityTarget
                .noProspectWithoutFoggedVisibility,
            refs: '#2847',
          ),
        ];
