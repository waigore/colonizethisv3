import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/src/world/province_ownership_transfer_stages.dart';

void main() {
  const ow = kRegionOldWorld;
  const pid = '$ow|P1';
  const otherPid = '$ow|P2';
  const tileInP1 = '$ow|P1|0|0';
  const tileInP2 = '$ow|P2|0|0';

  group('clearPurchasedTilesForProvinceOwnershipTransfer', () {
    test('positive: removes only tiles in the conquered province', () {
      final world = TestFixtures.worldStateAtOrdersPhase(
        oldWorld: const RegionData(
          provinces: [
            Province(id: pid, regionId: ow, ownerId: 'a'),
            Province(id: otherPid, regionId: ow, ownerId: 'a'),
          ],
        ),
      ).copyWith(
        purchasedTilesByTileKey: const {
          tileInP1: 'buyer1',
          tileInP2: 'buyer2',
        },
      );

      var removed = -1;
      final next = clearPurchasedTilesForProvinceOwnershipTransfer(
        world,
        pid,
        (n) => removed = n,
      );

      expect(removed, 1);
      expect(next, const {tileInP2: 'buyer2'});
    });

    test('negative: empty purchases returns same map and zero removed', () {
      final world = TestFixtures.worldStateAtOrdersPhase(
        oldWorld: const RegionData(
          provinces: [Province(id: pid, regionId: ow, ownerId: 'a')],
        ),
      );

      var removed = -1;
      final next = clearPurchasedTilesForProvinceOwnershipTransfer(
        world,
        pid,
        (n) => removed = n,
      );

      expect(removed, 0);
      expect(identical(next, world.purchasedTilesByTileKey), isTrue);
      expect(next, isEmpty);
    });
  });

  group('countSpyTimersClearedForProvinceOwnershipTransfer', () {
    test('positive: counts old and new owner timers for the province', () {
      final maps = <String, Map<String, int>>{
        'old': {pid: 2},
        'new': {pid: 1, otherPid: 9},
      };
      expect(
        countSpyTimersClearedForProvinceOwnershipTransfer(
          maps,
          pid,
          'old',
          'new',
        ),
        2,
      );
    });

    test('negative: returns 0 when neither owner has a timer for province', () {
      final maps = <String, Map<String, int>>{
        'old': {otherPid: 2},
        'new': {otherPid: 1},
      };
      expect(
        countSpyTimersClearedForProvinceOwnershipTransfer(
          maps,
          pid,
          'old',
          'new',
        ),
        0,
      );
    });
  });

  group('countIllegalCivilianRelocationsBeforeOwnershipTransfer', () {
    test('positive: counts civilian illegal on changed province tile', () {
      final game = TestFixtures.minimalGame(
        oldWorld: RegionData(
          provinces: const [
            Province(id: pid, regionId: ow, ownerId: 'a'),
          ],
          units: [
            Unit(
              id: 'civ1',
              type: 'peasant',
              ownerId: 'b',
              locationProvinceId: pid,
              tileKey: tileInP1,
            ),
          ],
        ),
        tileKeysByRegionAndProvince: const {
          ow: {
            pid: [tileInP1],
          },
        },
        players: const [
          Player(id: 'a', displayName: 'A', isHuman: true),
          Player(id: 'b', displayName: 'B', isHuman: false),
        ],
      );

      expect(
        countIllegalCivilianRelocationsBeforeOwnershipTransfer(game, {pid}),
        greaterThan(0),
      );
    });

    test('negative: military units do not count as civilian relocations', () {
      final game = TestFixtures.minimalGame(
        oldWorld: RegionData(
          provinces: const [
            Province(id: pid, regionId: ow, ownerId: 'a'),
          ],
          units: [
            Unit(
              id: 'r1',
              type: 'grenadiers',
              ownerId: 'a',
              locationProvinceId: pid,
              tileKey: tileInP1,
            ),
          ],
        ),
        tileKeysByRegionAndProvince: const {
          ow: {
            pid: [tileInP1],
          },
        },
        players: const [Player(id: 'a', displayName: 'A', isHuman: true)],
      );

      expect(
        countIllegalCivilianRelocationsBeforeOwnershipTransfer(game, {pid}),
        0,
      );
    });
  });
}
