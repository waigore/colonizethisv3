// Scenario table densify (Refs #4349 Slice C).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import '../init_game_orchestrator_test_support.dart';
import 'scenario_runner.dart';

List<RunnableScenario> gameSetupVariantsAndNamingScenariosMore() => [
  rs('allGreatPowerIds has 7 entries (no prussia_reserve)', () {
    expect(allGreatPowerIds.length, 7);
    expect(allGreatPowerIds, contains('prussia'));
    expect(allGreatPowerIds, isNot(contains('prussia_reserve')));
  }),
  rs('province naming fallback when tribe count exceeds naming config', () {
    // Default naming has tribe1..tribe10. Use 11 tribes so tribe11 uses fallback.
    final nwGrid = [
      ['n1', 'n2', 'n3', 'n4', 'n5', 'n6', 'n7', 'n8', 'n9', 'n10', 'n11'],
      [
        'sea',
        'sea',
        'sea',
        'sea',
        'sea',
        'sea',
        'sea',
        'sea',
        'sea',
        'sea',
        'sea',
      ],
    ];
    final nwNodes = <TopologyNode>[
      const TopologyNode(
        id: 'sea',
        regionId: 'newWorld',
        type: TopologyNodeType.seaZone,
      ),
      for (var i = 1; i <= 11; i++)
        TopologyNode(
          id: 'n$i',
          regionId: 'newWorld',
          type: TopologyNodeType.province,
        ),
    ];
    final nwEdges = <TopologyEdge>[
      for (var i = 1; i <= 11; i++) TopologyEdge(id1: 'n$i', id2: 'sea'),
      for (var i = 1; i < 11; i++) TopologyEdge(id1: 'n$i', id2: 'n${i + 1}'),
    ];
    final nwTopology = MapTopology(nodes: nwNodes, edges: nwEdges);
    final nwTileMap = TileMapResult(width: 11, height: 2, grid: nwGrid);

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
      tribeCount: 11,
      numProvincesOldWorld: 1,
      numProvincesNewWorld: 11,
      minProvincesPerMinor: 0,
    );

    final result = createGameFromGeneratedMaps(
      config: config,
      tileMapOldWorld: owTileMap,
      topologyOldWorld: owTopology,
      tileMapNewWorld: nwTileMap,
      topologyNewWorld: nwTopology,
      gameId: 'fallback-test',
    );

    for (final p in allProvinces(result.game.worldState)) {
      expect(p.displayName, isNotNull, reason: p.id);
      expect(p.displayName!.isNotEmpty, isTrue, reason: p.id);
    }
    final nwProvinces = result.game.worldState.newWorld.provinces;
    expect(result.game.tribes.length, 11);
    final tribe11 = result.game.tribes.firstWhere((t) => t.id == 'tribe11');
    final tribe11Provinces = nwProvinces
        .where((p) => p.ownerId == tribe11.id)
        .toList();
    expect(tribe11Provinces, isNotEmpty);
    for (final p in tribe11Provinces) {
      expect(p.displayName, isNotNull);
      expect(
        p.displayName!.isNotEmpty,
        isTrue,
        reason: 'tribe11 fallback must produce non-empty name',
      );
    }
  }),
];
