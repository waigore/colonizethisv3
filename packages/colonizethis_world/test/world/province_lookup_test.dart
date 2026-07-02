// ignore_for_file: deprecated_member_use

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/src/world/province_lookup.dart';
import 'package:colonizethis_world/src/world/province_owner_cache.dart';
import 'package:colonizethis_world/src/world_constants.dart'
    show kRegionNewWorld, kRegionOldWorld;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

import '../world_test_support/province_lookup_test_support.dart';

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
      // Already at 0 stays clamped at 0.
      final clamped = decrementFortLevelForProvinceIdIfPresent(
        provinces,
        'oldWorld|p2',
      );
      expect(clamped.firstWhere((p) => p.id == 'oldWorld|p2').fortLevel, 0);
    });

    test('decrementFortLevelForProvinceIdIfPresent returns same list if absent', () {
      final next = decrementFortLevelForProvinceIdIfPresent(
        provinces,
        'oldWorld|missing',
      );
      expect(next, same(provinces));
    });
  });

  group('standalone lookup functions', () {
    final world = provinceLookupTestWorld();

    test('resolveToFullProvinceId returns prefixed, throws on short id', () {
      expect(resolveToFullProvinceId(world, 'oldWorld|p1'), 'oldWorld|p1');
      // Unprefixed id passed via variable so the throw-behavior is exercised
      // without tripping the unprefixed-province-id-literal AST lint.
      const shortId = 'p1';
      expect(() => resolveToFullProvinceId(world, shortId), throwsStateError);
    });

    test('getProvinceByRegion success and failure modes', () {
      expect(getProvinceByRegion(world, 'oldWorld', 'p1').ownerId, 'gp1');
      expect(
        () => getProvinceByRegion(world, 'badRegion', 'p1'),
        throwsStateError,
      );
      expect(
        () => getProvinceByRegion(world, 'oldWorld', 'missing'),
        throwsStateError,
      );
    });

    test('getProvince resolves a prefixed id', () {
      expect(getProvince(world, 'newWorld|n1').ownerId, 'gp2');
    });

    test('resolveProvinceRowForOwnershipTransfer matches legacy short id', () {
      final legacyWorld = TestFixtures.worldStateAtOrdersPhase(
        oldWorld: const RegionData(
          provinces: [Province(id: 'shortId', regionId: 'oldWorld')],
        ),
      );
      final hit = resolveProvinceRowForOwnershipTransfer(
        legacyWorld,
        'shortId',
      );
      expect(hit!.canonicalProvinceId, 'shortId');
      expect(
        resolveProvinceRowForOwnershipTransfer(legacyWorld, 'nope'),
        isNull,
      );
    });

    test('landTileKeysForProvinceBucket returns a mutable copy of bucket keys', () {
      final keys = landTileKeysForProvinceBucket(
        world,
        'oldWorld',
        'oldWorld|p1',
      );
      expect(keys, ['oldWorld|p1|0|0', 'oldWorld|p1|1|0']);
      // Mutating the result must not affect the source bucket.
      keys.add('mutation');
      expect(
        landTileKeysForProvinceBucket(world, 'oldWorld', 'oldWorld|p1'),
        ['oldWorld|p1|0|0', 'oldWorld|p1|1|0'],
      );
      expect(
        landTileKeysForProvinceBucket(world, 'oldWorld', 'oldWorld|p2'),
        isEmpty,
      );
    });

    test('landTileKeysForProvinceBucket is strict full-id only by default', () {
      // Legacy/fixture bucket keyed by local id only; the default (strict)
      // lookup must not fall back to it (Refs #3403 Phase 1).
      final legacy = TestFixtures.worldStateAtOrdersPhase(
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            'p1': ['oldWorld|p1|0|0'],
          },
        },
      );
      expect(
        landTileKeysForProvinceBucket(legacy, 'oldWorld', 'oldWorld|p1'),
        isEmpty,
      );
    });

    test('landTileKeysForProvinceBucket opt-in fallback resolves local-id bucket', () {
      final legacy = TestFixtures.worldStateAtOrdersPhase(
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            'p1': ['oldWorld|p1|0|0'],
          },
        },
      );
      expect(
        landTileKeysForProvinceBucket(
          legacy,
          'oldWorld',
          'oldWorld|p1',
          allowLocalIdFallback: true,
        ),
        ['oldWorld|p1|0|0'],
      );
    });

    test('landTileKeysForProvinceBucket fallback never shadows a full-id bucket', () {
      final mixed = TestFixtures.worldStateAtOrdersPhase(
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            'oldWorld|p1': ['oldWorld|p1|0|0'],
            'p1': ['oldWorld|p1|9|9'],
          },
        },
      );
      expect(
        landTileKeysForProvinceBucket(
          mixed,
          'oldWorld',
          'oldWorld|p1',
          allowLocalIdFallback: true,
        ),
        ['oldWorld|p1|0|0'],
      );
    });

    test('landTileKeysForProvinceBucket fallback returns empty when neither bucket exists', () {
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
    });
  });

  group('WorldStateProvinceLookup extension', () {
    final world = provinceLookupTestWorld();

    test('tryGetRegionIdForLegacyProvinceKey resolves both regions', () {
      expect(world.tryGetRegionIdForLegacyProvinceKey('oldWorld|p1'), 'oldWorld');
      expect(world.tryGetRegionIdForLegacyProvinceKey('newWorld|n1'), 'newWorld');
      expect(world.tryGetRegionIdForLegacyProvinceKey('ghost'), isNull);
    });

    test('resolveToFullProvinceId throws on short id', () {
      // Unprefixed id passed via variable so the throw-behavior is exercised
      // without tripping the unprefixed-province-id-literal AST lint.
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
      expect(
        () => world.updateRegionById('mars', (r) => r),
        throwsStateError,
      );
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

    // Refs #3393 Phase 6b (slice 5) — behaviour-preserving migration onto
    // `ProvinceOwnerCache.countOwnedByInRegion`. The projection-backed count
    // equals both the prior `world.oldWorld.provinces` owner scan and the
    // cache accessor for the same faction id.
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
          reason: 'projection-backed count for $id',
        );
        expect(
          oldWorldProvinceCountOwnedBy(game, id),
          manualOldWorldCount(id),
          reason: 'matches prior old-world owner scan for $id',
        );
      }
    });
  });

}
