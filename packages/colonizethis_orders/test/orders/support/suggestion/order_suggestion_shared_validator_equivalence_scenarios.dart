// Table-driven shared-validator equivalence scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_shared_validator_equivalence_expectations.dart';

/// One row in [orderSuggestionSharedValidatorEquivalenceScenarios].
class OrderSuggestionSharedValidatorEquivalenceScenario implements RefsScenario {
  const OrderSuggestionSharedValidatorEquivalenceScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionSharedValidatorEquivalenceTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionSharedValidatorEquivalenceScenario(
  OrderSuggestionSharedValidatorEquivalenceScenario scenario,
) {
  runOrderSuggestionSharedValidatorEquivalenceExpectation(scenario.target);
}

List<OrderSuggestionSharedValidatorEquivalenceScenario>
    orderSuggestionSharedValidatorEquivalenceScenarios() => const [
          OrderSuggestionSharedValidatorEquivalenceScenario(
            label: 'suggestMoveOrders matches default path',
            target: OrderSuggestionSharedValidatorEquivalenceTarget
                .suggestMoveOrdersMatchesDefaultPath,
          ),
          OrderSuggestionSharedValidatorEquivalenceScenario(
            label: 'suggestArmyMoveOrders matches default path',
            target: OrderSuggestionSharedValidatorEquivalenceTarget
                .suggestArmyMoveOrdersMatchesDefaultPath,
          ),
          OrderSuggestionSharedValidatorEquivalenceScenario(
            label: 'suggestWorkOrders matches default path',
            target: OrderSuggestionSharedValidatorEquivalenceTarget
                .suggestWorkOrdersMatchesDefaultPath,
          ),
          OrderSuggestionSharedValidatorEquivalenceScenario(
            label: 'suggestBuildOrders matches default path',
            target: OrderSuggestionSharedValidatorEquivalenceTarget
                .suggestBuildOrdersMatchesDefaultPath,
          ),
          OrderSuggestionSharedValidatorEquivalenceScenario(
            label: 'suggestDiplomaticOrders is deterministic across repeated calls',
            target: OrderSuggestionSharedValidatorEquivalenceTarget
                .suggestDiplomaticOrdersDeterministicAcrossRepeatedCalls,
          ),
          OrderSuggestionSharedValidatorEquivalenceScenario(
            label: 'shared validator built with externally provided view/unitsById produces identical suggestions to forPlayer default path (no internal rebuild)',
            target: OrderSuggestionSharedValidatorEquivalenceTarget
                .sharedValidatorExternalViewUnitsByIdMatchesForPlayerDefault,
            refs: '#2394',
          ),
          OrderSuggestionSharedValidatorEquivalenceScenario(
            label: 'forBasePrefix matches fresh forPlayer for same basePrefix',
            target: OrderSuggestionSharedValidatorEquivalenceTarget
                .forBasePrefixMatchesFreshForPlayer,
          ),
        ];
