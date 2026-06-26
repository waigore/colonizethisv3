import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

void main() {
  group('previewTotalTurnsForPendingWorkOrder', () {
    test('returns scaled explore turns from province size', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: 'h1',
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final game = TestFixtures.oldWorldGameWithUnit(
        unit: unit,
        tileKeysByRegionAndProvince: const {
          'oldWorld': {
            'oldWorld|p1': ['oldWorld|p1|0|0', 'oldWorld|p1|1|0'],
            'oldWorld|p2': [
              'oldWorld|p2|0|0',
              'oldWorld|p2|1|0',
              'oldWorld|p2|2|0',
              'oldWorld|p2|3|0',
            ],
          },
        },
      );
      const order = WorkOrder(
        unitId: 'u1',
        target: kWorkTargetExplore,
        targetTileKey: 'oldWorld|p1|0|0',
      );

      final turns = previewTotalTurnsForPendingWorkOrder(
        game: game,
        unit: unit,
        order: order,
      );

      expect(turns, 2);
    });

    test('returns fort-level scaled turns for build_fort', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeEngineer,
        ownerId: 'h1',
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final game = TestFixtures.oldWorldGameWithUnit(
        unit: unit,
        provinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', fortLevel: 2),
        ],
      );
      const order = WorkOrder(
        unitId: 'u1',
        target: kWorkTargetBuildFort,
        targetTileKey: 'oldWorld|p1|0|0',
      );

      final turns = previewTotalTurnsForPendingWorkOrder(
        game: game,
        unit: unit,
        order: order,
      );

      expect(turns, 3);
    });

    test('returns one turn for counter_spy', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeSpy,
        ownerId: 'h1',
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final game = TestFixtures.oldWorldGameWithUnit(unit: unit);

      final turns = previewTotalTurnsForPendingWorkOrder(
        game: game,
        unit: unit,
        order: const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetCounterSpy,
          targetTileKey: 'oldWorld|p1|0|0',
        ),
      );

      expect(turns, 1);
    });

    test('returns improvement-level scaled turns for build_improvement', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeBuilder,
        ownerId: 'h1',
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final game = TestFixtures.oldWorldGameWithUnit(
        unit: unit,
        tileState: const TileMapState(
          improvementByTile: {'oldWorld|p1|0|0': 2},
        ),
      );

      final turns = previewTotalTurnsForPendingWorkOrder(
        game: game,
        unit: unit,
        order: const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: 'oldWorld|p1|0|0',
        ),
      );

      expect(turns, 1);
    });

    test('returns minimum one turn for prospect and purchase_land', () {
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: 'h1',
        locationProvinceId: 'oldWorld|p1',
        tileKey: 'oldWorld|p1|0|0',
      );
      final game = TestFixtures.oldWorldGameWithUnit(unit: unit);

      final prospectTurns = previewTotalTurnsForPendingWorkOrder(
        game: game,
        unit: unit,
        order: const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: 'oldWorld|p1|0|0',
        ),
      );
      final purchaseTurns = previewTotalTurnsForPendingWorkOrder(
        game: game,
        unit: unit,
        order: const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetPurchaseLand,
          targetTileKey: 'oldWorld|p1|0|0',
        ),
      );

      expect(prospectTurns, 1);
      expect(purchaseTurns, 1);
    });
  });
}
