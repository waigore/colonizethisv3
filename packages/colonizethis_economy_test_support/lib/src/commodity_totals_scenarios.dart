// Table-driven commodity totals helper scenarios (Refs #3939 phase 3 slice 21).

import 'commodity_totals_expectations.dart';

/// One row for commodity-totals helper tables (Refs #3939 slice 63).
typedef CommodityTotalsScenario = ({String label, void Function() run});

void runCommodityTotalsScenario(CommodityTotalsScenario scenario) {
  scenario.run();
}

List<CommodityTotalsScenario> addUnitsScenarios() => [
  addUnitsScenario(
    label: 'creates a new entry starting from zero',
    pins: (
      initial: <String, int>{},
      steps: [(key: 'a', delta: 3)],
      expected: {'a': 3},
      keyOrder: null,
    ),
  ),
  addUnitsScenario(
    label: 'accumulates onto an existing entry',
    pins: (
      initial: {'a': 3},
      steps: [(key: 'a', delta: 4)],
      expected: {'a': 7},
      keyOrder: null,
    ),
  ),
  addUnitsScenario(
    label: 'preserves first-seen insertion order across keys',
    pins: (
      initial: <String, int>{},
      steps: [(key: 'b', delta: 1), (key: 'a', delta: 1), (key: 'b', delta: 1)],
      expected: {'b': 2, 'a': 1},
      keyOrder: ['b', 'a'],
    ),
  ),
  addUnitsScenario(
    label: 'does not filter zero or negative deltas (caller guards)',
    pins: (
      initial: {'a': 5},
      steps: [
        (key: 'a', delta: 0),
        (key: 'a', delta: -2),
        (key: 'z', delta: -1),
      ],
      expected: {'a': 3, 'z': -1},
      keyOrder: null,
    ),
  ),
];

List<CommodityTotalsScenario> sumValuesScenarios() => [
  sumValuesScenario(
    label: 'returns 0 for an empty iterable',
    pins: (cases: [(values: <int>[], expected: 0)]),
  ),
  sumValuesScenario(
    label: 'sums positive and negative values',
    pins: (
      cases: [
        (values: [1, 2, 3], expected: 6),
        (values: [5, -2, -1], expected: 2),
      ],
    ),
  ),
  sumValuesScenario(
    label: 'matches the inline fold idiom it replaces',
    pins: (
      cases: [
        (values: [4, 8, 15, 16, 23, 42], expected: 108),
      ],
    ),
  ),
];

List<CommodityTotalsScenario> sumNestedValuesScenarios() => [
  sumNestedValuesScenario(
    label: 'returns 0 for no maps and for empty maps',
    pins: (maps: const [<String, int>{}, <String, int>{}], expected: 0),
  ),
  sumNestedValuesScenario(
    label: 'sums every value across nested maps',
    pins: (
      maps: [
        {'a': 1, 'b': 2},
        {'a': 3},
        <String, int>{},
        {'c': 4},
      ],
      expected: 10,
    ),
  ),
];
