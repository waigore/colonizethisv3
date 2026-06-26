import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_orders/src/orders/work_handlers/explore_work_handler.dart';
import 'package:colonizethis_orders/src/orders/work_handlers/simple_work_order_handler.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

void main() {
  group('exploreWorkOrderHandler', () {
    test('supports only explore target', () {
      expect(exploreWorkOrderHandler.supports(kWorkTargetExplore), isTrue);
      expect(exploreWorkOrderHandler.supports(kWorkTargetPurchaseLand), isFalse);
    });
  });

  group('tryApplyExploreWorkOrder', () {
    const ow = 'oldWorld';
    const provinceId = '$ow|P1';
    const tileKey = '$ow|P1|0|0';

    test('assigns explore currentWork when province has discoverable tiles', () {
      final game = TestFixtures.minimalGame(
        oldWorld: RegionData(
          provinces: [
            Province(id: provinceId, regionId: ow, ownerId: 'p1'),
          ],
          units: [
            Unit(
              id: 'u1',
              type: kUnitTypeExplorer,
              ownerId: 'p1',
              locationProvinceId: provinceId,
              tileKey: tileKey,
            ),
          ],
        ),
        tileKeysByRegionAndProvince: {
          ow: {
            provinceId: [tileKey, '$ow|P1|0|1'],
          },
        },
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
        ],
      );
      final unit = game.worldState.oldWorld.units.single;
      Unit? updated;
      final ok = tryApplyExploreWorkOrder(
        game: game,
        order: const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetExplore,
          targetTileKey: tileKey,
        ),
        unit: unit,
        targetTileKey: tileKey,
        regionForUnit: (_) => ow,
        updateUnit: (id, u) {
          expect(id, 'u1');
          updated = u;
        },
      );
      expect(ok, isTrue);
      final out = updated;
      expect(out, isNotNull);
      expect(out!.status, UnitStatus.working);
      expect(out.currentWork?.workTarget, kWorkTargetExplore);
      expect(out.currentWork?.tileKey, tileKey);
    });

    test('returns false when province has no tile keys in world state', () {
      final game = TestFixtures.minimalGame(
        oldWorld: RegionData(
          provinces: [
            Province(id: provinceId, regionId: ow, ownerId: 'p1'),
          ],
          units: [
            Unit(
              id: 'u1',
              type: kUnitTypeExplorer,
              ownerId: 'p1',
              locationProvinceId: provinceId,
              tileKey: tileKey,
            ),
          ],
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
        ],
      );
      final unit = game.worldState.oldWorld.units.single;
      var updateCalls = 0;
      final ok = tryApplyExploreWorkOrder(
        game: game,
        order: const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetExplore,
          targetTileKey: tileKey,
        ),
        unit: unit,
        targetTileKey: tileKey,
        regionForUnit: (_) => ow,
        updateUnit: (_, __) => updateCalls++,
      );
      expect(ok, isFalse);
      expect(updateCalls, 0);
    });
  });
}
