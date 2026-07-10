// Table-driven prospect location province priority scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_prospect_location_province_priority_run_rows.dart';

/// One row in prospect location province priority scenario tables.
class OrderSuggestionProspectLocationProvincePriorityScenario
    implements RefsScenario {
  const OrderSuggestionProspectLocationProvincePriorityScenario({
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

void runOrderSuggestionProspectLocationProvincePriorityScenario(
  OrderSuggestionProspectLocationProvincePriorityScenario scenario,
) {
  scenario.run();
}

/// Scenarios for suggestWorkOrders prospect location province priority.
List<OrderSuggestionProspectLocationProvincePriorityScenario>
suggestWorkOrdersProspectLocationProvincePriorityScenarios() => const [
  OrderSuggestionProspectLocationProvincePriorityScenario(
    label:
        'co-located Explorer in late-sorted province still receives a prospect suggestion for its iron tile',
    run: osplppRunCoLocatedExplorerReceivesProspectInLateSortedProvince,
    refs: '#2847',
  ),
  OrderSuggestionProspectLocationProvincePriorityScenario(
    label:
        'iron province without fogged visibility still yields no prospect (negative control)',
    run: osplppRunNoProspectWithoutFoggedVisibility,
    refs: '#2847',
  ),
];
