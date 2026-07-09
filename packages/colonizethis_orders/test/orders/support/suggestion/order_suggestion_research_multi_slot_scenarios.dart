// Table-driven multi-slot research suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_research_multi_slot_expectations.dart';

/// One row in [orderSuggestionResearchMultiSlotScenarios].
class OrderSuggestionResearchMultiSlotScenario implements RefsScenario {
  const OrderSuggestionResearchMultiSlotScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionResearchMultiSlotTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionResearchMultiSlotScenario(
  OrderSuggestionResearchMultiSlotScenario scenario,
) {
  runOrderSuggestionResearchMultiSlotExpectation(scenario.target);
}

List<OrderSuggestionResearchMultiSlotScenario>
    orderSuggestionResearchMultiSlotScenarios() => const [
          OrderSuggestionResearchMultiSlotScenario(
            label: 'fills every empty slot with a distinct researchable tech',
            target: OrderSuggestionResearchMultiSlotTarget
                .fillsEveryEmptySlotWithDistinctResearchableTech,
            refs: '#3472',
          ),
          OrderSuggestionResearchMultiSlotScenario(
            label: 're-emits in-progress research so the resolver preserves progress',
            target:
                OrderSuggestionResearchMultiSlotTarget.reEmitsInProgressResearch,
            refs: '#3472',
          ),
          OrderSuggestionResearchMultiSlotScenario(
            label: 'returns no suggestions when there are zero research slots',
            target: OrderSuggestionResearchMultiSlotTarget
                .returnsNoSuggestionsWhenZeroResearchSlots,
            refs: '#3472',
          ),
          OrderSuggestionResearchMultiSlotScenario(
            label: 'does not re-suggest a tech already assigned by a pending order',
            target: OrderSuggestionResearchMultiSlotTarget
                .doesNotReSuggestTechAlreadyAssignedByPendingOrder,
            refs: '#3472',
          ),
        ];
