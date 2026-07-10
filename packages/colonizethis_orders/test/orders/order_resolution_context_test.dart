// Consolidated order-resolution context runner (Refs #3949 wave 3).
//
// Migrated from imperative `test()` bodies to table-driven scenarios in support/.

import 'support/scenario_runner.dart';
import 'support/engine/order_resolution_context_scenarios.dart';

void main() {
  runLabeledScenarios(orderResolutionContextScenarios(), runRunnableScenario);
}
