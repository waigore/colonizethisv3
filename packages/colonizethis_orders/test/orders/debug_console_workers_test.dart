// Consolidated debug console worker runner (Refs #3949 wave 3).

import 'support/debug_console/debug_console_workers_scenarios.dart';
import 'support/scenario_runner.dart';

void main() {
  runLabeledScenarioGroup(
    'debugConsoleSupportedWorkerTierIds',
    debugConsoleWorkersScenarios(),
    runDebugConsoleWorkersScenario,
  );
}
