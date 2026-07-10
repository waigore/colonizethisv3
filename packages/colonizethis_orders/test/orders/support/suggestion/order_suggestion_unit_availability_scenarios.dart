// Table-driven order suggestion unit availability scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_unit_availability_expectations.dart';

/// One row in order suggestion unit availability scenario tables.
class OrderSuggestionUnitAvailabilityScenario implements RefsScenario {
  const OrderSuggestionUnitAvailabilityScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionUnitAvailabilityTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionUnitAvailabilityScenario(
  OrderSuggestionUnitAvailabilityScenario scenario,
) {
  runOrderSuggestionUnitAvailabilityExpectation(scenario.target);
}

/// Scenarios for getAvailableWorkTargetsForUnit.
List<OrderSuggestionUnitAvailabilityScenario>
    getAvailableWorkTargetsForUnitScenarios() => const [
          OrderSuggestionUnitAvailabilityScenario(
            label: 'pending draft work short-circuits with zero engine probes',
            target: OrderSuggestionUnitAvailabilityTarget.pendingDraftShortCircuits,
            refs: '#2133',
          ),
          OrderSuggestionUnitAvailabilityScenario(
            label: 'pending draft: zero probes even with high-reveal world (issue #2133 scale)',
            target: OrderSuggestionUnitAvailabilityTarget.pendingDraftZeroProbesScale,
            refs: '#2133',
          ),
          OrderSuggestionUnitAvailabilityScenario(
            label: 'multi-target availability matches shared-validator tile keys per target',
            target:
                OrderSuggestionUnitAvailabilityTarget.multiTargetMatchesSharedValidator,
            refs: '#2133',
          ),
        ];
