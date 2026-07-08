// Table-driven commodity totals helper scenarios (Refs #3939 phase 3 slice 21).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

class CommodityTotalsScenario {
  const CommodityTotalsScenario({
    required this.label,
    required this.run,
  });

  final String label;
  final void Function() run;
}

void runCommodityTotalsScenario(CommodityTotalsScenario scenario) {
  scenario.run();
}

List<CommodityTotalsScenario> addUnitsScenarios() => [
  CommodityTotalsScenario(
    label: 'creates a new entry starting from zero',
    run: () {
      final m = <String, int>{};
      addUnits(m, 'a', 3);
      expect(m, {'a': 3});
    },
  ),
  CommodityTotalsScenario(
    label: 'accumulates onto an existing entry',
    run: () {
      final m = <String, int>{'a': 3};
      addUnits(m, 'a', 4);
      expect(m['a'], 7);
    },
  ),
  CommodityTotalsScenario(
    label: 'preserves first-seen insertion order across keys',
    run: () {
      final m = <String, int>{};
      addUnits(m, 'b', 1);
      addUnits(m, 'a', 1);
      addUnits(m, 'b', 1);
      expect(m.keys.toList(), ['b', 'a']);
      expect(m, {'b': 2, 'a': 1});
    },
  ),
  CommodityTotalsScenario(
    label: 'does not filter zero or negative deltas (caller guards)',
    run: () {
      final m = <String, int>{'a': 5};
      addUnits(m, 'a', 0);
      addUnits(m, 'a', -2);
      addUnits(m, 'z', -1);
      expect(m, {'a': 3, 'z': -1});
    },
  ),
];

List<CommodityTotalsScenario> sumValuesScenarios() => [
  CommodityTotalsScenario(
    label: 'returns 0 for an empty iterable',
    run: () {
      expect(sumValues(const <int>[]), 0);
    },
  ),
  CommodityTotalsScenario(
    label: 'sums positive and negative values',
    run: () {
      expect(sumValues(const [1, 2, 3]), 6);
      expect(sumValues(const [5, -2, -1]), 2);
    },
  ),
  CommodityTotalsScenario(
    label: 'matches the inline fold idiom it replaces',
    run: () {
      const values = [4, 8, 15, 16, 23, 42];
      expect(sumValues(values), values.fold<int>(0, (a, b) => a + b));
    },
  ),
];

List<CommodityTotalsScenario> sumNestedValuesScenarios() => [
  CommodityTotalsScenario(
    label: 'returns 0 for no maps and for empty maps',
    run: () {
      expect(sumNestedValues(const <Map<String, int>>[]), 0);
      expect(sumNestedValues(const [<String, int>{}, <String, int>{}]), 0);
    },
  ),
  CommodityTotalsScenario(
    label: 'sums every value across nested maps',
    run: () {
      final maps = [
        {'a': 1, 'b': 2},
        {'a': 3},
        <String, int>{},
        {'c': 4},
      ];
      expect(sumNestedValues(maps), 10);
    },
  ),
];
