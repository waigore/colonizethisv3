import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:test/test.dart';

void main() {
  group('Unit', () {
    test('toJson/fromJson round-trip', () {
      const u = Unit(id: 'u1', type: 'infantry', ownerId: 'p1', provinceId: 'prov1');
      final u2 = Unit.fromJson(u.toJson());
      expect(u2.id, 'u1');
      expect(u2.type, 'infantry');
      expect(u2.ownerId, 'p1');
      expect(u2.provinceId, 'prov1');
    });
    test('equality', () {
      const a = Unit(id: 'u1', type: 'inf', ownerId: 'p1', provinceId: 'prov1');
      const b = Unit(id: 'u1', type: 'inf', ownerId: 'p1', provinceId: 'prov1');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
    test('equality false when different', () {
      const a = Unit(id: 'u1', type: 'inf', ownerId: 'p1', provinceId: 'prov1');
      const b = Unit(id: 'u2', type: 'inf', ownerId: 'p1', provinceId: 'prov1');
      expect(a == b, false);
      expect(a == Object(), false);
    });
  });
}
