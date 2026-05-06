import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('Unit', () {
    test('toJson/fromJson round-trip', () {
      final u = Unit(
        id: 'u1',
        type: 'infantry',
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|prov1',
        status: UnitStatus.working,
        medals: 2,
        originTileKey: 'oldWorld|p1|0|0',
        assignedTileKey: 'oldWorld|p1|1|0',
      );
      final u2 = Unit.fromJson(u.toJson());
      expect(u2.id, 'u1');
      expect(u2.type, 'infantry');
      expect(u2.ownerId, 'p1');
      expect(u2.locationProvinceId, 'oldWorld|prov1');
      expect(u2.status, UnitStatus.working);
      expect(u2.medals, 2);
      expect(u2.originTileKey, 'oldWorld|p1|0|0');
      expect(u2.assignedTileKey, 'oldWorld|p1|1|0');
    });
    test('equality', () {
      final a = Unit(
        id: 'u1',
        type: 'inf',
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|prov1',
      );
      final b = Unit(
        id: 'u1',
        type: 'inf',
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|prov1',
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });
    test('medals default 0 when omitted from JSON', () {
      final u = Unit.fromJson({
        'id': 'u1',
        'type': 'infantry',
        'ownerId': 'p1',
        'provinceId': 'oldWorld|prov1',
      });
      expect(u.medals, 0);
    });
    test('equality false when different', () {
      final a = Unit(
        id: 'u1',
        type: 'inf',
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|prov1',
      );
      final b = Unit(
        id: 'u2',
        type: 'inf',
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|prov1',
      );
      expect(a == b, false);
      expect(a == Object(), false);
    });
    test('fromJson normalizes stale provinceId when tileKey present', () {
      final u = Unit.fromJson({
        'id': 'u1',
        'type': kUnitTypeExplorer,
        'ownerId': 'p1',
        'provinceId': 'oldWorld|wrong',
        'tileKey': 'oldWorld|right|0|0',
      });
      expect(u.locationProvinceId, 'oldWorld|right');
      expect(u.toJson()['provinceId'], 'oldWorld|right');
    });

    test('fromJson throws for unprefixed provinceId', () {
      expect(
        () => Unit.fromJson({
          'id': 'u1',
          'type': 'infantry',
          'ownerId': 'p1',
          'provinceId': 'prov1',
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('provinceIdFromTileKey returns full id for 4-part key only', () {
      expect(Unit.provinceIdFromTileKey('oldWorld|p1|0|0'), 'oldWorld|p1');
      expect(Unit.provinceIdFromTileKey('oldWorld|p1|0'), isNull);
      expect(Unit.provinceIdFromTileKey('p1|0|0'), isNull);
      expect(Unit.provinceIdFromTileKey(null), isNull);
    });
  });
}
