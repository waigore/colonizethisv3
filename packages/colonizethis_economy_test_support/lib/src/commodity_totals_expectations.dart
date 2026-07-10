// Compact commodity totals helper assertions (Refs #3939 phase 3 slice 33).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

import 'commodity_totals_scenarios.dart';

/// One [addUnits] mutation step.
typedef AddUnitsStep = ({String key, int delta});

/// Pins for [addUnits] rows.
typedef AddUnitsPins = ({
  Map<String, int> initial,
  List<AddUnitsStep> steps,
  Map<String, int> expected,
  List<String>? keyOrder,
});

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

CommodityTotalsScenario addUnitsScenario({
  required String label,
  required AddUnitsPins pins,
}) => CommodityTotalsScenario(
  label: label,
  run: () => runAddUnitsExpectation(pins),
);

/// One [sumValues] assertion case.
typedef SumValuesCase = ({List<int> values, int expected});

/// Pins for [sumValues] rows.
typedef SumValuesPins = ({List<SumValuesCase> cases});

void runSumValuesExpectation(SumValuesPins pins) {
  for (final caseRow in pins.cases) {
    expect(sumValues(caseRow.values), caseRow.expected);
  }
}

CommodityTotalsScenario sumValuesScenario({
  required String label,
  required SumValuesPins pins,
}) => CommodityTotalsScenario(
  label: label,
  run: () => runSumValuesExpectation(pins),
);

/// Pins for [sumNestedValues] rows.
typedef SumNestedValuesPins = ({List<Map<String, int>> maps, int expected});

void runSumNestedValuesExpectation(SumNestedValuesPins pins) {
  expect(sumNestedValues(pins.maps), pins.expected);
}

CommodityTotalsScenario sumNestedValuesScenario({
  required String label,
  required SumNestedValuesPins pins,
}) => CommodityTotalsScenario(
  label: label,
  run: () => runSumNestedValuesExpectation(pins),
);
