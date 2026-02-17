import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:test/test.dart';

void main() {
  group('SeaTransport', () {
    test('cargo cap limits delivered overseas', () {
      final overseas = {'grain': 5, 'timber': 8, 'iron': 4};
      final delivered = allocateOverseasToStockpile(
        overseas,
        cargoHolds: 10,
      );
      final total = delivered.values.fold<int>(0, (a, b) => a + b);
      expect(total, lessThanOrEqualTo(10));
      expect(total, 10);
    });

    test('priority order: food before raw materials', () {
      final overseas = {'iron': 20, 'grain': 5};
      final delivered = allocateOverseasToStockpile(
        overseas,
        cargoHolds: 6,
      );
      expect(delivered['grain'], 5);
      expect(delivered['iron'], 1);
    });
  });
}
