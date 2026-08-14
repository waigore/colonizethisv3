// Scenario table for GameSetup creation (segment 1 repeat/misc) (Refs #4349 slice D).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../init_game_orchestrator_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario>
gameSetupCreationAndAssignmentPart1Segment1RepeatScenarios() => [
  rs(
    'createGameFromGeneratedMaps assigns identical townTileKeys on repeated runs',
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
      final config = configWithOverrides(
        selectedGreatPowerIds: ['england'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 2,
        numProvincesNewWorld: 1,
        minProvincesPerMinor: 0,
        seed: 9001,
      );
      final owMap = TileMapResult(width: 2, height: 2, grid: owGrid);
      final nwMap = TileMapResult(width: 2, height: 2, grid: nwGrid);
      Map<String, String?> towns(GameSetupResult r) => {
        for (final p in allProvinces(r.game.worldState)) p.id: p.townTileKey,
      };
      final r1 = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: owMap,
        topologyOldWorld: owTopology,
        tileMapNewWorld: nwMap,
        topologyNewWorld: nwTopology,
        gameId: 'town-determinism-a',
      );
      final r2 = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: owMap,
        topologyOldWorld: owTopology,
        tileMapNewWorld: nwMap,
        topologyNewWorld: nwTopology,
        gameId: 'town-determinism-b',
      );
      expect(towns(r2), towns(r1));
    },
  ),
  rs(
    'createGameFromGeneratedMaps honors preferredInitialMapZoomMultiplier with clamp',
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

      final preferredConfig = configWithOverrides(
        selectedGreatPowerIds: ['england'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 2,
        numProvincesNewWorld: 1,
        minProvincesPerMinor: 0,
        preferredInitialMapZoomMultiplier: 3.25,
      );
      final preferredResult = createGameFromGeneratedMaps(
        config: preferredConfig,
        tileMapOldWorld: TileMapResult(width: 2, height: 2, grid: owGrid),
        topologyOldWorld: owTopology,
        tileMapNewWorld: TileMapResult(width: 2, height: 2, grid: nwGrid),
        topologyNewWorld: nwTopology,
        gameId: 'preferred-map-zoom',
      );
      expect(preferredResult.game.mapViewState.zoomMultiplier, 3.25);
      expect(preferredResult.game.mapViewState.showPlayersBar, isFalse);

      final clampedConfig = configWithOverrides(
        selectedGreatPowerIds: ['england'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 2,
        numProvincesNewWorld: 1,
        minProvincesPerMinor: 0,
        preferredInitialMapZoomMultiplier: 9.0,
      );
      final clampedResult = createGameFromGeneratedMaps(
        config: clampedConfig,
        tileMapOldWorld: TileMapResult(width: 2, height: 2, grid: owGrid),
        topologyOldWorld: owTopology,
        tileMapNewWorld: TileMapResult(width: 2, height: 2, grid: nwGrid),
        topologyNewWorld: nwTopology,
        gameId: 'clamped-map-zoom',
      );
      expect(clampedResult.game.mapViewState.zoomMultiplier, 8.0);
      expect(clampedResult.game.mapViewState.showPlayersBar, isFalse);
    },
  ),
];
