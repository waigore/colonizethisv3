import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'checkPreconditionsInOrder (Refs #3517 Cluster 2)',
    checkPreconditionsInOrderScenarios(),
    runCheckPreconditionsInOrderScenario,
    labelOf: (s) => s.label,
  );
}
