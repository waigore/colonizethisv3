// Table-driven simple-AI validator-reuse scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'simple_ai_validator_reuse_expectations.dart';

/// One row in [simpleAiValidatorReuseScenarios].
class SimpleAiValidatorReuseScenario implements RefsScenario {
  const SimpleAiValidatorReuseScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final SimpleAiValidatorReuseTarget target;
  @override
  final String? refs;
}

void runSimpleAiValidatorReuseScenario(SimpleAiValidatorReuseScenario scenario) {
  runSimpleAiValidatorReuseExpectation(scenario.target);
}

List<SimpleAiValidatorReuseScenario> simpleAiValidatorReuseHeuristicScenarios() =>
    const [
      SimpleAiValidatorReuseScenario(
        label: 'builds one incremental validator per player heuristic pass',
        target: SimpleAiValidatorReuseTarget.oneValidatorPerHeuristicPass,
        refs: '#2394',
      ),
    ];

List<SimpleAiValidatorReuseScenario> simpleAiValidatorReuseBatchScenarios() =>
    const [
      SimpleAiValidatorReuseScenario(
        label: 'builds one incremental validator per AI player in batch path',
        target: SimpleAiValidatorReuseTarget.oneValidatorPerAiPlayerBatch,
        refs: '#2394',
      ),
    ];
