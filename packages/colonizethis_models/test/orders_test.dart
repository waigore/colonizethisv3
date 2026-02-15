import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:test/test.dart';

void main() {
  group('Orders', () {
    test('toJson/fromJson round-trip empty', () {
      const o = Orders();
      final o2 = Orders.fromJson(o.toJson());
      expect(o2.byPlayerId, isEmpty);
    });
    test('toJson/fromJson round-trip with data', () {
      const o = Orders(byPlayerId: {'p1': {'move': 'prov1'}});
      final o2 = Orders.fromJson(o.toJson());
      expect(o2.byPlayerId['p1'], {'move': 'prov1'});
    });
    test('equality', () {
      const a = Orders(byPlayerId: {'p1': {}});
      const b = Orders(byPlayerId: {'p1': {}});
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
    test('fromJson with null or missing byPlayerId', () {
      final o = Orders.fromJson({});
      expect(o.byPlayerId, isEmpty);
      final o2 = Orders.fromJson({'byPlayerId': null});
      expect(o2.byPlayerId, isEmpty);
    });
    test('equality false when different', () {
      const a = Orders(byPlayerId: {'p1': {}});
      const b = Orders(byPlayerId: {'p2': {}});
      expect(a == b, false);
      expect(a == Object(), false);
    });
  });
}
