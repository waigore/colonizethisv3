import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_world/src/world/province_traversal.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('traverseProvinces', () {
    test('yields provinces from both regions in old-then-new order', () {
      final world = WorldState(
        turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
        oldWorld: RegionData(
          provinces: [
            Province(id: 'oldWorld|p1', regionId: kRegionOldWorld, ownerId: 'gp1'),
            Province(id: 'oldWorld|p2', regionId: kRegionOldWorld),
          ],
        ),
        newWorld: RegionData(
          provinces: [
            Province(id: 'newWorld|p9', regionId: kRegionNewWorld, ownerId: 'gp2'),
          ],
        ),
        tileKeysByRegionAndProvince: {
          kRegionOldWorld: {
            'oldWorld|p1': ['oldWorld|p1|0|0'],
          },
          kRegionNewWorld: {
            'newWorld|p9': ['newWorld|p9|1|1'],
          },
        },
      );

      final entries = traverseProvinces(world).toList();
      expect(entries.map((e) => e.provinceId), [
        'oldWorld|p1',
        'oldWorld|p2',
        'newWorld|p9',
      ]);
      expect(entries[0].regionId, kRegionOldWorld);
      expect(entries[0].tileKeys, ['oldWorld|p1|0|0']);
      expect(entries[2].regionId, kRegionNewWorld);
    });

    test('where filter excludes provinces', () {
      final world = WorldState(
        turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
        oldWorld: RegionData(
          provinces: [
            Province(id: 'oldWorld|p1', regionId: kRegionOldWorld, ownerId: 'gp1'),
            Province(id: 'oldWorld|p2', regionId: kRegionOldWorld),
          ],
        ),
        newWorld: const RegionData(provinces: []),
      );

      final owned = traverseProvinces(
        world,
        where: (_, p) => p.ownerId != null,
      ).map((e) => e.provinceId).toList();

      expect(owned, ['oldWorld|p1']);
    });
  });

  group('forEachWorldRegion', () {
    test('invokes action once per region', () {
      final world = WorldState(
        turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
        oldWorld: RegionData(
          provinces: [Province(id: 'oldWorld|p1', regionId: kRegionOldWorld)],
        ),
        newWorld: RegionData(
          provinces: [Province(id: 'newWorld|p1', regionId: kRegionNewWorld)],
        ),
      );

      final seen = <String>[];
      forEachWorldRegion(world, (regionId, _) => seen.add(regionId));
      expect(seen, [kRegionOldWorld, kRegionNewWorld]);
    });
  });

  group('ownerByProvinceIdMap (Refs #2560)', () {
    test('covers both regions and preserves null ownerId entries', () {
      final world = WorldState(
        turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
        oldWorld: RegionData(
          provinces: [
            Province(
              id: 'oldWorld|p1',
              regionId: kRegionOldWorld,
              ownerId: 'gp1',
            ),
            Province(id: 'oldWorld|p2', regionId: kRegionOldWorld),
          ],
        ),
        newWorld: RegionData(
          provinces: [
            Province(
              id: 'newWorld|p9',
              regionId: kRegionNewWorld,
              ownerId: 'gp2',
            ),
            Province(id: 'newWorld|p10', regionId: kRegionNewWorld),
          ],
        ),
      );

      final byOwner = ownerByProvinceIdMap(world);

      expect(byOwner, {
        'oldWorld|p1': 'gp1',
        'oldWorld|p2': null,
        'newWorld|p9': 'gp2',
        'newWorld|p10': null,
      });
    });

    test('matches the inline traverseProvinces idiom it replaces', () {
      final world = WorldState(
        turnState: const TurnState(turnNumber: 1, phase: TurnPhase.orders),
        oldWorld: RegionData(
          provinces: [
            Province(
              id: 'oldWorld|p1',
              regionId: kRegionOldWorld,
              ownerId: 'gp1',
            ),
            Province(
              id: 'oldWorld|p2',
              regionId: kRegionOldWorld,
              ownerId: 'gp3',
            ),
          ],
        ),
        newWorld: RegionData(
          provinces: [
            Province(
              id: 'newWorld|p9',
              regionId: kRegionNewWorld,
              ownerId: 'gp2',
            ),
          ],
        ),
      );

      final inline = <String, String?>{
        for (final e in traverseProvinces(world)) e.provinceId: e.ownerId,
      };
      final viaHelper = ownerByProvinceIdMap(world);

      expect(viaHelper, equals(inline));
    });
  });
}
