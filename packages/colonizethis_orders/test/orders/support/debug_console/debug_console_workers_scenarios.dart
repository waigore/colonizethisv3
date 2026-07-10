// Table-driven debug console worker scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'debug_console_workers_expectations.dart';

class DebugConsoleWorkersScenario implements RefsScenario {
  const DebugConsoleWorkersScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final DebugConsoleWorkersTarget target;
  @override
  final String? refs;
}

void runDebugConsoleWorkersScenario(DebugConsoleWorkersScenario scenario) {
  runDebugConsoleWorkersExpectation(scenario.target);
}

List<DebugConsoleWorkersScenario> debugConsoleWorkersScenarios() => const [
      DebugConsoleWorkersScenario(
        label: 'debug worker tier ids are canonical and lexicographically sorted',
        target: DebugConsoleWorkersTarget
            .workerTierIdsCanonicalAndLexicographicallySorted,
      ),
    ];
