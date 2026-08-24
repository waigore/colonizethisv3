// Scenario table densify (Refs #4349 Slice C).

import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'scenario_runner.dart';

import 'capital_choice_more_scenarios.dart';

List<RunnableScenario> capitalChoiceScenarios() => [
  rs('isProvinceSeaBound true when P-S edge exists', () {
    final topology = MapTopology(
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
    expect(isProvinceSeaBound(topology, 'p1'), true);
    expect(isProvinceSeaBound(topology, 'sea1'), false);
  }),
  rs('setCapital updates player and auto-builds port on coastal capital', () {
    final grid = [
      ['p1', 'sea1'],
      ['p1', 'p1'],
    ];
    final topology = MapTopology(
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
    final game = TestFixtures.minimalGame(
      id: 'g1',
      turnNumber: 1,
      oldWorld: RegionData(
        provinces: [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'pl1'),
        ],
      ),
      players: [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
    );
    final next = setCapital(
      game: game,
      playerId: 'pl1',
      provinceId: 'oldWorld|p1',
      tile: CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      ),
      topology: topology,
      tileMapByRegion: {
        'oldWorld': TileMapResult(width: 2, height: 2, grid: grid),
      },
    );
    expect(next.players.single.capitalProvinceId, 'oldWorld|p1');
    expect(next.players.single.capitalTile?.x, 0);
    expect(next.players.single.capitalTile?.y, 0);
    expect(
      next.worldState.portsByProvinceSeaboard['oldWorld|p1|sea1'],
      'oldWorld|p1|0|0',
    );
    expect(next.worldState.tileState.roadLevel('oldWorld|p1|0|0'), 4);
  }),
  rs('pickCapitalForFaction returns sea-bound province and valid tile', () {
    final grid = [
      ['p1', 'sea1'],
      ['p2', 'p1'],
    ];
    final topology = MapTopology(
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
    final tileMap = TileMapResult(width: 2, height: 2, grid: grid);
    // p1 is sea-bound, p2 is not. Owned = [p2, p1]; after sort sea-bound = [p1].
    final (provinceId, tile) = pickCapitalForFaction(
      ['oldWorld|p2', 'oldWorld|p1'],
      'oldWorld',
      topology,
      tileMap,
    );
    expect(provinceId, 'oldWorld|p1');
    expect(tile.regionId, 'oldWorld');
    expect(tile.provinceId, 'oldWorld|p1');
    expect(tile.x, 0);
    expect(tile.y, 0);
  }),
  ...capitalChoiceScenariosMore(),
];
