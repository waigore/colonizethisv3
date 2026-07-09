// Table-driven diplomatic validator-reuse scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_diplomatic_validator_reuse_expectations.dart';

/// One row in [orderSuggestionDiplomaticValidatorReuseScenarios].
class OrderSuggestionDiplomaticValidatorReuseScenario implements RefsScenario {
  const OrderSuggestionDiplomaticValidatorReuseScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionDiplomaticValidatorReuseTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionDiplomaticValidatorReuseScenario(
  OrderSuggestionDiplomaticValidatorReuseScenario scenario,
) {
  runOrderSuggestionDiplomaticValidatorReuseExpectation(scenario.target);
}

List<OrderSuggestionDiplomaticValidatorReuseScenario>
    orderSuggestionDiplomaticValidatorReuseScenarios() => const [
          OrderSuggestionDiplomaticValidatorReuseScenario(
            label: 'builds one pass-level validator across multiple diplomatic targets',
            target: OrderSuggestionDiplomaticValidatorReuseTarget
                .onePassLevelValidatorAcrossTargets,
            refs: '#2394',
          ),
          OrderSuggestionDiplomaticValidatorReuseScenario(
            label: 'skips pass-level build when sharedCandidateValidator is supplied',
            target: OrderSuggestionDiplomaticValidatorReuseTarget
                .skipsPassLevelBuildWhenSharedSupplied,
            refs: '#2394',
          ),
          OrderSuggestionDiplomaticValidatorReuseScenario(
            label: 'rebinds pass validator to workingOrders after each target',
            target: OrderSuggestionDiplomaticValidatorReuseTarget
                .rebindsPassValidatorAfterEachTarget,
            refs: '#2394',
          ),
        ];
