import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_world/src/world/province_traversal.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
group('traverseProvinces', () {
    test('yields provinces from both regions in old-then-new order', () {
      final world = TestFixtures.worldStateAtOrdersPhase(
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
      final world = TestFixtures.worldStateAtOrdersPhase(
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

}
