// Consolidated orders-domain logging runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/application/orders_logging_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  runLabeledScenarioGroup(
    'ordersLog (Refs #3290 C2)',
    ordersLoggingScenarios(),
    runRunnableScenario,
  );
}
