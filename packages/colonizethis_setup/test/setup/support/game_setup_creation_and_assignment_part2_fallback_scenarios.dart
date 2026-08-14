// Scenario table for GameSetup creation (part 2 fallback/misc) (Refs #4349 slice D).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart' show RegionData;
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';

import '../init_game_orchestrator_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario>
gameSetupCreationAndAssignmentPart2FallbackScenarios() => [
  rs(
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

      final config = configWithOverrides(
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
  ),
  rs(
    'each Great Power has enough resources to build 5 improvements (bootstrap)',
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
  ),
];
