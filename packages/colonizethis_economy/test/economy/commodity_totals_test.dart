import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('addUnits', () {
    runLabeledScenarios(addUnitsScenarios(), (scenario) {
      runAddUnitsScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('sumValues', () {
    runLabeledScenarios(sumValuesScenarios(), (scenario) {
      runSumValuesScenario(scenario);
    }, labelOf: (s) => s.label);
  });

  group('sumNestedValues', () {
    runLabeledScenarios(sumNestedValuesScenarios(), (scenario) {
      runSumNestedValuesScenario(scenario);
    }, labelOf: (s) => s.label);
  });
}
