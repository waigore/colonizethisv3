import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/constants.dart';
import 'package:colonizethis_logic/src/orders/orders_application_context.dart';
import 'package:colonizethis_logic/src/orders/work_handlers/purchase_land_handler.dart';
import 'package:colonizethis_logic/src/orders/work_handlers/work_order_handler.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('PurchaseLandWorkOrderHandler', () {
    test('supports only purchase_land target', () {
      const handler = PurchaseLandWorkOrderHandler();
      expect(handler.supports(kWorkTargetPurchaseLand), isTrue);
      expect(handler.supports(kWorkTargetExplore), isFalse);
    });

    test('tryApply purchases land when embassy, peace, and treasury allow', () {
      const ow = 'oldWorld';
      const minorProvinceId = '$ow|M1';
      const tileKey = '$ow|M1|0|0';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
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
          newWorld: const RegionData(),
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
        ),
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
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
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
      const handler = PurchaseLandWorkOrderHandler();
      const order = WorkOrder(
        unitId: 'merchant1',
        target: kWorkTargetPurchaseLand,
        targetTileKey: tileKey,
      );

      final applied = handler.tryApply(
        context,
        order,
        merchant,
        tileKey,
        true,
      );

      expect(applied, isTrue);
      expect(context.treasury, 500 - purchaseLandCost('grain'));
      expect(context.purchasedTilesByTileKey[tileKey], 'p1');
      final updatedMerchant =
          context.state.work.newUnitsById['merchant1'] ??
          context.state.work.oldUnitsById['merchant1'];
      expect(updatedMerchant, isNotNull);
      expect(updatedMerchant!.status, UnitStatus.idle);
      expect(updatedMerchant.tileKey, tileKey);
    });
  });

  group('applyPurchaseLandWorkOrder', () {
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
      final game = Game(
        id: 'g',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(),
          newWorld: RegionData(),
          resourceByTileKey: {},
        ),
        players: const [],
      );
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeMerchant,
        ownerId: 'p1',
        locationProvinceId: 'oldWorld|P1',
        tileKey: 'oldWorld|P1|0|0',
      );
      final out = applyPurchaseLandWorkOrder(
        state: minimalState(game),
        player: const Player(
          id: 'p1',
          displayName: 'P1',
          isHuman: true,
        ),
        unit: unit,
        targetTileKey: 'oldWorld|P1|0|0',
        treasury: 100,
        purchasedTilesByTileKey: const {},
        provinceById: (_) => null,
        updateUnit: (_, __) => fail('updateUnit should not run'),
      );
      expect(out.treasury, 100);
      expect(out.purchasedTilesByTileKey, isEmpty);
    });
  });
}
