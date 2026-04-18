import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('regimentTransferBucketKey', () {
    test('uses unit type when present', () {
      final u = Unit(
        id: 'r1',
        type: 'peasant_levy',
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|x',
      );
      expect(regimentTransferBucketKey(u, 'r1'), 'peasant_levy');
    });

    test('falls back to unit id when unit is null', () {
      expect(regimentTransferBucketKey(null, 'ghost'), 'ghost');
    });
  });

  group('regimentUnitIdsForTransferCounts', () {
    final units = <Unit>[
      Unit(
        id: 'a',
        type: 'peasant_levy',
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|x',
      ),
      Unit(
        id: 'b',
        type: 'peasant_levy',
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|x',
      ),
      Unit(
        id: 'c',
        type: 'peasant_levy',
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|x',
      ),
      Unit(
        id: 'd',
        type: 'musketeer',
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|x',
      ),
    ];
    Unit? tryUnit(String id) {
      for (final u in units) {
        if (u.id == id) return u;
      }
      return null;
    }

    test('takes first N per type in regiment order', () {
      const order = ['a', 'b', 'c', 'd'];
      final moved = regimentUnitIdsForTransferCounts(order, tryUnit, {
        'peasant_levy': 2,
        'musketeer': 1,
      });
      expect(moved, ['a', 'b', 'd']);
    });

    test('returns empty when need map is empty or all zero', () {
      expect(regimentUnitIdsForTransferCounts(['a'], tryUnit, {}), isEmpty);
      expect(
        regimentUnitIdsForTransferCounts(['a'], tryUnit, {'peasant_levy': 0}),
        isEmpty,
      );
    });

    test('unknown regiment id uses id as bucket', () {
      final moved = regimentUnitIdsForTransferCounts(
        ['a', 'missing', 'b'],
        tryUnit,
        {'peasant_levy': 1, 'missing': 1},
      );
      expect(moved, ['a', 'missing']);
    });
  });
}
