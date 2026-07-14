// dart format off
// Unified scenario-table test harness (Refs #3939 phase 3).
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
///
/// Pass [labelOf] for typedef/record rows. Class rows that implement
/// [LabeledScenario] may omit it (Refs #3939 slice 63).
void runLabeledScenarios<S>(Iterable<S> scenarios, void Function(S scenario) run, {String Function(S scenario)? labelOf}) {
  for (final scenario in scenarios) {
    runLabeledScenario(_scenarioLabel(scenario, labelOf), () => run(scenario));
  }
}
/// Registers a [groupName] containing table-driven scenario tests.
void runLabeledScenarioGroup<S>(String groupName, Iterable<S> scenarios, void Function(S scenario) run, {String Function(S scenario)? labelOf}) {
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
  throw ScenarioLabelRequiredException('runLabeledScenarios: pass labelOf for non-LabeledScenario rows');
}
// dart format on
