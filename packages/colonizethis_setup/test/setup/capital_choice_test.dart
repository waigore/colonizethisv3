// Densified via scenario table (Refs #4349 Slice C).
import 'package:colonizethis_test/test.dart';

import 'support/capital_choice_scenarios.dart' show capitalChoiceScenarios;
import 'support/scenario_runner.dart';

void main() {
  group('CapitalChoice', () {
    runLabeledScenarios(capitalChoiceScenarios(), runRunnableScenario);
  });
}
