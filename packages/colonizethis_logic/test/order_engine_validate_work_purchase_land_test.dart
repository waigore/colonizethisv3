import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('OrderEngine', () {
    group('validateWork (purchase_land)', () {
      const ow = 'oldWorld';
      const minorProvinceId = '$ow|M1';
      const tileKey = '$ow|M1|0|0';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: 'M1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'P1', id2: 'M1')],
      );

      Game baseGame({
        required int treasury,
        List<OvertureState>? overtureStates,
        List<DiplomacyRelation>? diplomacyRelations,
        Map<String, String>? resourceByTileKey,
        Map<String, Set<String>>? playerProspectedTiles,
        Map<String, String>? purchasedTilesByTileKey,
      }) {
        return Game(
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
            resourceByTileKey: resourceByTileKey ?? {tileKey: 'grain'},
            playerVisibilityByTile: const {
              'p1': {tileKey: 'fullyVisible'},
            },
            tileKeysByRegionAndProvince: {
              ow: {
                minorProvinceId: [tileKey],
                '$ow|P1': ['$ow|P1|0|0'],
              },
            },
            playerProspectedTiles: playerProspectedTiles ?? const {},
            purchasedTilesByTileKey: purchasedTilesByTileKey ?? const {},
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              capitalProvinceId: '$ow|P1',
              stockpile: const Stockpile(),
              treasury: treasury,
              techUnlocked: {kTechIdMerchantCompanies: true},
            ),
          ],
          minorNations: const [
            MinorNation(id: 'minor1', displayName: 'Minor 1'),
          ],
          overtureStates: overtureStates ?? [],
          diplomacyRelations: diplomacyRelations ?? [],
        );
      }

      test('rejects purchase_land when no embassy with Minor', () {
        final game = baseGame(treasury: 500);
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          const WorkOrder(
            unitId: 'merchant1',
            target: kWorkTargetPurchaseLand,
            targetTileKey: tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('embassy'));
      });

      test('rejects purchase_land when at war with faction', () {
        final game = baseGame(
          treasury: 500,
          overtureStates: [
            const OvertureState(
              gpId: 'p1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
          diplomacyRelations: [
            const DiplomacyRelation(
              factionId1: 'p1',
              factionId2: 'minor1',
              state: RelationState.atWar,
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          const WorkOrder(
            unitId: 'merchant1',
            target: kWorkTargetPurchaseLand,
            targetTileKey: tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('war'));
      });

      test('rejects purchase_land when insufficient treasury', () {
        const cost = 15 * 10; // grain default base 10
        final game = baseGame(
          treasury: cost - 1,
          overtureStates: [
            const OvertureState(
              gpId: 'p1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          const WorkOrder(
            unitId: 'merchant1',
            target: kWorkTargetPurchaseLand,
            targetTileKey: tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('Insufficient treasury'));
      });

      test('rejects purchase_land when tile has no resource', () {
        final game = baseGame(
          treasury: 500,
          overtureStates: [
            const OvertureState(
              gpId: 'p1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
          resourceByTileKey: {},
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          const WorkOrder(
            unitId: 'merchant1',
            target: kWorkTargetPurchaseLand,
            targetTileKey: tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('no resource'));
      });

      test('rejects purchase_land when mineral tile not prospected', () {
        final game = baseGame(
          treasury: 500,
          overtureStates: [
            const OvertureState(
              gpId: 'p1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
          resourceByTileKey: {tileKey: 'iron'},
          playerProspectedTiles: {}, // p1 has not prospected this tile
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          const WorkOrder(
            unitId: 'merchant1',
            target: kWorkTargetPurchaseLand,
            targetTileKey: tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('prospected'));
      });

      test(
        'accepts purchase_land with embassy, at peace, sufficient treasury, tile with resource',
        () {
          final game = baseGame(
            treasury: 500,
            overtureStates: [
              const OvertureState(
                gpId: 'p1',
                targetId: 'minor1',
                stage: OvertureStage.embassy,
                sinceTurn: 0,
              ),
            ],
          );
          final engine = OrderEngine();
          engine.addWorkOrder(
            'p1',
            const WorkOrder(
              unitId: 'merchant1',
              target: kWorkTargetPurchaseLand,
              targetTileKey: tileKey,
            ),
          );
          final results = engine.validatePlayerOrdersWithContext(
            game,
            topology,
            'p1',
          );
          expect(results.single.status, OrderValidationStatus.accepted);
        },
      );

      test(
        'rejects second Builder/Engineer/Merchant work order on same tile for same player (per-tile exclusivity)',
        () {
          const ow = 'oldWorld';
          const provinceId = '$ow|P1';
          const tileKey = '$ow|P1|0|0';
          final topology = MapTopology(
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
            topology,
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
        final game = baseGame(
          treasury: 500,
          overtureStates: [
            const OvertureState(
              gpId: 'p1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
          resourceByTileKey: {tileKey: 'iron'},
          playerProspectedTiles: {
            'p1': {tileKey},
          },
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          const WorkOrder(
            unitId: 'merchant1',
            target: kWorkTargetPurchaseLand,
            targetTileKey: tileKey,
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
          final game = baseGame(
            treasury: 500,
            overtureStates: [
              const OvertureState(
                gpId: 'p1',
                targetId: 'minor1',
                stage: OvertureStage.embassy,
                sinceTurn: 0,
              ),
            ],
            purchasedTilesByTileKey: {tileKey: 'p2'},
          );
          final engine = OrderEngine();
          engine.addWorkOrder(
            'p1',
            const WorkOrder(
              unitId: 'merchant1',
              target: kWorkTargetPurchaseLand,
              targetTileKey: tileKey,
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
        final game = baseGame(
          treasury: 500,
          overtureStates: [
            const OvertureState(
              gpId: 'p1',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
              sinceTurn: 0,
            ),
          ],
          purchasedTilesByTileKey: {tileKey: 'p1'},
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          const WorkOrder(
            unitId: 'merchant1',
            target: kWorkTargetPurchaseLand,
            targetTileKey: tileKey,
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
