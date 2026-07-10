// Table-driven debug console worker scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'debug_console_workers_run_rows.dart';

class DebugConsoleWorkersScenario implements RefsScenario {
  const DebugConsoleWorkersScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runDebugConsoleWorkersScenario(DebugConsoleWorkersScenario scenario) {
  scenario.run();
}

List<DebugConsoleWorkersScenario> debugConsoleWorkersScenarios() => const [
  DebugConsoleWorkersScenario(
    label: 'debug worker tier ids are canonical and lexicographically sorted',
    run: dcwRunWorkerTierIdsCanonicalAndLexicographicallySorted,
  ),
];
