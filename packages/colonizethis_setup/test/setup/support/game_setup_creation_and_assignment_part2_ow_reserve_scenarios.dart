// Scenario table for GameSetup OW minor reserve assignment (Refs #4349 slice D).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';

import '../init_game_orchestrator_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario>
gameSetupCreationAndAssignmentPart2OwReserveScenarios() => [
  rs('Old World assignment reserves provinces for minors based on config', () {
    final owNodes = <TopologyNode>[
      const TopologyNode(
        id: 'sea1',
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
      for (var i = 1; i <= 12; i++)
        TopologyNode(
          id: 'p$i',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
    ];
    final owEdges = <TopologyEdge>[
      const TopologyEdge(id1: 'p1', id2: 'sea1'),
      const TopologyEdge(id1: 'p2', id2: 'sea1'),
      const TopologyEdge(id1: 'p12', id2: 'sea1'),
      for (var i = 1; i < 12; i++) TopologyEdge(id1: 'p$i', id2: 'p${i + 1}'),
    ];
    final owTopology = MapTopology(nodes: owNodes, edges: owEdges);
    final owTileMap = TileMapResult(
      width: 12,
      height: 2,
      grid: [
        [for (var i = 1; i <= 12; i++) 'p$i'],
        [for (var i = 1; i <= 12; i++) 'sea1'],
      ],
    );

    final nwTopology = MapTopology(
      nodes: const [
        TopologyNode(
          id: 'nw1',
          regionId: 'newWorld',
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 'nwSea',
          regionId: 'newWorld',
          type: TopologyNodeType.seaZone,
        ),
      ],
      edges: const [TopologyEdge(id1: 'nw1', id2: 'nwSea')],
    );
    final nwTileMap = TileMapResult(
      width: 1,
      height: 2,
      grid: const [
        ['nw1'],
        ['nwSea'],
      ],
    );

    const minorCount = 2;
    const minPerMinor = 3;
    const totalOw = 12;
    const availableForGps = totalOw - (minorCount * minPerMinor);

    final config = configWithOverrides(
      selectedGreatPowerIds: ['england', 'france'],
      continentCount: 1,
      minorNationCount: minorCount,
      tribeCount: 1,
      numProvincesOldWorld: totalOw,
      numProvincesNewWorld: 1,
      minProvincesPerMinor: minPerMinor,
    );

    final result = createGameFromGeneratedMaps(
      config: config,
      tileMapOldWorld: owTileMap,
      topologyOldWorld: owTopology,
      tileMapNewWorld: nwTileMap,
      topologyNewWorld: nwTopology,
      gameId: 'ow-reservation',
    );

    final ow = result.game.worldState.oldWorld.provinces;
    final gpOwned = ow
        .where((p) => p.ownerId == 'gp1' || p.ownerId == 'gp2')
        .length;
    final minorOwned = ow
        .where((p) => p.ownerId == 'minor1' || p.ownerId == 'minor2')
        .length;

    expect(gpOwned, availableForGps);
    expect(minorOwned, totalOw - availableForGps);
    for (final minor in result.game.minorNations) {
      final minorCapitalTile = minor.capitalTile;
      expect(minorCapitalTile, isNotNull);
      final minorUnits = result.game.worldState.oldWorld.units
          .where((u) => u.ownerId == minor.id && u.tileKey != null)
          .toList();
      expect(minorUnits, isNotEmpty);
      for (final unit in minorUnits) {
        expect(unit.tileKey, minorCapitalTile!.toTileKey());
      }
    }
  }),
];
