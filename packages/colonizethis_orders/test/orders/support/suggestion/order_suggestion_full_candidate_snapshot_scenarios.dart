// Table-driven full-candidate snapshot scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_suggestion_full_candidate_snapshot_run_rows.dart';

class OrderSuggestionFullCandidateSnapshotScenario implements LabeledScenario {
  const OrderSuggestionFullCandidateSnapshotScenario({
    required this.label,
    required this.run,
  });

  @override
  final String label;
  final void Function() run;
}

void runOrderSuggestionFullCandidateSnapshotScenario(
  OrderSuggestionFullCandidateSnapshotScenario scenario,
) {
  scenario.run();
}

List<OrderSuggestionFullCandidateSnapshotScenario>
orderSuggestionFullCandidateSnapshotScenarios() => const [
  OrderSuggestionFullCandidateSnapshotScenario(
    label:
        'suggestWorkOrders full-candidate snapshot remains stable (Refs #2133 AC8)',
    run: osfcsRunStableSnapshot,
  ),
];
