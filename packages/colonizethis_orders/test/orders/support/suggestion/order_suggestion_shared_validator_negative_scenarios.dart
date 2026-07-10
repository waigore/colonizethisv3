// Table-driven shared-validator negative scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_shared_validator_negative_run_rows.dart';

/// One row in [orderSuggestionSharedValidatorNegativeMismatchScenarios].
class OrderSuggestionSharedValidatorNegativeScenario implements RefsScenario {
  const OrderSuggestionSharedValidatorNegativeScenario({
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

void runOrderSuggestionSharedValidatorNegativeScenario(
  OrderSuggestionSharedValidatorNegativeScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionSharedValidatorNegativeScenario>
orderSuggestionSharedValidatorNegativeMismatchScenarios() => const [
  OrderSuggestionSharedValidatorNegativeScenario(
    label:
        'suggestMoveOrders trips assertion when validator is for a different player',
    run: ossvnRunSuggestMoveOrdersWrongPlayer,
    refs: '#2394',
  ),
  OrderSuggestionSharedValidatorNegativeScenario(
    label:
        'suggestArmyMoveOrders trips assertion when validator is for a different player',
    run: ossvnRunSuggestArmyMoveOrdersWrongPlayer,
    refs: '#2394',
  ),
  OrderSuggestionSharedValidatorNegativeScenario(
    label:
        'suggestWorkOrders trips assertion when validator is for a different player',
    run: ossvnRunSuggestWorkOrdersWrongPlayer,
    refs: '#2394',
  ),
  OrderSuggestionSharedValidatorNegativeScenario(
    label:
        'suggestBuildOrders trips assertion when validator is for a different player',
    run: ossvnRunSuggestBuildOrdersWrongPlayer,
    refs: '#2394',
  ),
  OrderSuggestionSharedValidatorNegativeScenario(
    label:
        'IncrementalCandidateValidator.forPlayer trips assertion when supplied view is for a different player',
    run: ossvnRunForPlayerForeignView,
    refs: '#2394',
  ),
];

List<OrderSuggestionSharedValidatorNegativeScenario>
orderSuggestionSharedValidatorNegativeSmokeScenarios() => const [
  OrderSuggestionSharedValidatorNegativeScenario(
    label:
        'orders generated under the new shared-validator code path are unchanged against a known fixture',
    run: ossvnRunSimpleHeuristicsSmokeFixture,
    refs: '#2394',
  ),
];
