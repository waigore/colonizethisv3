// dart format off
// Table-driven commodity totals helper scenarios (Refs #3939 phase 3 slice 21, #3979).

/// One [addUnits] mutation step.
typedef AddUnitsStep = ({String key, int delta});

/// Pins for [addUnits] rows.
typedef AddUnitsPins = ({Map<String, int> initial, List<AddUnitsStep> steps, Map<String, int> expected, List<String>? keyOrder});

/// One row for [addUnits] tables (Refs #3979).
typedef AddUnitsScenario = ({String label, AddUnitsPins pins});

AddUnitsScenario addUnitsScenario({required String label, required AddUnitsPins pins}) => (label: label, pins: pins);

/// One [sumValues] assertion case.
typedef SumValuesCase = ({List<int> values, int expected});

/// Pins for [sumValues] rows.
typedef SumValuesPins = ({List<SumValuesCase> cases});

/// One row for [sumValues] tables (Refs #3979).
typedef SumValuesScenario = ({String label, SumValuesPins pins});

SumValuesScenario sumValuesScenario({required String label, required SumValuesPins pins}) => (label: label, pins: pins);

/// Pins for [sumNestedValues] rows.
typedef SumNestedValuesPins = ({List<Map<String, int>> maps, int expected});

/// One row for [sumNestedValues] tables (Refs #3979).
typedef SumNestedValuesScenario = ({String label, SumNestedValuesPins pins});

SumNestedValuesScenario sumNestedValuesScenario({required String label, required SumNestedValuesPins pins}) =>
    (label: label, pins: pins);

List<AddUnitsScenario> addUnitsScenarios() => [
  addUnitsScenario(label: 'creates a new entry starting from zero', pins: (initial: <String, int>{}, steps: [(key: 'a', delta: 3)], expected: {'a': 3}, keyOrder: null)),
  addUnitsScenario(label: 'accumulates onto an existing entry', pins: (initial: {'a': 3}, steps: [(key: 'a', delta: 4)], expected: {'a': 7}, keyOrder: null)),
  addUnitsScenario(label: 'preserves first-seen insertion order across keys', pins: (initial: <String, int>{}, steps: [(key: 'b', delta: 1), (key: 'a', delta: 1), (key: 'b', delta: 1)], expected: {'b': 2, 'a': 1}, keyOrder: ['b', 'a'])),
  addUnitsScenario(label: 'does not filter zero or negative deltas (caller guards)', pins: (initial: {'a': 5}, steps: [(key: 'a', delta: 0), (key: 'a', delta: -2), (key: 'z', delta: -1)], expected: {'a': 3, 'z': -1}, keyOrder: null)),
];

List<SumValuesScenario> sumValuesScenarios() => [
  sumValuesScenario(label: 'returns 0 for an empty iterable', pins: (cases: [(values: <int>[], expected: 0)])),
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

List<SumNestedValuesScenario> sumNestedValuesScenarios() => [
  sumNestedValuesScenario(label: 'returns 0 for no maps and for empty maps', pins: (maps: const [<String, int>{}, <String, int>{}], expected: 0)),
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
// dart format on
