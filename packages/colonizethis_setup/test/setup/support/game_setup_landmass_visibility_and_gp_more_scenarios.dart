// Scenario table densify (Refs #4349 Slice C).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import '../init_game_orchestrator_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> gameSetupLandmassVisibilityAndGpScenariosMore() => [
  rs('sea tiles have visibility set (OW fogged, NW unknown)', () {
    // OW: 1 province (p1) + 1 sea zone (sea1)
    // NW:1 province (nw1) + 1 sea zone (sea1)
    final owGrid = [
      ['p1', 'sea1'],
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
    final owTileMap = TileMapResult(width: 2, height: 1, grid: owGrid);

    final nwGrid = [
      ['nw1', 'sea1'],
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
    final nwTileMap = TileMapResult(width: 2, height: 1, grid: nwGrid);

    final config = configWithOverrides(
      selectedGreatPowerIds: ['england'],
      continentCount: 1,
      minorNationCount: 0,
      tribeCount: 1,
      numProvincesOldWorld: 1,
      numProvincesNewWorld: 1,
      minProvincesPerMinor: 0,
    );

    final result = createGameFromGeneratedMaps(
      config: config,
      tileMapOldWorld: owTileMap,
      topologyOldWorld: owTopology,
      tileMapNewWorld: nwTileMap,
      topologyNewWorld: nwTopology,
      gameId: 'sea-visibility-test',
    );

    final vis = result.game.worldState.playerVisibilityByTile;
    final gpId = result.game.players.first.id;

    // Old World sea tile (sea1) should be fullyVisible because it's adjacent
    // to the GP's province (p1). Coastal sea zone visibility is applied at
    // game setup per SPEC/program/fog-and-exploration-resolution.md.
    final owSeaTileKey = 'oldWorld|sea1|1|0';
    expect(
      vis[gpId],
      contains(owSeaTileKey),
      reason: 'OW sea tile must be in visibility map',
    );
    expect(
      vis[gpId]![owSeaTileKey],
      'fullyVisible',
      reason:
          'OW sea tile adjacent to owned province should be fullyVisible'
          ' at game setup (coastal sea zone visibility)',
    );

    // New World sea tile (sea1) should be unknown (no GP owns adjacent province)
    final nwSeaTileKey = 'newWorld|sea1|1|0';
    expect(
      vis[gpId],
      contains(nwSeaTileKey),
      reason: 'NW sea tile must be in visibility map',
    );
    expect(
      vis[gpId]![nwSeaTileKey],
      'unknown',
      reason: 'NW sea tile should be unknown (no GP owns adjacent province)',
    );

    // Verify land tiles also have visibility
    final owLandTileKey = 'oldWorld|p1|0|0';
    expect(
      vis[gpId],
      contains(owLandTileKey),
      reason: 'OW land tile must be in visibility map',
    );
    // Own province should be fullyVisible
    expect(
      vis[gpId]![owLandTileKey],
      'fullyVisible',
      reason: 'OW own province should be fully visible',
    );

    final nwLandTileKey = 'newWorld|nw1|0|0';
    expect(
      vis[gpId],
      contains(nwLandTileKey),
      reason: 'NW land tile must be in visibility map',
    );
    // New World should be unknown
    expect(
      vis[gpId]![nwLandTileKey],
      'unknown',
      reason: 'NW land tile should be unknown',
    );
  }),
];
