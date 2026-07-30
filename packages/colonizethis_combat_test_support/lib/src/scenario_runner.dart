// dart format off
// Unified scenario-table test harness (Refs #3983 phase 3).

import 'package:colonizethis_test/test.dart';

/// Minimal contract for table-driven scenario rows.
abstract class LabeledScenario {
  String get label;
}

/// Optional issue/spec reference metadata on a scenario row.
abstract class RefsScenario implements LabeledScenario {
  String? get refs;
}

/// Shared tear-off scenario row (scenarioId + label + run [+ optional refs]).
///
/// Prefer this over per-family scenario classes when the row only carries a
/// `void Function()` body (Refs #4196 slice A).
class RunnableScenario implements RefsScenario {
  const RunnableScenario({
    required this.scenarioId,
    required this.label,
    required this.run,
    this.refs,
  });

  final String scenarioId;
  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

/// Compact [RunnableScenario] constructor for densified scenario tables.
RunnableScenario rs({
  required String scenarioId,
  required String label,
  required void Function() run,
  String? refs,
}) =>
    RunnableScenario(
      scenarioId: scenarioId,
      label: label,
      run: run,
      refs: refs,
    );

/// Invokes [RunnableScenario.run] (canonical runner for shared rows).
void runRunnableScenario(RunnableScenario scenario) => scenario.run();

/// Registers one labeled test case (canonical wrapper over bare `test()`).
void runLabeledScenario(String label, void Function() body) {
  test(label, body);
}

/// Registers one test per [scenarios] row using [run].
///
/// Pass [labelOf] for typedef/record rows. Class rows that implement
/// [LabeledScenario] may omit it (Refs #3983).
void runLabeledScenarios<S>(
  Iterable<S> scenarios,
  void Function(S scenario) run, {
  String Function(S scenario)? labelOf,
}) {
  for (final scenario in scenarios) {
    runLabeledScenario(_scenarioLabel(scenario, labelOf), () => run(scenario));
  }
}

/// Registers a [groupName] containing table-driven scenario tests.
void runLabeledScenarioGroup<S>(
  String groupName,
  Iterable<S> scenarios,
  void Function(S scenario) run, {
  String Function(S scenario)? labelOf,
}) {
  group(groupName, () {
    runLabeledScenarios(scenarios, run, labelOf: labelOf);
  });
}

/// Thrown when [runLabeledScenarios] cannot resolve a row label.
class ScenarioLabelRequiredException implements Exception {
  ScenarioLabelRequiredException(this.message);
  final String message;

  @override
  String toString() => 'ScenarioLabelRequiredException: $message';
}

String _scenarioLabel<S>(S scenario, String Function(S scenario)? labelOf) {
  if (labelOf != null) return labelOf(scenario);
  if (scenario is LabeledScenario) return scenario.label;
  throw ScenarioLabelRequiredException(
    'runLabeledScenarios: pass labelOf for non-LabeledScenario rows',
  );
}
// dart format on
