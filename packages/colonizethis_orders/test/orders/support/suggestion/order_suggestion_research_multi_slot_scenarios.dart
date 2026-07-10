// Table-driven multi-slot research suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_research_multi_slot_run_rows.dart';

/// One row in [orderSuggestionResearchMultiSlotScenarios].
class OrderSuggestionResearchMultiSlotScenario implements RefsScenario {
  const OrderSuggestionResearchMultiSlotScenario({
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

void runOrderSuggestionResearchMultiSlotScenario(
  OrderSuggestionResearchMultiSlotScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionResearchMultiSlotScenario>
orderSuggestionResearchMultiSlotScenarios() => const [
  OrderSuggestionResearchMultiSlotScenario(
    label: 'fills every empty slot with a distinct researchable tech',
    run: osrmsRunFillsEveryEmptySlotWithDistinctResearchableTech,
    refs: '#3472',
  ),
  OrderSuggestionResearchMultiSlotScenario(
    label: 're-emits in-progress research so the resolver preserves progress',
    run: osrmsRunReEmitsInProgressResearch,
    refs: '#3472',
  ),
  OrderSuggestionResearchMultiSlotScenario(
    label: 'returns no suggestions when there are zero research slots',
    run: osrmsRunReturnsNoSuggestionsWhenZeroResearchSlots,
    refs: '#3472',
  ),
  OrderSuggestionResearchMultiSlotScenario(
    label: 'does not re-suggest a tech already assigned by a pending order',
    run: osrmsRunDoesNotReSuggestTechAlreadyAssignedByPendingOrder,
    refs: '#3472',
  ),
];
