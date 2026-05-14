import 'package:colonizethis_data/colonizethis_data.dart'
    show kTechIdMerchantCompanies;
import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_logic/src/orders/orders_application_context.dart';
import 'package:colonizethis_logic/src/orders/purchase_land_work_completion.dart';
import 'package:colonizethis_logic/src/orders/work_handlers/simple_work_order_handler.dart';
import 'package:colonizethis_logic/src/orders/work_handlers/work_order_handler.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../../test_fixtures.dart';

void main() {
  group('PurchaseLandWorkOrderHandler', () {
    test('supports only purchase_land target', () {
      final handler = purchaseLandWorkOrderHandler;
      expect(handler.supports(kWorkTargetPurchaseLand), isTrue);
      expect(handler.supports(kWorkTargetExplore), isFalse);
    });

    test('tryApply assigns currentWork without treasury deduction', () {
      const ow = 'oldWorld';
      const minorProvinceId = '$ow|M1';
      const tileKey = '$ow|M1|0|0';
      final game = TestFixtures.minimalGame(
        id: 'g1',
        turnNumber: 0,
        oldWorld: RegionData(
          provinces: [
            Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
            Province(id: minorProvinceId, regionId: ow, ownerId: 'minor1'),
          ],
          units: [
            Unit(
              id: 'merchant1',
              type: kUnitTypeMerchant,
              ownerId: 'p1',
              locationProvinceId: minorProvinceId,
              tileKey: tileKey,
            ),
          ],
        ),
        resourceByTileKey: const {tileKey: 'grain'},
        playerVisibilityByTile: const {
          'p1': {tileKey: 'fullyVisible'},
        },
        tileKeysByRegionAndProvince: {
          ow: {
            minorProvinceId: [tileKey],
            '$ow|P1': ['$ow|P1|0|0'],
          },
        },
        players: [
          Player(
            id: 'p1',
            displayName: 'P1',
            isHuman: true,
            capitalProvinceId: '$ow|P1',
            stockpile: const Stockpile(),
            treasury: 500,
            techUnlocked: {kTechIdMerchantCompanies: true},
          ),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
        overtureStates: [
          const OvertureState(
            gpId: 'p1',
            targetId: 'minor1',
            stage: OvertureStage.embassy,
            sinceTurn: 0,
          ),
        ],
        diplomacyRelations: const [],
      );

      final merchant = game.worldState.oldWorld.units.single;
      final work = WorkOrderState(
        oldUnitsById: {merchant.id: merchant},
        newUnitsById: const {},
        tileState: game.worldState.tileState,
        visibilityByTile: const {},
        portsByProvinceSeaboard: const {},
        purchasedTilesByTileKey: const {},
        oldProvinces: List<Province>.from(game.worldState.oldWorld.provinces),
        newProvinces: const [],
      );
      var state = BuildWorkState(
        game: game,
        buildOrders: const {},
        workOrders: const {},
        work: work,
      );
      final player = game.players.single;
      final context = WorkOrderExecutionContext(state: state, player: player);
      final handler = purchaseLandWorkOrderHandler;
      const order = WorkOrder(
        unitId: 'merchant1',
        target: kWorkTargetPurchaseLand,
        targetTileKey: tileKey,
      );

      final applied = handler.tryApply(context, order, merchant, tileKey, true);

      expect(applied, isTrue);
      expect(context.treasury, 500);
      expect(context.purchasedTilesByTileKey.containsKey(tileKey), isFalse);
      final updatedMerchant =
          context.state.work.newUnitsById['merchant1'] ??
          context.state.work.oldUnitsById['merchant1'];
      expect(updatedMerchant, isNotNull);
      expect(updatedMerchant!.status, UnitStatus.working);
      expect(updatedMerchant.tileKey, tileKey);
      expect(updatedMerchant.currentWork?.workTarget, kWorkTargetPurchaseLand);
      expect(updatedMerchant.currentWork?.remainingTurns, 1);
    });
  });

  group('applyPurchaseLandCompletion', () {
    BuildWorkState minimalState(Game game) {
      return BuildWorkState(
        game: game,
        buildOrders: const {},
        workOrders: const {},
        work: WorkOrderState(
          oldUnitsById: const {},
          newUnitsById: const {},
          tileState: game.worldState.tileState,
          visibilityByTile: const {},
          portsByProvinceSeaboard: const {},
          purchasedTilesByTileKey: const {},
          oldProvinces: const [],
          newProvinces: const [],
        ),
      );
    }

    test('returns unchanged treasury when tile has no resource entry', () {
      final game = TestFixtures.minimalGame(players: const []);
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeMerchant,
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|P1',
        tileKey: 'oldWorld|P1|0|0',
      );
      final out = applyPurchaseLandCompletion(
        state: minimalState(game),
        player: const Player(id: 'p1', displayName: 'P1', isHuman: true),
        unit: unit,
        targetTileKey: 'oldWorld|P1|0|0',
        treasury: 100,
        purchasedTilesByTileKey: const {},
        provinceById: (_) => null,
      );
      expect(out.treasury, 100);
      expect(out.purchasedTilesByTileKey, isEmpty);
    });
  });
}
