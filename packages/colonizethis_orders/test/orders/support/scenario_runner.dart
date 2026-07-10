// Unified scenario-table test harness (Refs #3949 wave 3).

import 'package:colonizethis_test/test.dart';

/// Minimal contract for table-driven scenario rows.
abstract class LabeledScenario {
  String get label;
}

/// Optional issue/spec reference metadata on a scenario row.
abstract class RefsScenario implements LabeledScenario {
  String? get refs;
}

/// Shared tear-off scenario row (label + run [+ optional refs]).
///
/// Prefer this over per-family scenario classes when the row only carries a
/// `void Function()` body (Refs #3949 wave 3 slice 153).
class RunnableScenario implements RefsScenario {
  const RunnableScenario({required this.label, required this.run, this.refs});

  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

/// Compact [RunnableScenario] constructor for densified scenario tables
/// (Refs #3949 wave 3 slice 156).
RunnableScenario rs(String label, void Function() run, [String? refs]) =>
    RunnableScenario(label: label, run: run, refs: refs);

/// Invokes [RunnableScenario.run] (canonical runner for shared rows).
void runRunnableScenario(RunnableScenario scenario) => scenario.run();

/// Registers one labeled test case (canonical wrapper over bare `test()`).
void runLabeledScenario(String label, void Function() body) {
  test(label, body);
}

/// Registers one test per [scenarios] row using [run].
void runLabeledScenarios<S extends LabeledScenario>(
  Iterable<S> scenarios,
  void Function(S scenario) run,
) {
  for (final scenario in scenarios) {
    runLabeledScenario(scenario.label, () => run(scenario));
  }
}

/// Registers a [groupName] containing table-driven scenario tests.
void runLabeledScenarioGroup<S extends LabeledScenario>(
  String groupName,
  Iterable<S> scenarios,
  void Function(S scenario) run,
) {
  group(groupName, () {
    runLabeledScenarios(scenarios, run);
  });
}
