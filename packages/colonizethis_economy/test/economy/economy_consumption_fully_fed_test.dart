import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('fullyFedCountFromConsumed', () {
    test('returns zero when demand or count is non-positive', () {
      expect(
        fullyFedCountFromConsumed(consumed: 4, totalDemand: 0, count: 2),
        0,
      );
      expect(
        fullyFedCountFromConsumed(consumed: 4, totalDemand: 4, count: 0),
        0,
      );
    });

    test('clamps fed count to unit count', () {
      expect(
        fullyFedCountFromConsumed(consumed: 100, totalDemand: 6, count: 3),
        3,
      );
    });
  });
}
