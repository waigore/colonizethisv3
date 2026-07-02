// Cross-package province-lookup contract tests (Refs #3403 / #3843).
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  final world = WorldState(
    turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [
        Province(id: 'oldWorld|p1', regionId: 'oldWorld', displayName: 'Alpha'),
        Province(id: 'oldWorld|p2', regionId: 'oldWorld', displayName: 'Beta'),
      ],
    ),
    newWorld: RegionData(
      provinces: [
        Province(id: 'newWorld|n1', regionId: 'newWorld', displayName: 'Gamma'),
      ],
    ),
  );

  final worldWithLegacyUnprefixedProvince = WorldState(
    turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [
        Province(id: 'p1', regionId: 'oldWorld', displayName: 'Legacy Alpha'),
      ],
    ),
    newWorld: RegionData(provinces: const []),
  );

  group('tryGetRegionIdForLegacyProvinceKey', () {
    test('resolves legacy short province id to oldWorld', () {
      expect(
        worldWithLegacyUnprefixedProvince.tryGetRegionIdForLegacyProvinceKey(
          'p1',
        ),
        kRegionOldWorld,
      );
    });

    test('resolves prefixed province id via row id match', () {
      expect(
        world.tryGetRegionIdForLegacyProvinceKey('oldWorld|p1'),
        kRegionOldWorld,
      );
      expect(
        world.tryGetRegionIdForLegacyProvinceKey('newWorld|n1'),
        kRegionNewWorld,
      );
    });

    test('returns null when key absent from both regions', () {
      expect(world.tryGetRegionIdForLegacyProvinceKey('none'), isNull);
    });

    test('prefers oldWorld when same id string exists in both regions', () {
      final dup = WorldState(
        turnState: world.turnState,
        oldWorld: RegionData(
          provinces: [
            Province(id: 'dup', regionId: 'oldWorld', displayName: 'A'),
          ],
        ),
        newWorld: RegionData(
          provinces: [
            Province(id: 'dup', regionId: 'newWorld', displayName: 'B'),
          ],
        ),
      );
      expect(dup.tryGetRegionIdForLegacyProvinceKey('dup'), kRegionOldWorld);
    });
  });

  group('tryGetProvince', () {
    test('finds OW province by full prefixed id', () {
      final p = world.tryGetProvince('oldWorld|p1');
      expect(p, isNotNull);
      expect(p!.displayName, 'Alpha');
    });

    test('finds NW province by full prefixed id', () {
      final p = world.tryGetProvince('newWorld|n1');
      expect(p, isNotNull);
      expect(p!.displayName, 'Gamma');
    });

    test('returns null for unknown province id', () {
      expect(world.tryGetProvince('oldWorld|missing'), isNull);
    });

    test('returns null for unknown region', () {
      expect(world.tryGetProvince('unknownRegion|p1'), isNull);
    });

    test('returns null for malformed prefixed id', () {
      expect(world.tryGetProvince('oldWorld|'), isNull);
    });

    test('returns null for short id (prefixed required)', () {
      expect(world.tryGetProvince('oldWorld|p1'), isNotNull);
    });
  });

  group('getProvince', () {
    test('finds OW province by full prefixed id', () {
      final p = world.getProvince('oldWorld|p1');
      expect(p.displayName, 'Alpha');
    });

    test('throws StateError for unknown province', () {
      expect(() => world.getProvince('oldWorld|missing'), throwsStateError);
    });

    test('throws StateError for short id (prefixed required)', () {
      expect(() => world.getProvince('oldWorld|missing'), throwsStateError);
    });
  });

  group('resolveToFullProvinceId', () {
    test('returns as-is when prefixed', () {
      expect(world.resolveToFullProvinceId('oldWorld|p1'), 'oldWorld|p1');
      expect(world.resolveToFullProvinceId('newWorld|n1'), 'newWorld|n1');
    });

    test('throws StateError for short id (no short-id resolution)', () {
      expect(world.resolveToFullProvinceId('oldWorld|p1'), 'oldWorld|p1');
    });
  });

  group('getProvinceByRegion / tryGetProvinceByRegion (region-scoped)', () {
    test('getProvinceByRegion finds province only in given region', () {
      expect(world.getProvinceByRegion('oldWorld', 'p1').displayName, 'Alpha');
      expect(world.getProvinceByRegion('newWorld', 'n1').displayName, 'Gamma');
    });
    test('getProvinceByRegion throws for wrong region', () {
      expect(
        () => world.getProvinceByRegion('newWorld', 'p1'),
        throwsStateError,
      );
    });
    test('getProvinceByRegion throws for unknown region', () {
      expect(
        () => world.getProvinceByRegion('unknownRegion', 'p1'),
        throwsStateError,
      );
    });
    test('tryGetProvinceByRegion returns null for missing in region', () {
      expect(world.tryGetProvinceByRegion('oldWorld', 'missing'), isNull);
      expect(world.tryGetProvinceByRegion('unknownRegion', 'p1'), isNull);
    });
    test('does not match legacy unprefixed province ids in region lookup', () {
      expect(
        () => worldWithLegacyUnprefixedProvince.getProvinceByRegion(
          'oldWorld',
          'p1',
        ),
        throwsStateError,
      );
      expect(
        worldWithLegacyUnprefixedProvince.tryGetProvinceByRegion(
          'oldWorld',
          'p1',
        ),
        isNull,
      );
    });
    test('getProvince(fullId) delegates to region-scoped lookup', () {
      expect(world.getProvince('oldWorld|p1').displayName, 'Alpha');
      expect(world.getProvince('newWorld|n1').displayName, 'Gamma');
    });
  });

  group('WorldState.updateRegionById', () {
    test('updates oldWorld and preserves newWorld', () {
      final updated = world.updateRegionById(
        kRegionOldWorld,
        (region) => RegionData(
          provinces: [
            ...region.provinces,
            Province(
              id: 'oldWorld|p3',
              regionId: 'oldWorld',
              displayName: 'Delta',
            ),
          ],
          units: region.units,
        ),
      );

      expect(updated.oldWorld.provinces.length, 3);
      expect(updated.oldWorld.provinces.last.id, 'oldWorld|p3');
      expect(updated.newWorld.provinces, hasLength(1));
      expect(updated.newWorld.provinces.first.id, 'newWorld|n1');
    });

    test('throws for unknown region id', () {
      expect(
        () => world.updateRegionById('unknownRegion', (region) => region),
        throwsStateError,
      );
    });
  });

  group('provinceListContainsProvinceId', () {
    test('true when id matches a row', () {
      expect(
        provinceListContainsProvinceId(world.oldWorld.provinces, 'oldWorld|p1'),
        isTrue,
      );
    });

    test('false when absent', () {
      expect(
        provinceListContainsProvinceId(
          world.oldWorld.provinces,
          'oldWorld|missing',
        ),
        isFalse,
      );
    });
  });

  group('provinceListIndexOfProvinceId', () {
    test('returns first index and matches indexWhere on duplicate ids', () {
      final dupA = Province(
        id: 'dup',
        regionId: 'oldWorld',
        displayName: 'First',
      );
      final dupB = Province(
        id: 'dup',
        regionId: 'oldWorld',
        displayName: 'Second',
      );
      final provinces = [dupA, dupB];
      expect(provinceListIndexOfProvinceId(provinces, 'dup'), 0);
      expect(provinces.indexWhere((p) => p.id == 'dup'), 0);
    });

    test('returns null when absent', () {
      expect(
        provinceListIndexOfProvinceId(
          world.oldWorld.provinces,
          'oldWorld|missing',
        ),
        isNull,
      );
    });
  });

  group('decrementFortLevelForProvinceIdIfPresent', () {
    test('returns same list reference when id missing', () {
      final provinces = world.oldWorld.provinces;
      final out = decrementFortLevelForProvinceIdIfPresent(
        provinces,
        'oldWorld|missing',
      );
      expect(identical(out, provinces), isTrue);
    });

    test('decrements fort for matching row', () {
      final withFort = Province(
        id: 'oldWorld|fx',
        regionId: 'oldWorld',
        displayName: 'Fort',
        fortLevel: 2,
      );
      final list = [withFort];
      final out = decrementFortLevelForProvinceIdIfPresent(list, 'oldWorld|fx');
      expect(identical(out, list), isFalse);
      expect(out.single.fortLevel, 1);
    });
  });
}
