import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart' show RegionData;

void main() {
  group('GameSetup', () {
    test(
      'same-region non-seaboard province town ranks centroid before BFS to capital',
      () {
        final owGrid = [
          ['p1', 'p2', 'p2'],
          ['p1', 'p1', 'p2'],
          ['sea1', 'sea1', 'sea1'],
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
            TopologyEdge(id1: 'p1', id2: 'p2'),
          ],
        );
        final owTileMap = TileMapResult(width: 3, height: 3, grid: owGrid);

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
          gameId: 'test-centroid-before-bfs',
        );

        final p2 = result.game.worldState.oldWorld.provinces.firstWhere(
          (p) => p.id == 'oldWorld|p2',
        );
        expect(
          p2.townTileKey,
          'oldWorld|p2|2|0',
          reason:
              'p2 centroid favors (2,0) over (1,0) even though BFS from capital '
              'is shorter to (1,0)',
        );
      },
    );

    test(
      'sea-bound mismatch falls back to full-tile centroid then BFS selection',
      () {
        final owGrid = [
          ['p1', 'p1', 'sea1'],
          ['p1', 'p2', 'p1'],
          ['p1', 'p1', 'p1'],
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
        final owTileMap = TileMapResult(width: 3, height: 3, grid: owGrid);

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
          gameId: 'test-seaboard-town-fallback',
        );

        final p2 = result.game.worldState.oldWorld.provinces.firstWhere(
          (p) => p.id == 'oldWorld|p2',
        );
        expect(
          p2.townTileKey,
          'oldWorld|p2|1|1',
          reason:
              'when no sea-zone-adjacent tile exists, seaboard town selection '
              'falls back to all tiles with centroid-then-BFS ordering',
        );
      },
    );

    test(
      'overseas province (capital in other region, no port) picks town by centroid',
      () {
        final owGrid = [
          ['p1', 'sea1'],
          ['p1', 'p1'],
        ];
        final owTopology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: [TopologyEdge(id1: 'p1', id2: 'sea1')],
        );
        final owTileMap = TileMapResult(width: 2, height: 2, grid: owGrid);

        final nwGrid = [
          ['col', 'col', 'col'],
          ['col', 'col', 'col'],
        ];
        final nwTopology = MapTopology(
          nodes: [
            TopologyNode(
              id: 'col',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final nwTileMap = TileMapResult(width: 3, height: 2, grid: nwGrid);

        final config = GameSetupConfig(
          selectedGreatPowerIds: ['england'],
          continentCount: 1,
          minorNationCount: 0,
          tribeCount: 0,
          numProvincesOldWorld: 1,
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
          gameId: 'test-overseas-centroid',
        );

        var game = result.game;
        final nwProvinces = game.worldState.newWorld.provinces.map((p) {
          if (p.id == 'newWorld|col') {
            return p.copyWith(ownerId: 'gp1');
          }
          return p;
        }).toList();
        game = game.copyWith(
          worldState: game.worldState.copyWith(
            newWorld: RegionData(
              provinces: nwProvinces,
              units: game.worldState.newWorld.units,
            ),
          ),
        );

        game = assignProvinceTownsForTesting(
          game: game,
          topologyByRegion: result.topologyByRegion,
          tileMapByRegion: result.tileMapByRegion,
        );

        final col = game.worldState.newWorld.provinces.firstWhere(
          (p) => p.id == 'newWorld|col',
        );
        expect(
          col.townTileKey,
          'newWorld|col|1|1',
          reason:
              'GP capital in oldWorld; inland NW province has no port — town is '
              'the tile at rounded centroid (1,1), with lexicographic key as '
              'final tie-break when BFS to capital is not applicable',
        );
      },
    );

    test(
      'each Great Power has enough resources to build 5 improvements (bootstrap)',
      () {
        // SPEC/program/game-setup-pipeline.md section 7f: initialImprovementSlots default 5.
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
          gameId: 'test-bootstrap',
        );
        final start = config.startingResources;
        final expectedGrain = start.initialPeasants * start.initialGrainTurns;
        for (final player in result.game.players) {
          expect(
            player.stockpile.quantityOf(CommodityCatalog.grain.id),
            expectedGrain,
            reason: '${player.id} grain',
          );
          expect(
            player.stockpile.quantityOf(CommodityCatalog.lumber.id),
            start.initialImprovementSlots,
            reason: '${player.id} lumber for 5 improvements',
          );
          expect(
            player.stockpile.quantityOf(CommodityCatalog.castIron.id),
            start.initialImprovementSlots,
            reason: '${player.id} castIron for 5 improvements',
          );
          expect(
            player.stockpile.quantityOf(CommodityCatalog.wool.id),
            start.initialWool,
            reason: '${player.id} starting wool',
          );
          expect(
            player.stockpile.quantityOf(CommodityCatalog.paper.id),
            start.initialPaper,
            reason: '${player.id} starting paper',
          );
        }
      },
    );
  });
}
