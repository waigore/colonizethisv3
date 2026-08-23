import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'province_ownership_transfer_extra_cases.dart';

void main() {
  group('applyCanonicalSingleProvinceOwnershipTransfer', () {
    test('transfers province owner and resident military regiments', () {
      const ow = kRegionOldWorld;
      const pid = '$ow|P1';
      const tileKey = '$ow|P1|0|0';

      final game = TestFixtures.minimalGame(
        oldWorld: RegionData(
          provinces: const [Province(id: pid, regionId: ow, ownerId: 'a')],
          units: [
            Unit(
              id: 'r1',
              type: 'grenadiers',
              ownerId: 'a',
              locationProvinceId: pid,
            ),
            Unit(
              id: 'r2',
              type: 'grenadiers',
              ownerId: 'b',
              locationProvinceId: pid,
            ),
          ],
        ),
        tileKeysByRegionAndProvince: const {
          ow: {
            pid: [tileKey],
          },
        },
        players: const [
          Player(id: 'a', displayName: 'A', isHuman: true),
          Player(id: 'b', displayName: 'B', isHuman: true),
        ],
      );

      final after = applyCanonicalSingleProvinceOwnershipTransfer(
        game,
        targetProvinceId: pid,
        oldOwnerId: 'a',
        newOwnerId: 'b',
      );

      final p = after.worldState.oldWorld.provinces.first;
      expect(p.ownerId, 'b');

      final r1 = after.worldState.oldWorld.units.firstWhere(
        (u) => u.id == 'r1',
      );
      final r2 = after.worldState.oldWorld.units.firstWhere(
        (u) => u.id == 'r2',
      );
      expect(r1.ownerId, 'b');
      expect(r2.ownerId, 'b');
    });

    test('transfers only in-port fleets at target province', () {
      const ow = kRegionOldWorld;
      const pid = '$ow|P1';

      final game = TestFixtures.minimalGame(
        oldWorld: const RegionData(
          provinces: [Province(id: pid, regionId: ow, ownerId: 'a')],
        ),
        fleets: [
          Fleet(
            id: 'f_port',
            ownerId: 'a',
            regionId: ow,
            shipTypeIds: const ['carrack'],
            inPortAtProvinceId: pid,
          ),
          Fleet(
            id: 'f_sea',
            ownerId: 'a',
            regionId: ow,
            shipTypeIds: const ['carrack'],
            seaZoneId: 's1',
          ),
        ],
        players: const [
          Player(id: 'a', displayName: 'A', isHuman: true),
          Player(id: 'b', displayName: 'B', isHuman: true),
        ],
      );

      final after = applyCanonicalSingleProvinceOwnershipTransfer(
        game,
        targetProvinceId: pid,
        oldOwnerId: 'a',
        newOwnerId: 'b',
      );

      final port = after.worldState.fleets.firstWhere((f) => f.id == 'f_port');
      final sea = after.worldState.fleets.firstWhere((f) => f.id == 'f_sea');
      expect(port.ownerId, 'b');
      expect(sea.ownerId, 'a');
    });

    test('clears purchased land entries for province tiles', () {
      const ow = kRegionOldWorld;
      const pid = '$ow|P1';
      const tileKey = '$ow|P1|0|0';

      final game = TestFixtures.minimalGame(
        oldWorld: const RegionData(
          provinces: [Province(id: pid, regionId: ow, ownerId: 'a')],
        ),
        purchasedTilesByTileKey: const {
          tileKey: 'buyer',
          'oldWorld|P2|0|0': 'buyer',
        },
        tileKeysByRegionAndProvince: const {
          ow: {
            pid: [tileKey],
            '$ow|P2': ['oldWorld|P2|0|0'],
          },
        },
        players: const [
          Player(id: 'a', displayName: 'A', isHuman: true),
          Player(id: 'b', displayName: 'B', isHuman: true),
        ],
      );

      final after = applyCanonicalSingleProvinceOwnershipTransfer(
        game,
        targetProvinceId: pid,
        oldOwnerId: 'a',
        newOwnerId: 'b',
      );

      expect(
        after.worldState.purchasedTilesByTileKey.containsKey(tileKey),
        isFalse,
      );
      expect(
        after.worldState.purchasedTilesByTileKey['oldWorld|P2|0|0'],
        'buyer',
      );
    });
  });
  registerProvinceOwnershipTransferExtraCases();
}
