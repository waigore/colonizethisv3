// Table-driven shared-validator equivalence scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_shared_validator_equivalence_run_rows.dart';

/// One row in [orderSuggestionSharedValidatorEquivalenceScenarios].
class OrderSuggestionSharedValidatorEquivalenceScenario
    implements RefsScenario {
  const OrderSuggestionSharedValidatorEquivalenceScenario({
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

void runOrderSuggestionSharedValidatorEquivalenceScenario(
  OrderSuggestionSharedValidatorEquivalenceScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionSharedValidatorEquivalenceScenario>
orderSuggestionSharedValidatorEquivalenceScenarios() => const [
  OrderSuggestionSharedValidatorEquivalenceScenario(
    label: 'suggestMoveOrders matches default path',
    run: ossveRunSuggestMoveOrdersMatchesDefaultPath,
  ),
  OrderSuggestionSharedValidatorEquivalenceScenario(
    label: 'suggestArmyMoveOrders matches default path',
    run: ossveRunSuggestArmyMoveOrdersMatchesDefaultPath,
  ),
  OrderSuggestionSharedValidatorEquivalenceScenario(
    label: 'suggestWorkOrders matches default path',
    run: ossveRunSuggestWorkOrdersMatchesDefaultPath,
  ),
  OrderSuggestionSharedValidatorEquivalenceScenario(
    label: 'suggestBuildOrders matches default path',
    run: ossveRunSuggestBuildOrdersMatchesDefaultPath,
  ),
  OrderSuggestionSharedValidatorEquivalenceScenario(
    label: 'suggestDiplomaticOrders is deterministic across repeated calls',
    run: ossveRunSuggestDiplomaticOrdersDeterministicAcrossRepeatedCalls,
  ),
  OrderSuggestionSharedValidatorEquivalenceScenario(
    label:
        'shared validator built with externally provided view/unitsById produces identical suggestions to forPlayer default path (no internal rebuild)',
    run: ossveRunSharedValidatorExternalViewUnitsByIdMatchesForPlayerDefault,
    refs: '#2394',
  ),
  OrderSuggestionSharedValidatorEquivalenceScenario(
    label: 'forBasePrefix matches fresh forPlayer for same basePrefix',
    run: ossveRunForBasePrefixMatchesFreshForPlayer,
  ),
];
