// Consolidated draft-order mutations runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/application/draft_orders_mutations_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  runLabeledScenarioGroup(
    'removePendingWorkOrderAt',
    removePendingWorkOrderAtScenarios(),
    runRunnableScenario,
  );
  runLabeledScenarioGroup(
    'tradeOrderForPlayerCommodity / applyTradeOrderForPlayer / '
    'removeTradeOrderForPlayer (Refs #2993 E5b)',
    draftOrdersTradeMutationScenarios(),
    runRunnableScenario,
  );
}
