// Scenario table for GameSetup creation (part 2 town rank) (Refs #4349 slice D).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';

import '../init_game_orchestrator_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario>
gameSetupCreationAndAssignmentPart2TownRankScenarios() => [
  rs(
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

      final config = configWithOverrides(
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
  ),
  rs(
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

      final config = configWithOverrides(
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
  ),
];
