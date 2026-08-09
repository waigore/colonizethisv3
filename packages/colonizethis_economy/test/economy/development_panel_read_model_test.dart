import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  suppressLogsForTests();

  runLabeledScenarioGroup(
    'buildDevelopmentPanelModel (Refs #4175)',
    developmentPanelReadModelScenarios(),
    runDevelopmentPanelReadModelScenario,
    labelOf: (scenario) => scenario.label,
  );
}
