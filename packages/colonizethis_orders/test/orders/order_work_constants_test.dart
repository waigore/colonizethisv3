// Consolidated order/work constant ownership runner (Refs #3949 wave 3 slice 96).
//
// Order/work-domain constant ownership (Refs #3290).

import 'support/order_work_constants_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  runLabeledScenarioGroup(
    'order_work_constants ownership (Refs #3290)',
    orderWorkConstantsScenarios(),
    runOrderWorkConstantsScenario,
  );
}
