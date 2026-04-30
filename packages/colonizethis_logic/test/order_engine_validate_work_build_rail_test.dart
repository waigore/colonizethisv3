import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('OrderEngine', () {
    group('validateWork (build_rail)', () {
      const ow = 'oldWorld';
      const provinceId = '$ow|P1';
      const tileKey = '$provinceId|0|0';

      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );

      TileMapResult railTileMap(TerrainType terrain) => TileMapResult(
        width: 1,
        height: 1,
        grid: const [
          ['P1'],
        ],
        terrainGrid: [
          [terrain],
        ],
      );

      Stockpile railStockpile() => Stockpile()
          .applyDelta(CommodityCatalog.lumber.id, 10)
          .applyDelta(CommodityCatalog.steel.id, 10);

      Game gameWithRailUnit({
        required TileMapState tileState,
        Map<String, bool>? techUnlocked,
        Stockpile? stockpile,
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
                  id: 'rail1',
                  type: kUnitTypeRailBuilder,
                  ownerId: 'p1',
                  locationProvinceId: provinceId,
                  tileKey: tileKey,
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileState: tileState,
            tileKeysByRegionAndProvince: {
              ow: {
                provinceId: [tileKey],
              },
            },
            playerVisibilityByTile: const {
              'p1': {tileKey: 'fullyVisible'},
            },
          ),
          players: [
            Player(
              id: 'p1',
              displayName: 'P1',
              isHuman: true,
              capitalProvinceId: provinceId,
              stockpile: stockpile ?? railStockpile(),
              techUnlocked: techUnlocked ?? const {kTechIdEarlySteamEngine: true},
            ),
          ],
        );
      }

      test('rejects build_rail when tile terrain data is missing', () {
        final game = gameWithRailUnit(
          tileState: TileMapState().setRoadLevel(tileKey, 1),
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          const WorkOrder(
            unitId: 'rail1',
            target: kWorkTargetBuildRail,
            targetTileKey: tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
          tileMapByRegion: null,
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('terrain data required'));
      });

      test('rejects build_rail when road level is 0', () {
        final game = gameWithRailUnit(
          tileState: TileMapState().setRoadLevel(tileKey, 0),
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          const WorkOrder(
            unitId: 'rail1',
            target: kWorkTargetBuildRail,
            targetTileKey: tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
          tileMapByRegion: {ow: railTileMap(TerrainType.plains)},
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('existing road'));
      });

      test('rejects build_rail on hills with only Early Steam', () {
        final game = gameWithRailUnit(
          tileState: TileMapState().setRoadLevel(tileKey, 1),
          techUnlocked: const {kTechIdEarlySteamEngine: true},
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          const WorkOrder(
            unitId: 'rail1',
            target: kWorkTargetBuildRail,
            targetTileKey: tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
          tileMapByRegion: {ow: railTileMap(TerrainType.hills)},
        );
        expect(results.single.status, OrderValidationStatus.rejected);
        expect(results.single.reason, contains('Later Steam'));
      });

      test('accepts build_rail on plains with Early Steam and road 1', () {
        final game = gameWithRailUnit(
          tileState: TileMapState().setRoadLevel(tileKey, 1),
        );
        final engine = OrderEngine();
        engine.addWorkOrder(
          'p1',
          const WorkOrder(
            unitId: 'rail1',
            target: kWorkTargetBuildRail,
            targetTileKey: tileKey,
          ),
        );
        final results = engine.validatePlayerOrdersWithContext(
          game,
          topology,
          'p1',
          tileMapByRegion: {ow: railTileMap(TerrainType.plains)},
        );
        expect(results.single.status, OrderValidationStatus.accepted);
      });
    });
  });
}
