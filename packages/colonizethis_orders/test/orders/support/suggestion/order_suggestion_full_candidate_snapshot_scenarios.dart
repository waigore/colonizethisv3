// Table-driven full-candidate snapshot scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_full_candidate_snapshot_expectations.dart';

class OrderSuggestionFullCandidateSnapshotScenario implements LabeledScenario {
  const OrderSuggestionFullCandidateSnapshotScenario({
    required this.label,
    required this.target,
  });

  @override
  final String label;
  final OrderSuggestionFullCandidateSnapshotTarget target;
}

void runOrderSuggestionFullCandidateSnapshotScenario(
  OrderSuggestionFullCandidateSnapshotScenario scenario,
) {
  runOrderSuggestionFullCandidateSnapshotExpectation(scenario.target);
}

List<OrderSuggestionFullCandidateSnapshotScenario>
    orderSuggestionFullCandidateSnapshotScenarios() => const [
          OrderSuggestionFullCandidateSnapshotScenario(
            label: 'suggestWorkOrders full-candidate snapshot remains stable (Refs #2133 AC8)',
            target: OrderSuggestionFullCandidateSnapshotTarget.stableSnapshot,
          ),
        ];
