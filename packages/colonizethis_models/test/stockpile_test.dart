import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('Stockpile', () {
    test('quantityOf returns 0 when absent', () {
      const s = Stockpile();
      expect(s.quantityOf('grain'), 0);
    });

    test('copyQuantities returns an equal snapshot of quantities', () {
      const s = Stockpile(quantities: {'grain': 5, 'iron': 2});
      final copy = s.copyQuantities();
      expect(copy, {'grain': 5, 'iron': 2});
    });

    test('copyQuantities returns a mutable map detached from the source', () {
      const s = Stockpile(quantities: {'grain': 5});
      final copy = s.copyQuantities();
      copy['grain'] = 1;
      copy['iron'] = 9;
      expect(s.quantityOf('grain'), 5, reason: 'source stays unchanged');
      expect(s.quantities.containsKey('iron'), isFalse);
      expect(copy, {'grain': 1, 'iron': 9});
    });

    test('applyDelta adds and deducts quantities with clamping', () {
      const s = Stockpile();
      final s2 = s.applyDelta('grain', 5);
      expect(s2.quantityOf('grain'), 5);

      final s3 = s2.applyDelta('grain', -3);
      expect(s3.quantityOf('grain'), 2);

      final s4 = s3.applyDelta('grain', -10);
      expect(s4.quantityOf('grain'), 0);
    });

    test('applyDelta has no upper cap on quantity (strategic stockpile)', () {
      const s = Stockpile();
      const large = 2000000;
      final s2 = s.applyDelta('iron', large);
      expect(s2.quantityOf('iron'), large);
      final s3 = s2.applyDelta('iron', 1);
      expect(s3.quantityOf('iron'), large + 1);
    });

    test('merge sums quantities', () {
      final a = const Stockpile().applyDelta('grain', 2);
      final b = const Stockpile().applyDelta('grain', 3).applyDelta('iron', 1);
      final merged = a.merge(b);
      expect(merged.quantityOf('grain'), 5);
      expect(merged.quantityOf('iron'), 1);
    });

    test('toJson/fromJson round-trip', () {
      final s = const Stockpile().applyDelta('grain', 4).applyDelta('iron', 1);
      final json = s.toJson();
      final s2 = Stockpile.fromJson(json);
      expect(s2.quantityOf('grain'), 4);
      expect(s2.quantityOf('iron'), 1);
      expect(s2, s);
      expect(s2.hashCode, s.hashCode);
    });

    test('fromJson tolerates bad input', () {
      final s = Stockpile.fromJson({'quantities': {'grain': '3', 'iron': 'x'}});
      expect(s.quantityOf('grain'), 3);
      expect(s.quantityOf('iron'), 0);
    });
  });
}

