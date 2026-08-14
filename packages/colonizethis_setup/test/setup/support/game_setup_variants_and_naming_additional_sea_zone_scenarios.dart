// Scenario table for GameSetup additional naming (sea zones) (Refs #4349 slice D).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_test/test.dart';

import '../init_game_orchestrator_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario>
gameSetupVariantsAndNamingAdditionalSeaZoneScenarios() => [
  rs(
    'single tribe with more NW provinces than pool uses procedural names without duplicates',
    () {
      final nwNodes = <TopologyNode>[
        const TopologyNode(
          id: 'sea',
          regionId: 'newWorld',
          type: TopologyNodeType.seaZone,
        ),
        for (var i = 1; i <= 6; i++)
          TopologyNode(
            id: 'n$i',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
      ];
      final nwEdges = <TopologyEdge>[
        for (var i = 1; i <= 6; i++) TopologyEdge(id1: 'n$i', id2: 'sea'),
        for (var i = 1; i < 6; i++) TopologyEdge(id1: 'n$i', id2: 'n${i + 1}'),
      ];
      final nwTopology = MapTopology(nodes: nwNodes, edges: nwEdges);
      final nwTileMap = TileMapResult(
        width: 6,
        height: 2,
        grid: const [
          ['n1', 'n2', 'n3', 'n4', 'n5', 'n6'],
          ['sea', 'sea', 'sea', 'sea', 'sea', 'sea'],
        ],
      );

      final owTopology = MapTopology(
        nodes: const [
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
        edges: const [TopologyEdge(id1: 'p1', id2: 'sea1')],
      );
      final owTileMap = TileMapResult(
        width: 1,
        height: 2,
        grid: const [
          ['p1'],
          ['sea1'],
        ],
      );

      final config = configWithOverrides(
        selectedGreatPowerIds: ['england'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 1,
        numProvincesNewWorld: 6,
        minProvincesPerMinor: 0,
        seed: 77,
      );

      final result = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: owTileMap,
        topologyOldWorld: owTopology,
        tileMapNewWorld: nwTileMap,
        topologyNewWorld: nwTopology,
        gameId: 'tribe-pool-overflow',
        namingSeed: 77,
      );

      final nwProvinces = result.game.worldState.newWorld.provinces;
      final names = nwProvinces.map((p) => p.displayName!).toList();
      expect(names.length, 6);
      expect(names.length, names.toSet().length);
      for (final p in nwProvinces) {
        expect(p.displayName, isNotNull);
        expect(p.displayName!.isNotEmpty, isTrue, reason: p.id);
      }
    },
  ),
  rs('sea-zone naming is deterministic for same seed/topology', () {
    final topology = MapTopology(
      nodes: const [
        TopologyNode(
          id: 'p1',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 's1',
          regionId: 'oldWorld',
          type: TopologyNodeType.seaZone,
        ),
        TopologyNode(
          id: 's2',
          regionId: 'oldWorld',
          type: TopologyNodeType.seaZone,
        ),
      ],
      edges: const [
        TopologyEdge(id1: 'p1', id2: 's1'),
        TopologyEdge(id1: 's1', id2: 's2'),
      ],
    );
    final config = configWithOverrides(
      selectedGreatPowerIds: ['england'],
      continentCount: 1,
      minorNationCount: 0,
      tribeCount: 1,
      numProvincesOldWorld: 1,
      numProvincesNewWorld: 1,
      minProvincesPerMinor: 0,
      seed: 99,
    );
    Game run(String id) => createGameFromGeneratedMaps(
      config: config,
      tileMapOldWorld: TileMapResult(
        width: 2,
        height: 2,
        grid: [
          ['p1', 'p1'],
          ['s1', 's2'],
        ],
      ),
      topologyOldWorld: topology,
      tileMapNewWorld: TileMapResult(
        width: 1,
        height: 2,
        grid: [
          ['n1'],
          ['ns1'],
        ],
      ),
      topologyNewWorld: const MapTopology(
        nodes: [
          TopologyNode(
            id: 'n1',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'ns1',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [TopologyEdge(id1: 'n1', id2: 'ns1')],
      ),
      gameId: id,
      namingSeed: 99,
    ).game;
    final first = run('det-1');
    final second = run('det-2');
    expect(
      first.worldState.seaZoneDisplayNameById,
      second.worldState.seaZoneDisplayNameById,
    );
  }),
];
