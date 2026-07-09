// Table-driven colonial acquisition suggestion scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_colonial_acquisition_expectations.dart';

/// One row in [orderSuggestionColonialAcquisitionScenarios].
class OrderSuggestionColonialAcquisitionScenario implements RefsScenario {
  const OrderSuggestionColonialAcquisitionScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderSuggestionColonialAcquisitionTarget target;
  @override
  final String? refs;
}

void runOrderSuggestionColonialAcquisitionScenario(
  OrderSuggestionColonialAcquisitionScenario scenario,
) {
  runOrderSuggestionColonialAcquisitionExpectation(scenario.target);
}

List<OrderSuggestionColonialAcquisitionScenario>
    orderSuggestionColonialAcquisitionScenarios() => const [
          OrderSuggestionColonialAcquisitionScenario(
            label: 'embassy-stage tribe: suggestDiplomaticOrders surfaces Join Empire',
            target: OrderSuggestionColonialAcquisitionTarget
                .joinEmpireCandidateEmitted,
            refs: '#2509',
          ),
          OrderSuggestionColonialAcquisitionScenario(
            label: 'embassy-stage tribe: suggestDeclareWarOrders surfaces declareWar',
            target: OrderSuggestionColonialAcquisitionTarget
                .declareWarCandidateEmitted,
            refs: '#2509',
          ),
          OrderSuggestionColonialAcquisitionScenario(
            label: 'candidate set is deterministic across repeated suggestion calls',
            target: OrderSuggestionColonialAcquisitionTarget
                .deterministicAcrossRepeatedCalls,
            refs: '#2509',
          ),
        ];
