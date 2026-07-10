// Consolidated recruit-worker suggestion runner (Refs #3949 wave 3).

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_recruit_worker_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'suggestRecruitWorkerOrders (#2692 S7) — per-tier inclusion',
    orderSuggestionRecruitWorkerInclusionScenarios(),
    runRunnableScenario,
  );

  runLabeledScenarioGroup(
    'suggestRecruitWorkerOrders (#2692 S7) — parity and ordering',
    orderSuggestionRecruitWorkerParityScenarios(),
    runRunnableScenario,
  );
}
