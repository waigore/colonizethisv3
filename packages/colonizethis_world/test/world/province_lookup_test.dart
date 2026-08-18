// ignore_for_file: deprecated_member_use

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

import '../world_test_support/province_lookup_test_support.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

void main() {
  group('province-list helpers', () {
    const provinces = [
      Province(id: 'oldWorld|p1', regionId: 'oldWorld', fortLevel: 2),
      Province(id: 'oldWorld|p2', regionId: 'oldWorld', fortLevel: 0),
    ];

    test('provinceListContainsProvinceId', () {
      expect(provinceListContainsProvinceId(provinces, 'oldWorld|p1'), isTrue);
      expect(provinceListContainsProvinceId(provinces, 'oldWorld|x'), isFalse);
    });

    test('decrementFortLevelForProvinceIdIfPresent decrements and clamps', () {
      final next = decrementFortLevelForProvinceIdIfPresent(
        provinces,
        'oldWorld|p1',
      );
      expect(next.firstWhere((p) => p.id == 'oldWorld|p1').fortLevel, 1);
      final clamped = decrementFortLevelForProvinceIdIfPresent(
        provinces,
        'oldWorld|p2',
      );
      expect(clamped.firstWhere((p) => p.id == 'oldWorld|p2').fortLevel, 0);
    });

    test(
      'decrementFortLevelForProvinceIdIfPresent returns same list if absent',
      () {
        expect(
          decrementFortLevelForProvinceIdIfPresent(
            provinces,
            'oldWorld|missing',
          ),
          same(provinces),
        );
      },
    );
  });

  group('province key resolution helpers', () {
    final world = provinceLookupTestWorld();

    test('resolveToFullProvinceId returns prefixed, throws on short id', () {
      expect(resolveToFullProvinceId(world, 'oldWorld|p1'), 'oldWorld|p1');
      const shortId = 'p1';
      expect(() => resolveToFullProvinceId(world, shortId), throwsStateError);
    });

    test('resolveProvinceRowForOwnershipTransfer matches legacy short id', () {
      final legacyWorld = TestFixtures.worldStateAtOrdersPhase(
        oldWorld: const RegionData(
          provinces: [Province(id: 'shortId', regionId: 'oldWorld')],
        ),
      );
      expect(
        resolveProvinceRowForOwnershipTransfer(
          legacyWorld,
          'shortId',
        )!.canonicalProvinceId,
        'shortId',
      );
      expect(
        resolveProvinceRowForOwnershipTransfer(legacyWorld, 'nope'),
        isNull,
      );
    });

    test(
      'landTileKeysForProvinceBucket returns a mutable copy of bucket keys',
      () {
        final keys = landTileKeysForProvinceBucket(
          world,
          'oldWorld',
          'oldWorld|p1',
        );
        expect(keys, ['oldWorld|p1|0|0', 'oldWorld|p1|1|0']);
        keys.add('mutation');
        expect(
          landTileKeysForProvinceBucket(world, 'oldWorld', 'oldWorld|p1'),
          ['oldWorld|p1|0|0', 'oldWorld|p1|1|0'],
        );
        expect(
          landTileKeysForProvinceBucket(world, 'oldWorld', 'oldWorld|p2'),
          isEmpty,
        );
      },
    );

    test('landTileKeysForProvinceBucket is strict full-id only by default', () {
      expect(
        landTileKeysForProvinceBucket(
          provinceLookupLegacyLocalIdBucketWorld(),
          'oldWorld',
          'oldWorld|p1',
        ),
        isEmpty,
      );
    });

    test(
      'landTileKeysForProvinceBucket opt-in fallback resolves local-id bucket',
      () {
        expect(
          landTileKeysForProvinceBucket(
            provinceLookupLegacyLocalIdBucketWorld(),
            'oldWorld',
            'oldWorld|p1',
            allowLocalIdFallback: true,
          ),
          ['oldWorld|p1|0|0'],
        );
      },
    );

    test(
      'landTileKeysForProvinceBucket fallback never shadows a full-id bucket',
      () {
        expect(
          landTileKeysForProvinceBucket(
            provinceLookupMixedBucketWorld(),
            'oldWorld',
            'oldWorld|p1',
            allowLocalIdFallback: true,
          ),
          ['oldWorld|p1|0|0'],
        );
      },
    );

    test(
      'landTileKeysForProvinceBucket fallback returns empty when neither bucket exists',
      () {
        final empty = TestFixtures.worldStateAtOrdersPhase(
          tileKeysByRegionAndProvince: const {'oldWorld': {}},
        );
        expect(
          landTileKeysForProvinceBucket(
            empty,
            'oldWorld',
            'oldWorld|p1',
            allowLocalIdFallback: true,
          ),
          isEmpty,
        );
        expect(
          landTileKeysForProvinceBucket(empty, 'oldWorld', 'oldWorld|p1'),
          isEmpty,
        );
      },
    );
  });

  group('WorldStateProvinceLookup extension', () {
    final world = provinceLookupTestWorld();

    test('tryGetRegionIdForLegacyProvinceKey resolves both regions', () {
      expect(
        world.tryGetRegionIdForLegacyProvinceKey('oldWorld|p1'),
        'oldWorld',
      );
      expect(
        world.tryGetRegionIdForLegacyProvinceKey('newWorld|n1'),
        'newWorld',
      );
      expect(world.tryGetRegionIdForLegacyProvinceKey('ghost'), isNull);
    });

    test('resolveToFullProvinceId throws on short id', () {
      const shortId = 'p1';
      expect(() => world.resolveToFullProvinceId(shortId), throwsStateError);
      expect(world.resolveToFullProvinceId('oldWorld|p1'), 'oldWorld|p1');
    });

    test('toFullProvinceId prefixes local ids', () {
      expect(world.toFullProvinceId('oldWorld', 'p1'), 'oldWorld|p1');
      expect(world.toFullProvinceId('oldWorld', 'oldWorld|p1'), 'oldWorld|p1');
    });

    test('getProvinceByRegion and getProvince via extension', () {
      expect(world.getProvinceByRegion('oldWorld', 'p1').ownerId, 'gp1');
      expect(() => world.getProvinceByRegion('bad', 'p1'), throwsStateError);
      expect(
        () => world.getProvinceByRegion('oldWorld', 'missing'),
        throwsStateError,
      );
      expect(world.getProvince('oldWorld|p1').ownerId, 'gp1');
    });

    test('updateRegionById throws on unknown region', () {
      expect(() => world.updateRegionById('mars', (r) => r), throwsStateError);
    });
  });

  group('oldWorldProvinceCountOwnedBy', () {
    test('counts only old-world provinces of the faction', () {
      final game = TestFixtures.singlePlayerGame(
        const Player(id: 'gp1', displayName: 'GP1', isHuman: true),
        gameId: 'g',
        worldState: provinceLookupTestWorld(),
      );
      expect(oldWorldProvinceCountOwnedBy(game, 'gp1'), 2);
      expect(oldWorldProvinceCountOwnedBy(game, 'gp2'), 0);
    });

    test('matches the projection accessor and the prior old-world scan', () {
      final world = provinceLookupTestWorld();
      final game = TestFixtures.singlePlayerGame(
        const Player(id: 'gp1', displayName: 'GP1', isHuman: true),
        gameId: 'g',
        worldState: world,
      );
      final cache = ProvinceOwnerCache.of(world);
      int manualOldWorldCount(String id) =>
          world.oldWorld.provinces.where((p) => p.ownerId == id).length;
      for (final id in ['gp1', 'gp2', 'unowned']) {
        expect(
          oldWorldProvinceCountOwnedBy(game, id),
          cache.countOwnedByInRegion(id, kRegionOldWorld),
        );
        expect(oldWorldProvinceCountOwnedBy(game, id), manualOldWorldCount(id));
      }
    });
  });

  group('traverseProvinces', () {
    test('yields provinces from both regions in old-then-new order', () {
      final entries = traverseProvinces(provinceLookupTraverseWorld()).toList();
      expect(entries.map((e) => e.provinceId), [
        'oldWorld|p1',
        'oldWorld|p2',
        'newWorld|p9',
      ]);
      expect(entries[0].regionId, kRegionOldWorld);
      expect(entries[0].tileKeys, ['oldWorld|p1|0|0']);
      expect(entries[2].regionId, 'newWorld');
    });

    test('where filter excludes provinces', () {
      final world = TestFixtures.worldStateAtOrdersPhase(
        oldWorld: const RegionData(
          provinces: [
            Province(
              id: 'oldWorld|p1',
              regionId: kRegionOldWorld,
              ownerId: 'gp1',
            ),
            Province(id: 'oldWorld|p2', regionId: kRegionOldWorld),
          ],
        ),
      );
      expect(
        traverseProvinces(
          world,
          where: (_, p) => p.ownerId != null,
        ).map((e) => e.provinceId).toList(),
        ['oldWorld|p1'],
      );
    });
  });
}
