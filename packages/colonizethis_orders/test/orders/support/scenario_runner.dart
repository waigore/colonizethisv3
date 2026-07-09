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
