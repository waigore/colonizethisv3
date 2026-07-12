import 'package:colonizethis_combat_test_support/colonizethis_combat_test_support.dart';

void main() {
  runLabeledScenarioGroup(
    'aggregateActionModifiers',
    aggregateActionModifiersScenarios(),
    (s) => s.run(),
  );
}
