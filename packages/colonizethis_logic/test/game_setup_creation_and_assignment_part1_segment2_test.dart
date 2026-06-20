import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' show RegionData;


void main() {
  group('GameSetup', () {
    test(
      'init raises road level on shortest owned-tile path from OW town to capital (SPEC § Init town roads)',
      () {
        final owGrid = [
          ['p1', 'sea1'],
          ['p2', 'p1'],
        ];
        final owTopology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [
            TopologyEdge(id1: 'p1', id2: 'sea1'),
            TopologyEdge(id1: 'p2', id2: 'p1'),
          ],
        );
        final owTileMap = TileMapResult(width: 2, height: 2, grid: owGrid);

        final nwGrid = [
          ['nw1', 'sea1'],
          ['nw1', 'nw1'],
        ];
        final nwTopology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'nw1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: 'nw1', id2: 'sea1')],
        );
        final nwTileMap = TileMapResult(width: 2, height: 2, grid: nwGrid);

        final config = GameSetupConfig(
          selectedGreatPowerIds: ['england'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 1,
          numProvincesOldWorld: 2,
          numProvincesNewWorld: 1,
          minProvincesPerMinor: 0,
        );

        final result = createGameFromGeneratedMaps(
          config: config,
          tileMapOldWorld: owTileMap,
          topologyOldWorld: owTopology,
          tileMapNewWorld: nwTileMap,
          topologyNewWorld: nwTopology,
          gameId: 'test-town-roads',
        );

        final p2 = result.game.worldState.oldWorld.provinces.firstWhere(
          (p) => p.id == 'oldWorld|p2',
        );
        final tk = p2.townTileKey;
        expect(tk, isNotNull);
        expect(
          result.game.worldState.tileState.roadLevel(tk!),
          greaterThanOrEqualTo(1),
          reason: 'land-connected OW town needs init road link toward capital',
        );
      },
    );

    test(
      'initTownRoadWiringRegionIds empty skips town→capital road wiring',
      () {
        final owGrid = [
          ['p1', 'sea1'],
          ['p2', 'p1'],
        ];
        final owTopology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [
            TopologyEdge(id1: 'p1', id2: 'sea1'),
            TopologyEdge(id1: 'p2', id2: 'p1'),
          ],
        );
        final owTileMap = TileMapResult(width: 2, height: 2, grid: owGrid);
        final nwGrid = [
          ['nw1', 'sea1'],
          ['nw1', 'nw1'],
        ];
        final nwTopology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'nw1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: 'nw1', id2: 'sea1')],
        );
        final nwTileMap = TileMapResult(width: 2, height: 2, grid: nwGrid);

        final config = GameSetupConfig(
          selectedGreatPowerIds: ['england'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 1,
          numProvincesOldWorld: 2,
          numProvincesNewWorld: 1,
          minProvincesPerMinor: 0,
          initTownRoadWiringRegionIds: <String>{},
        );

        final result = createGameFromGeneratedMaps(
          config: config,
          tileMapOldWorld: owTileMap,
          topologyOldWorld: owTopology,
          tileMapNewWorld: nwTileMap,
          topologyNewWorld: nwTopology,
          gameId: 'test-town-roads-off',
        );

        final p2 = result.game.worldState.oldWorld.provinces.firstWhere(
          (p) => p.id == 'oldWorld|p2',
        );
        final tk = p2.townTileKey;
        expect(tk, isNotNull);
        expect(
          result.game.worldState.tileState.roadLevel(tk!),
          0,
          reason: 'wiring disabled: no init town roads on non-capital province',
        );
      },
    );

    test(
      'sea-bound same-region province town is placed on a sea-zone-adjacent tile',
      () {
        final owGrid = [
          ['p1', 'p1', 'sea1', 'sea1'],
          ['p1', 'p2', 'p2', 'sea1'],
          ['p1', 'p2', 'p2', 'sea1'],
        ];
        final owTopology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'p2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [
            TopologyEdge(id1: 'p1', id2: 'sea1'),
            TopologyEdge(id1: 'p2', id2: 'sea1'),
            TopologyEdge(id1: 'p1', id2: 'p2'),
          ],
        );
        final owTileMap = TileMapResult(width: 4, height: 3, grid: owGrid);

        final nwGrid = [
          ['nw1', 'sea1'],
          ['nw1', 'nw1'],
        ];
        final nwTopology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'nw1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: 'nw1', id2: 'sea1')],
        );
        final nwTileMap = TileMapResult(width: 2, height: 2, grid: nwGrid);

        final config = GameSetupConfig(
          selectedGreatPowerIds: ['england'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 1,
          numProvincesOldWorld: 2,
          numProvincesNewWorld: 1,
          minProvincesPerMinor: 0,
        );

        final result = createGameFromGeneratedMaps(
          config: config,
          tileMapOldWorld: owTileMap,
          topologyOldWorld: owTopology,
          tileMapNewWorld: nwTileMap,
          topologyNewWorld: nwTopology,
          gameId: 'test-seaboard-town-placement',
        );

        final p2 = result.game.worldState.oldWorld.provinces.firstWhere(
          (p) => p.id == 'oldWorld|p2',
        );
        expect(p2.townTileKey, isNotNull);
        expect(
          p2.townTileKey,
          'oldWorld|p2|2|2',
          reason:
              'sea-bound province town must be seaboard-valid and closest to '
              'province centroid before shortest-path tie-break',
        );
      },
    );
  });
}
