import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_map/src/tile_map_province_budget.dart';

void main() {
  group('allocateBudgetByProvinceCount', () {
    test('splits proportionally and applies remainder to continent 0', () {
      final provincesByContinent = {
        0: ['a', 'b'],
        1: ['c'],
      };
      final budget = allocateBudgetByProvinceCount(
        totalBudget: 10,
        provincesByContinent: provincesByContinent,
        numContinents: 2,
      );
      expect(budget.reduce((a, b) => a + b), 10);
      expect(budget[0], greaterThan(budget[1]));
    });

    test('returns zeros when no provinces', () {
      final budget = allocateBudgetByProvinceCount(
        totalBudget: 100,
        provincesByContinent: const {},
        numContinents: 3,
      );
      expect(budget, [0, 0, 0]);
    });
  });
}
