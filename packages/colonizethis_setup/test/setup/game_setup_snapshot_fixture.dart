import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';

import 'init_game_orchestrator_test_support.dart';

/// Shared snapshot maps for [game_setup_snapshot_test.dart] (Refs #4624).
GameSetupResult gameSetupSnapshotFixture() {
  final owGrid = [
    ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
    ['sea1', 'sea1', 'p7', 'p8', 'p9', 'p10'],
  ];
  final owTopology = MapTopology(
    nodes: [
      for (var i = 1; i <= 10; i++)
        TopologyNode(
          id: 'p$i',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
      const TopologyNode(
        id: 'sea1',
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [
      const TopologyEdge(id1: 'p1', id2: 'sea1'),
      const TopologyEdge(id1: 'p2', id2: 'sea1'),
      const TopologyEdge(id1: 'p1', id2: 'p2'),
      const TopologyEdge(id1: 'p2', id2: 'p3'),
      const TopologyEdge(id1: 'p3', id2: 'p4'),
      const TopologyEdge(id1: 'p4', id2: 'p5'),
      const TopologyEdge(id1: 'p5', id2: 'p6'),
      const TopologyEdge(id1: 'p3', id2: 'p7'),
      const TopologyEdge(id1: 'p7', id2: 'p8'),
      const TopologyEdge(id1: 'p8', id2: 'p9'),
      const TopologyEdge(id1: 'p9', id2: 'p10'),
      const TopologyEdge(id1: 'p4', id2: 'p8'),
      const TopologyEdge(id1: 'p5', id2: 'p9'),
      const TopologyEdge(id1: 'p6', id2: 'p10'),
      const TopologyEdge(id1: 'p7', id2: 'sea1'),
    ],
  );
  final owTileMap = TileMapResult(width: 6, height: 2, grid: owGrid);

  final nwGrid = [
    ['nw1', 'nw2', 'nw3'],
    ['nwSea', 'nwSea', 'nwSea'],
  ];
  final nwTopology = MapTopology(
    nodes: [
      for (final id in ['nw1', 'nw2', 'nw3'])
        TopologyNode(
          id: id,
          regionId: 'newWorld',
          type: TopologyNodeType.province,
        ),
      const TopologyNode(
        id: 'nwSea',
        regionId: 'newWorld',
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [
      const TopologyEdge(id1: 'nw1', id2: 'nwSea'),
      const TopologyEdge(id1: 'nw2', id2: 'nwSea'),
      const TopologyEdge(id1: 'nw3', id2: 'nwSea'),
      const TopologyEdge(id1: 'nw1', id2: 'nw2'),
      const TopologyEdge(id1: 'nw2', id2: 'nw3'),
    ],
  );
  final nwTileMap = TileMapResult(width: 3, height: 2, grid: nwGrid);

  final config = configWithOverrides(
    selectedGreatPowerIds: ['england', 'france'],
    continentCount: 1,
    minorNationCount: 1,
    tribeCount: 3,
    numProvincesOldWorld: 10,
    numProvincesNewWorld: 3,
    minProvincesPerMinor: 2,
    seed: 42,
  );

  return createGameFromGeneratedMaps(
    config: config,
    tileMapOldWorld: owTileMap,
    topologyOldWorld: owTopology,
    tileMapNewWorld: nwTileMap,
    topologyNewWorld: nwTopology,
    gameId: 'char-snapshot',
    namingSeed: 42,
  );
}
