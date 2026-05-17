import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('riches prices', () {
    test('riches commodity ids are stable and complete', () {
      expect(richesCommodityIds, const [
        'spices',
        'silver',
        'gold',
        'gems',
        'diamonds',
      ]);
    });

    test('richesBasePrice returns expected values for riches', () {
      expect(richesBasePrice('spices'), 50);
      expect(richesBasePrice('silver'), 100);
      expect(richesBasePrice('gold'), 166);
      expect(richesBasePrice('gems'), 250);
      expect(richesBasePrice('diamonds'), 500);
    });

    test('richesBasePrice returns zero for non-riches ids', () {
      expect(richesBasePrice('grain'), 0);
      expect(richesBasePrice('unknown'), 0);
    });

    test('land purchase prices use riches when available', () {
      expect(landPurchaseBasePrice('spices'), 50);
      expect(purchaseLandCost('spices'), 750);
      expect(landPurchaseBasePrice('diamonds'), 500);
      expect(purchaseLandCost('diamonds'), 7500);
    });

    test('land purchase prices fall back to default for non-riches', () {
      expect(landPurchaseBasePrice('grain'), landPurchaseDefaultBasePrice);
      expect(landPurchaseBasePrice('unknown'), landPurchaseDefaultBasePrice);
      expect(purchaseLandCost('grain'), 15 * landPurchaseDefaultBasePrice);
    });
  });
}
