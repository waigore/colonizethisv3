// Consolidated order suggestion context helpers runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/scenario_runner.dart';
import 'support/suggestion/order_suggestion_context_helpers_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'appendDiplomaticOrderForTrial',
    appendDiplomaticOrderForTrialScenarios(),
    runRunnableScenario,
  );
  runLabeledScenarioGroup(
    'OvertureStageChain.next',
    overtureStageChainNextScenarios(),
    runRunnableScenario,
  );
  runLabeledScenarioGroup(
    'OvertureStageChain.previous',
    overtureStageChainPreviousScenarios(),
    runRunnableScenario,
  );
  runLabeledScenarioGroup(
    'acceptance wrappers',
    orderSuggestionContextAcceptanceWrapperScenarios(),
    runRunnableScenario,
  );
}
