// ignore_for_file: deprecated_member_use

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('forEachWorldRegion', () {
    test('invokes action once per region', () {
      final world = TestFixtures.worldStateAtOrdersPhase(
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
      final world = TestFixtures.worldStateAtOrdersPhase(
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
      final world = TestFixtures.worldStateAtOrdersPhase(
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
