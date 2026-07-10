// Consolidated purchase-land work handler runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import '../support/scenario_runner.dart';
import '../support/work_handlers/purchase_land_work_handler_scenarios.dart';

void main() {
  runLabeledScenarioGroup(
    'PurchaseLandWorkOrderHandler',
    purchaseLandWorkHandlerScenarios().take(2),
    runPurchaseLandWorkHandlerScenario,
  );
  runLabeledScenarioGroup(
    'applyPurchaseLandCompletion',
    purchaseLandWorkHandlerScenarios().skip(2),
    runPurchaseLandWorkHandlerScenario,
  );
}
