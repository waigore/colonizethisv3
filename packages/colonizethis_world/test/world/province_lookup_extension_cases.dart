// ignore_for_file: deprecated_member_use

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

import '../world_test_support/province_lookup_test_support.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

void registerProvinceLookupExtensionCases() {
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
