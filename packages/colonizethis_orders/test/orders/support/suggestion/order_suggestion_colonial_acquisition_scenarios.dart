// Table-driven colonial acquisition suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_colonial_acquisition_run_rows.dart';

/// One row in [orderSuggestionColonialAcquisitionScenarios].
class OrderSuggestionColonialAcquisitionScenario implements RefsScenario {
  const OrderSuggestionColonialAcquisitionScenario({
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

void runOrderSuggestionColonialAcquisitionScenario(
  OrderSuggestionColonialAcquisitionScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionColonialAcquisitionScenario>
orderSuggestionColonialAcquisitionScenarios() => const [
  OrderSuggestionColonialAcquisitionScenario(
    label: 'embassy-stage tribe: suggestDiplomaticOrders surfaces Join Empire',
    run: oscaRunJoinEmpireCandidateEmitted,
    refs: '#2509',
  ),
  OrderSuggestionColonialAcquisitionScenario(
    label: 'embassy-stage tribe: suggestDeclareWarOrders surfaces declareWar',
    run: oscaRunDeclareWarCandidateEmitted,
    refs: '#2509',
  ),
  OrderSuggestionColonialAcquisitionScenario(
    label: 'candidate set is deterministic across repeated suggestion calls',
    run: oscaRunDeterministicAcrossRepeatedCalls,
    refs: '#2509',
  ),
];
