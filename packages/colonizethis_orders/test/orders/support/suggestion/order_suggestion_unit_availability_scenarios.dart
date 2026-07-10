// Table-driven order suggestion unit availability scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_unit_availability_run_rows.dart';

/// One row in order suggestion unit availability scenario tables.
class OrderSuggestionUnitAvailabilityScenario implements RefsScenario {
  const OrderSuggestionUnitAvailabilityScenario({
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

void runOrderSuggestionUnitAvailabilityScenario(
  OrderSuggestionUnitAvailabilityScenario scenario,
) {
  scenario.run();
}

/// Scenarios for getAvailableWorkTargetsForUnit.
List<OrderSuggestionUnitAvailabilityScenario>
getAvailableWorkTargetsForUnitScenarios() => const [
  OrderSuggestionUnitAvailabilityScenario(
    label: 'pending draft work short-circuits with zero engine probes',
    run: osuaRunPendingDraftShortCircuits,
    refs: '#2133',
  ),
  OrderSuggestionUnitAvailabilityScenario(
    label:
        'pending draft: zero probes even with high-reveal world (issue #2133 scale)',
    run: osuaRunPendingDraftZeroProbesScale,
    refs: '#2133',
  ),
  OrderSuggestionUnitAvailabilityScenario(
    label:
        'multi-target availability matches shared-validator tile keys per target',
    run: osuaRunMultiTargetMatchesSharedValidator,
    refs: '#2133',
  ),
];
