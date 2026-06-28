import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('Province', () {
    test('toJson/fromJson round-trip with owner', () {
      const p = Province(
        id: 'oldWorld|prov1',
        regionId: 'oldWorld',
        ownerId: 'p1',
      );
      final json = p.toJson();
      final p2 = Province.fromJson(json);
      expect(p2.id, 'oldWorld|prov1');
      expect(p2.regionId, 'oldWorld');
      expect(p2.ownerId, 'p1');
    });
    test('toJson/fromJson round-trip without owner', () {
      const p = Province(
        id: 'newWorld|prov2',
        regionId: 'newWorld',
        ownerId: null,
      );
      final p2 = Province.fromJson(p.toJson());
      expect(p2.ownerId, null);
    });
    test('equality', () {
      const a = Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'x');
      const b = Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'x');
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
    test('fortLevel and terrain round-trip', () {
      const p = Province(
        id: 'oldWorld|p1',
        regionId: 'oldWorld',
        fortLevel: 2,
        terrain: 'hardwoodForest',
      );
      final p2 = Province.fromJson(p.toJson());
      expect(p2.fortLevel, 2);
      expect(p2.terrain, 'hardwoodForest');
    });
    test('fortLevel defaults 0, terrain defaults plains', () {
      final p = Province.fromJson({
        'id': 'oldWorld|p1',
        'regionId': 'oldWorld',
      });
      expect(p.fortLevel, 0);
      expect(p.terrain, 'plains');
    });
    test('equality false when different', () {
      const a = Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'x');
      const b = Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'x');
      expect(a == b, false);
      expect(a == Object(), false);
    });

    test('fromJson throws for unprefixed province id', () {
      expect(
        () => Province.fromJson({'id': 'p1', 'regionId': 'oldWorld'}),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
