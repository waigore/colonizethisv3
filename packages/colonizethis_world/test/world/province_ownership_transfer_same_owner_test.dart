import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_world/src/world/province_ownership_transfer.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_test/game_test_fixtures.dart';

void main() {
  group('applyCanonicalSingleProvinceOwnershipTransfer same-owner early-exit', () {
    test('leaves game unchanged when old and new owner match', () {
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
          ],
        ),
        tileKeysByRegionAndProvince: const {
          ow: {
            pid: [tileKey],
          },
        },
        players: const [Player(id: 'a', displayName: 'A', isHuman: true)],
      );

      final after = applyCanonicalSingleProvinceOwnershipTransfer(
        game,
        targetProvinceId: pid,
        oldOwnerId: 'a',
        newOwnerId: 'a',
      );

      expect(identical(after, game), isTrue);
      expect(after.worldState.oldWorld.provinces.single.ownerId, 'a');
      expect(after.worldState.oldWorld.units.single.ownerId, 'a');
    });

    test('WithResult returns zeroed counts when old and new owner match', () {
      const ow = kRegionOldWorld;
      const pid = '$ow|P1';

      final game = TestFixtures.minimalGame(
        oldWorld: const RegionData(
          provinces: [Province(id: pid, regionId: ow, ownerId: 'a')],
        ),
        players: const [Player(id: 'a', displayName: 'A', isHuman: true)],
      );

      final out = applyCanonicalSingleProvinceOwnershipTransferWithResult(
        game,
        targetProvinceId: pid,
        oldOwnerId: 'a',
        newOwnerId: 'a',
      );

      expect(identical(out.game, game), isTrue);
      expect(out.result.regimentsTransferred, 0);
      expect(out.result.inPortFleetsTransferred, 0);
      expect(out.result.purchasedLandEntriesRemoved, 0);
      expect(out.result.spyTimersCleared, 0);
      expect(out.result.civilianRelocations, 0);
      expect(out.result.visibilitySummary.tilesSetFullyVisibleForNewOwner, 0);
      expect(out.result.visibilitySummary.tilesDowngradedForFormerOwner, 0);
    });
  });

  group('applyCanonicalSingleProvinceOwnershipTransferWithResult', () {
    test('returns structured counts matching transfer', () {
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
          ],
        ),
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'a',
            regionId: ow,
            shipTypeIds: const ['carrack'],
            inPortAtProvinceId: pid,
          ),
        ],
        purchasedTilesByTileKey: const {tileKey: 'x'},
        spyRevealTurnsByPlayer: const {
          'a': {pid: 1},
          'b': {pid: 1},
        },
        tileKeysByRegionAndProvince: const {
          ow: {
            pid: [tileKey],
          },
        },
        playerVisibilityByTile: const {
          'a': {tileKey: 'fullyVisible'},
          'b': {},
        },
        players: const [
          Player(id: 'a', displayName: 'A', isHuman: true),
          Player(id: 'b', displayName: 'B', isHuman: true),
        ],
      );

      final out = applyCanonicalSingleProvinceOwnershipTransferWithResult(
        game,
        targetProvinceId: pid,
        oldOwnerId: 'a',
        newOwnerId: 'b',
      );

      expect(out.result.regimentsTransferred, 1);
      expect(out.result.inPortFleetsTransferred, 1);
      expect(out.result.purchasedLandEntriesRemoved, 1);
      expect(out.result.spyTimersCleared, 2);
      expect(out.result.visibilitySummary.tilesSetFullyVisibleForNewOwner, 1);
      expect(out.result.visibilitySummary.tilesDowngradedForFormerOwner, 1);
    });
  });
}
