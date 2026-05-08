import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_engine_purchase_land_test_support.dart';

void main() {
  group('OrderEngine', () {
    group('validateWork (purchase_land)', () {
      final topology = PurchaseLandTestFixture.topology();

      test(
        'rejects second Builder/Engineer/Merchant work order on same tile for same player (per-tile exclusivity)',
        () {
          const ow = 'oldWorld';
          const provinceId = '$ow|P1';
          const tileKey = '$ow|P1|0|0';
          final tileTopology = MapTopology(
            nodes: const [
              TopologyNode(
                id: 'P1',
                regionId: ow,
                type: TopologyNodeType.province,
              ),
            ],
            edges: const [],
          );

          final game = Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 0,
              ),
              oldWorld: RegionData(
                provinces: const [
                  Province(id: provinceId, regionId: ow, ownerId: 'p1'),
                ],
                units: [
                  Unit(
                    id: 'builder1',
                    type: kUnitTypeBuilder,
                    ownerId: 'p1',
                    locationProvinceId: provinceId,
                    tileKey: tileKey,
                  ),
                  Unit(
                    id: 'engineer1',
                    type: kUnitTypeEngineer,
                    ownerId: 'p1',
                    locationProvinceId: provinceId,
                    tileKey: tileKey,
                  ),
                ],
              ),
              newWorld: const RegionData(),
              resourceByTileKey: const {tileKey: 'grain'},
              // Tile is fully visible so visibility is not the rejecting reason.
              playerVisibilityByTile: const {
                'p1': {tileKey: 'fullyVisible'},
              },
              tileKeysByRegionAndProvince: const {
                ow: {
                  provinceId: [tileKey],
                },
              },
            ),
            players: [
              Player(
                id: 'p1',
                displayName: 'P1',
                isHuman: true,
                capitalProvinceId: provinceId,
                // Provide enough materials so material-cost validation passes and
                // the first work order can be accepted.
                stockpile: Stockpile()
                    .applyDelta(CommodityCatalog.lumber.id, 10)
                    .applyDelta(CommodityCatalog.castIron.id, 10),
              ),
            ],
          );

          final engine = OrderEngine();
          engine
            ..addWorkOrder(
              'p1',
              const WorkOrder(
                unitId: 'builder1',
                target: kWorkTargetBuildImprovement,
                targetTileKey: tileKey,
              ),
            )
            ..addWorkOrder(
              'p1',
              const WorkOrder(
                unitId: 'engineer1',
                target: kWorkTargetBuildRoad,
                targetTileKey: tileKey,
              ),
            );

          final results = engine.validatePlayerOrdersWithContext(
            game,
            tileTopology,
            'p1',
          );

          expect(results.length, 2);
          expect(results[0].status, OrderValidationStatus.accepted);
          expect(results[1].status, OrderValidationStatus.rejected);
          expect(
            results[1].reason,
            contains('Tile already has development or purchase work'),
          );
        },
      );

      test('accepts purchase_land for mineral when prospected', () {
        final tk = PurchaseLandTestFixture.tileKey;
        final game = PurchaseLandTestFixture.baseGame(
          treasury: 500,
          overtureStates: [
            const OvertureState(
              gpId: 'p1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
          resourceByTileKey: {tk: 'iron'},
          playerProspectedTiles: {
            'p1': {tk},
          },
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          WorkOrder(
            unitId: 'merchant1',
            target: kWorkTargetPurchaseLand,
            targetTileKey: PurchaseLandTestFixture.tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.accepted);
      });

      test(
        'rejects purchase_land when tile already purchased by another GP',
        () {
          final game = PurchaseLandTestFixture.baseGame(
            treasury: 500,
            overtureStates: [
              const OvertureState(
                gpId: 'p1',
                targetId: 'minor1',
                stage: OvertureStage.embassy,
                sinceTurn: 0,
              ),
            ],
            purchasedTilesByTileKey: {
              PurchaseLandTestFixture.tileKey: 'p2',
            },
          );
          final engine = OrderEngine();
          engine.addWorkOrder(
            'p1',
            WorkOrder(
              unitId: 'merchant1',
              target: kWorkTargetPurchaseLand,
              targetTileKey: PurchaseLandTestFixture.tileKey,
            ),
          );
          final results = engine.validatePlayerOrdersWithContext(
            game,
            topology,
            'p1',
          );
          expect(results.single.status, OrderValidationStatus.rejected);
          expect(
            results.single.reason,
            contains('Tile already purchased by another power'),
          );
        },
      );

      test('rejects purchase_land when tile already owned by same player', () {
        final game = PurchaseLandTestFixture.baseGame(
          treasury: 500,
          overtureStates: [
            const OvertureState(
              gpId: 'p1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
          purchasedTilesByTileKey: {
            PurchaseLandTestFixture.tileKey: 'p1',
          },
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          WorkOrder(
            unitId: 'merchant1',
            target: kWorkTargetPurchaseLand,
            targetTileKey: PurchaseLandTestFixture.tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('You already own this tile'));
      });
    });
  });
}
