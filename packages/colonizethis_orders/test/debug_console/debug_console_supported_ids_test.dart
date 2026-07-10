// Consolidated debug console supported-id runner (Refs #3949 wave 3).

import '../orders/support/debug_console/debug_console_supported_ids_scenarios.dart';
import '../orders/support/scenario_runner.dart';

void main() {
  runLabeledScenarioGroup(
    'debug console supported id lists',
    debugConsoleSupportedIdsScenarios(),
    runDebugConsoleSupportedIdsScenario,
  );
}
