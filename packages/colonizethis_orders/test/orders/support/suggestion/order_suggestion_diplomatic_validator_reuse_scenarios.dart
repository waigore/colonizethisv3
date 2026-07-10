// Table-driven diplomatic validator-reuse scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_diplomatic_validator_reuse_run_rows.dart';

/// One row in [orderSuggestionDiplomaticValidatorReuseScenarios].
class OrderSuggestionDiplomaticValidatorReuseScenario implements RefsScenario {
  const OrderSuggestionDiplomaticValidatorReuseScenario({
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

void runOrderSuggestionDiplomaticValidatorReuseScenario(
  OrderSuggestionDiplomaticValidatorReuseScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionDiplomaticValidatorReuseScenario>
orderSuggestionDiplomaticValidatorReuseScenarios() => const [
  OrderSuggestionDiplomaticValidatorReuseScenario(
    label: 'builds one pass-level validator across multiple diplomatic targets',
    run: osdvrRunOnePassLevelValidatorAcrossTargets,
    refs: '#2394',
  ),
  OrderSuggestionDiplomaticValidatorReuseScenario(
    label: 'skips pass-level build when sharedCandidateValidator is supplied',
    run: osdvrRunSkipsPassLevelBuildWhenSharedSupplied,
    refs: '#2394',
  ),
  OrderSuggestionDiplomaticValidatorReuseScenario(
    label: 'rebinds pass validator to workingOrders after each target',
    run: osdvrRunRebindsPassValidatorAfterEachTarget,
    refs: '#2394',
  ),
];
