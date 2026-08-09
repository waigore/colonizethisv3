import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/test.dart';

// --- Slice C runners (Refs #4108) ---
// dart format off
void runAddUnitsExpectation(AddUnitsPins pins) {
  final m = Map<String, int>.from(pins.initial);
  for (final step in pins.steps) {
    addUnits(m, step.key, step.delta);
  }
  expect(m, pins.expected);
  if (pins.keyOrder != null) {
    expect(m.keys.toList(), pins.keyOrder);
  }
}

void runSumValuesExpectation(SumValuesPins pins) {
  for (final caseRow in pins.cases) {
    expect(sumValues(caseRow.values), caseRow.expected);
  }
}

void runSumNestedValuesExpectation(SumNestedValuesPins pins) {
  expect(sumNestedValues(pins.maps), pins.expected);
}

void runAddUnitsScenario(AddUnitsScenario scenario) {
  runAddUnitsExpectation(scenario.pins);
}

void runSumValuesScenario(SumValuesScenario scenario) {
  runSumValuesExpectation(scenario.pins);
}

void runSumNestedValuesScenario(SumNestedValuesScenario scenario) {
  runSumNestedValuesExpectation(scenario.pins);
}
// dart format on

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
