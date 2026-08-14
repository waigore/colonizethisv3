// Densified via scenario table (Refs #4349 Slice C).
import 'package:colonizethis_test/test.dart';

import 'support/province_assignment_scenarios.dart'
    show provinceAssignmentScenarios;
import 'support/scenario_runner.dart';

void main() {
  group('Province assignment', () {
    runLabeledScenarios(provinceAssignmentScenarios(), runRunnableScenario);
  });
}
