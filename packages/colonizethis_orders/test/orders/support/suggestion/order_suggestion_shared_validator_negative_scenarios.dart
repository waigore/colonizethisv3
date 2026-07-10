// Table-driven shared-validator negative scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_shared_validator_negative_expectations.dart';

/// One row in [orderSuggestionSharedValidatorNegativeMismatchScenarios].
class OrderSuggestionSharedValidatorNegativeScenario implements RefsScenario {
  const OrderSuggestionSharedValidatorNegativeScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionSharedValidatorNegativeTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionSharedValidatorNegativeScenario(
  OrderSuggestionSharedValidatorNegativeScenario scenario,
) {
  runOrderSuggestionSharedValidatorNegativeExpectation(scenario.target);
}

List<OrderSuggestionSharedValidatorNegativeScenario>
    orderSuggestionSharedValidatorNegativeMismatchScenarios() => const [
          OrderSuggestionSharedValidatorNegativeScenario(
            label: 'suggestMoveOrders trips assertion when validator is for a different player',
            target: OrderSuggestionSharedValidatorNegativeTarget
                .suggestMoveOrdersWrongPlayer,
            refs: '#2394',
          ),
          OrderSuggestionSharedValidatorNegativeScenario(
            label: 'suggestArmyMoveOrders trips assertion when validator is for a different player',
            target: OrderSuggestionSharedValidatorNegativeTarget
                .suggestArmyMoveOrdersWrongPlayer,
            refs: '#2394',
          ),
          OrderSuggestionSharedValidatorNegativeScenario(
            label: 'suggestWorkOrders trips assertion when validator is for a different player',
            target: OrderSuggestionSharedValidatorNegativeTarget
                .suggestWorkOrdersWrongPlayer,
            refs: '#2394',
          ),
          OrderSuggestionSharedValidatorNegativeScenario(
            label: 'suggestBuildOrders trips assertion when validator is for a different player',
            target: OrderSuggestionSharedValidatorNegativeTarget
                .suggestBuildOrdersWrongPlayer,
            refs: '#2394',
          ),
          OrderSuggestionSharedValidatorNegativeScenario(
            label: 'IncrementalCandidateValidator.forPlayer trips assertion when supplied view is for a different player',
            target: OrderSuggestionSharedValidatorNegativeTarget.forPlayerForeignView,
            refs: '#2394',
          ),
        ];

List<OrderSuggestionSharedValidatorNegativeScenario>
    orderSuggestionSharedValidatorNegativeSmokeScenarios() => const [
          OrderSuggestionSharedValidatorNegativeScenario(
            label: 'orders generated under the new shared-validator code path are unchanged against a known fixture',
            target: OrderSuggestionSharedValidatorNegativeTarget
                .simpleHeuristicsSmokeFixture,
            refs: '#2394',
          ),
        ];
