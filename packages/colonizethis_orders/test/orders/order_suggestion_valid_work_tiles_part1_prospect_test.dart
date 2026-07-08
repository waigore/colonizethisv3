import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'support/suggestion/valid_work_tiles_test_support.dart';

void main() {
  group('getValidWorkOrderTileKeys', () {
    test(
      'getValidWorkOrderTileKeysWithVisibility prospect excludes non-mineral '
      'and already prospected',
      () {
        final provinceId = ValidWorkTilesTestSupport.provinceId('p1');
        final grassTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
        final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
        final p1 = Province(
          id: provinceId,
          regionId: ValidWorkTilesTestSupport.ow,
          ownerId: 'tribe1',
        );
        final unit = ValidWorkTilesTestSupport.explorerUnit(
          locationProvinceId: provinceId,
          tileKey: grassTile,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1], units: [unit]),
          newWorld: const RegionData(),
          playerVisibilityByTile: {
            ValidWorkTilesTestSupport.playerId: {
              grassTile: 'fogged',
              ironTile: 'fogged',
            },
          },
          resourceByTileKey: {grassTile: 'grain', ironTile: 'iron'},
          playerProspectedTiles: {
            ValidWorkTilesTestSupport.playerId: {ironTile},
          },
          tileKeysByRegionAndProvince:
              ValidWorkTilesTestSupport.tileKeysByProvince(
            {provinceId: [grassTile, ironTile]},
          ),
        );
        final game = Game(
          id: 'g1',
          worldState: world,
          players: const [ValidWorkTilesTestSupport.defaultPlayer],
          tribes: const [ValidWorkTilesTestSupport.defaultTribe],
          // Refs #3753 R4: a Consulate is required to prospect Tribe provinces.
          overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final view = buildPlayerView(
          game,
          topology,
          ValidWorkTilesTestSupport.playerId,
        );
        final valid = getValidWorkOrderTileKeysWithVisibility(
          game: game,
          topology: topology,
          view: view,
          unitId: 'u1',
          workTarget: kWorkTargetProspect,
          currentOrders: const Orders(),
        );
        expect(valid.contains(grassTile), isFalse);
        expect(valid.contains(ironTile), isFalse);
      },
    );

    test(
      'getValidWorkOrderTileKeysWithVisibility prospect includes eligible tile',
      () {
        final provinceId = ValidWorkTilesTestSupport.provinceId('p1');
        final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
        final p1 = Province(
          id: provinceId,
          regionId: ValidWorkTilesTestSupport.ow,
          ownerId: 'tribe1',
        );
        final unit = ValidWorkTilesTestSupport.explorerUnit(
          locationProvinceId: provinceId,
          tileKey: ironTile,
        );
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1], units: [unit]),
          newWorld: const RegionData(),
          playerVisibilityByTile: {
            ValidWorkTilesTestSupport.playerId: {ironTile: 'fogged'},
          },
          resourceByTileKey: {ironTile: 'iron'},
          tileKeysByRegionAndProvince:
              ValidWorkTilesTestSupport.tileKeysByProvince(
            {provinceId: [ironTile]},
          ),
        );
        final game = Game(
          id: 'g1',
          worldState: world,
          players: const [ValidWorkTilesTestSupport.defaultPlayer],
          tribes: const [ValidWorkTilesTestSupport.defaultTribe],
          // Refs #3753 R4: a Consulate is required to prospect Tribe provinces.
          overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final view = buildPlayerView(
          game,
          topology,
          ValidWorkTilesTestSupport.playerId,
        );
        final valid = getValidWorkOrderTileKeysWithVisibility(
          game: game,
          topology: topology,
          view: view,
          unitId: 'u1',
          workTarget: kWorkTargetProspect,
          currentOrders: const Orders(),
        );
        expect(valid, contains(ironTile));
      },
    );

    test(
      'getValidWorkOrderTileKeysWithVisibility prospect excludes wool on hills '
      'when tile map marks hills (terrain-only eligibility must not apply)',
      () {
        final provinceId = ValidWorkTilesTestSupport.provinceId('p1');
        final woolTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
        final p1 = Province(
          id: provinceId,
          regionId: ValidWorkTilesTestSupport.ow,
          ownerId: 'tribe1',
        );
        final unit = ValidWorkTilesTestSupport.explorerUnit(
          locationProvinceId: provinceId,
          tileKey: woolTile,
        );
        final tileMapByRegion = <String, TileMapResult>{
          ValidWorkTilesTestSupport.ow: TileMapResult(
            width: 1,
            height: 1,
            grid: const [
              ['p1'],
            ],
            terrainGrid: const [
              [TerrainType.hills],
            ],
            resourceGrid: const [
              [Resource.wool],
            ],
          ),
        };
        final world = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(provinces: [p1], units: [unit]),
          newWorld: const RegionData(),
          playerVisibilityByTile: {
            ValidWorkTilesTestSupport.playerId: {woolTile: 'fogged'},
          },
          resourceByTileKey: {woolTile: 'wool'},
          tileKeysByRegionAndProvince:
              ValidWorkTilesTestSupport.tileKeysByProvince(
            {provinceId: [woolTile]},
          ),
        );
        final game = Game(
          id: 'g1',
          worldState: world,
          players: const [ValidWorkTilesTestSupport.defaultPlayer],
          tribes: const [ValidWorkTilesTestSupport.defaultTribe],
          // Refs #3753 R4: a Consulate is required to prospect Tribe provinces.
          overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
        );
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final view = buildPlayerView(
          game,
          topology,
          ValidWorkTilesTestSupport.playerId,
        );
        final valid = getValidWorkOrderTileKeysWithVisibility(
          game: game,
          topology: topology,
          view: view,
          unitId: 'u1',
          workTarget: kWorkTargetProspect,
          currentOrders: const Orders(),
          tileMapByRegion: tileMapByRegion,
        );
        expect(valid.contains(woolTile), isFalse);
      },
    );
  });
}
