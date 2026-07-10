// Table-driven simple-AI validator-reuse scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'simple_ai_validator_reuse_run_rows.dart';

/// One row in [simpleAiValidatorReuseScenarios].
class SimpleAiValidatorReuseScenario implements RefsScenario {
  const SimpleAiValidatorReuseScenario({
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

void runSimpleAiValidatorReuseScenario(
  SimpleAiValidatorReuseScenario scenario,
) {
  scenario.run();
}

List<SimpleAiValidatorReuseScenario>
simpleAiValidatorReuseHeuristicScenarios() => const [
  SimpleAiValidatorReuseScenario(
    label: 'builds one incremental validator per player heuristic pass',
    run: savrRunOneValidatorPerHeuristicPass,
    refs: '#2394',
  ),
];

List<SimpleAiValidatorReuseScenario> simpleAiValidatorReuseBatchScenarios() =>
    const [
      SimpleAiValidatorReuseScenario(
        label: 'builds one incremental validator per AI player in batch path',
        run: savrRunOneValidatorPerAiPlayerBatch,
        refs: '#2394',
      ),
    ];
