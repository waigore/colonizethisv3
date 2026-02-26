import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('Stockpile', () {
    test('quantityOf returns 0 when absent', () {
      const s = Stockpile();
      expect(s.quantityOf('grain'), 0);
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

