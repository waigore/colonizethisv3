import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('OrderEngine', () {
    group('validateWork (build_improvement)', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      const tileKey = '$provinceId|0|0';

      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );

      Game baseGame({
        Map<String, String>? resourceByTileKey,
        TileMapState tileState = const TileMapState(),
        Map<String, bool>? techUnlocked,
        Stockpile? stockpile,
        Map<String, Set<String>>? playerProspectedTiles,
      }) {
        return Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
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
              ],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: resourceByTileKey ?? {tileKey: 'grain'},
            tileState: tileState,
            tileKeysByRegionAndProvince: {
              ow: {
                provinceId: [tileKey],
              },
            },
            playerVisibilityByTile: const {
              'p1': {tileKey: 'fullyVisible'},
            },
            playerProspectedTiles: playerProspectedTiles ?? const {},
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              capitalProvinceId: provinceId,
              stockpile:
                  stockpile ??
                  Stockpile()
                      .applyDelta(CommodityCatalog.lumber.id, 2)
                      .applyDelta(CommodityCatalog.castIron.id, 2),
              techUnlocked: techUnlocked ?? const {kTechIdCircularSaw: true},
            ),
          ],
        );
      }

      test(
        'rejects build_improvement on mineral tile when not prospected',
        () {
          final game = baseGame(
            resourceByTileKey: {tileKey: 'iron'},
          );
          final engine = OrderEngine();
          engine.addWorkOrder(
            'p1',
            const WorkOrder(
              unitId: 'builder1',
              target: kWorkTargetBuildImprovement,
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
        },
      );

      test(
        'accepts build_improvement on mineral tile after prospected',
        () {
          final game = baseGame(
            resourceByTileKey: {tileKey: 'iron'},
            playerProspectedTiles: {
              'p1': {tileKey},
            },
          );
          final engine = OrderEngine();
          engine.addWorkOrder(
            'p1',
            const WorkOrder(
              unitId: 'builder1',
              target: kWorkTargetBuildImprovement,
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
        'accepts build_improvement on grain when tile not prospected',
        () {
          final game = baseGame(resourceByTileKey: {tileKey: 'grain'});
          final engine = OrderEngine();
          engine.addWorkOrder(
            'p1',
            const WorkOrder(
              unitId: 'builder1',
              target: kWorkTargetBuildImprovement,
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

      test('rejects build_improvement when tile has no resource', () {
        final game = baseGame(resourceByTileKey: {});
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          const WorkOrder(
            unitId: 'builder1',
            target: kWorkTargetBuildImprovement,
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

      test('rejects build_improvement when improvement level already 4', () {
        final game = baseGame(
          tileState: const TileMapState(
            improvementByTile: {'oldWorld|P1|0|0': 4},
          ),
          stockpile: Stockpile()
              .applyDelta(CommodityCatalog.lumber.id, 20)
              .applyDelta(CommodityCatalog.castIron.id, 20),
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          const WorkOrder(
            unitId: 'builder1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('maximum'));
      });

      test(
        'rejects build_improvement when tech cap would be exceeded (empty tech)',
        () {
          final game = baseGame(
            techUnlocked: const {},
            tileState: const TileMapState(
              improvementByTile: {'oldWorld|P1|0|0': 1},
            ),
            stockpile: Stockpile()
                .applyDelta(CommodityCatalog.lumber.id, 10)
                .applyDelta(CommodityCatalog.castIron.id, 10),
          );
          final engine = OrderEngine();
          engine.addWorkOrder(
            'p1',
            const WorkOrder(
              unitId: 'builder1',
              target: kWorkTargetBuildImprovement,
              targetTileKey: tileKey,
            ),
          );
          final results = engine.validatePlayerOrdersWithContext(
            game,
            topology,
            'p1',
          );
          expect(results.single.status, OrderValidationStatus.rejected);
          expect(results.single.reason, contains('Insufficient tech'));
          expect(results.single.reason, contains('grain'));
          expect(results.single.reason, contains('cap 1'));
        },
      );

      test('rejects build_improvement when tech cap would be exceeded', () {
        // With no grain-cap tech, grain stays at cap 1; tile at level 1 cannot upgrade.
        final game = baseGame(
          techUnlocked: const {kTechIdSawMill: true},
          tileState: const TileMapState(
            improvementByTile: {'oldWorld|P1|0|0': 1},
          ),
          stockpile: Stockpile()
              .applyDelta(CommodityCatalog.lumber.id, 10)
              .applyDelta(CommodityCatalog.castIron.id, 10),
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          const WorkOrder(
            unitId: 'builder1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('Insufficient tech'));
        expect(results.single.reason, contains('cap 1'));
      });

      test(
        'accepts grain upgrade when exact next-level grain tech is unlocked',
        () {
          final game = baseGame(
            techUnlocked: const {kTechIdLandEnclosure: true},
            tileState: const TileMapState(
              improvementByTile: {'oldWorld|P1|0|0': 1},
            ),
            stockpile: Stockpile()
                .applyDelta(CommodityCatalog.lumber.id, 10)
                .applyDelta(CommodityCatalog.castIron.id, 10),
          );
          final engine = OrderEngine();
          engine.addWorkOrder(
            'p1',
            const WorkOrder(
              unitId: 'builder1',
              target: kWorkTargetBuildImprovement,
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
        'accepts build_improvement when tile has resource, level < 4, tech cap allows',
        () {
          final game = baseGame(
            resourceByTileKey: {tileKey: 'grain'},
            tileState: const TileMapState(),
            techUnlocked: const {kTechIdCircularSaw: true},
          );
          final engine = OrderEngine();
          engine.addWorkOrder(
            'p1',
            const WorkOrder(
              unitId: 'builder1',
              target: kWorkTargetBuildImprovement,
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

      test('rejects build_improvement in foreign, unpurchased province', () {
        final foreignProvinceId = '$ow|P2';
        final foreignTileKey = '$foreignProvinceId|0|0';
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: provinceId, regionId: ow, ownerId: 'p1'),
                Province(id: foreignProvinceId, regionId: ow, ownerId: 'p2'),
              ],
              units: [
                Unit(
                  id: 'builder1',
                  type: kUnitTypeBuilder,
                  ownerId: 'p1',
                  locationProvinceId: provinceId,
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
            resourceByTileKey: {tileKey: 'grain', foreignTileKey: 'grain'},
            tileState: const TileMapState(),
            tileKeysByRegionAndProvince: {
              ow: {
                provinceId: [tileKey],
                foreignProvinceId: [foreignTileKey],
              },
            },
            playerVisibilityByTile: {
              'p1': {tileKey: 'fullyVisible', foreignTileKey: 'fullyVisible'},
            },
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              capitalProvinceId: provinceId,
              stockpile: Stockpile()
                  .applyDelta(CommodityCatalog.lumber.id, 2)
                  .applyDelta(CommodityCatalog.castIron.id, 2),
              techUnlocked: const {kTechIdCircularSaw: true},
            ),
            const Player(id: 'p2', displayName: 'P2', isHuman: false),
          ],
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          WorkOrder(
            unitId: 'builder1',
            target: kWorkTargetBuildImprovement,
            targetTileKey: foreignTileKey,
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
          contains('foreign or uncontrolled province'),
        );
      });
    });
  });
}
