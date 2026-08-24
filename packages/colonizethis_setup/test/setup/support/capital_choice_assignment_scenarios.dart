// Scenario table densify (Refs #4349 Slice C).

import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'scenario_runner.dart';

import 'capital_choice_assignment_more_scenarios.dart';

List<RunnableScenario> capitalChoiceAssignmentScenarios() => [
  rs('setCapitalForMinorNation updates minor and WorldState port/road', () {
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
      players: const [],
      minorNations: [MinorNation(id: 'min1', displayName: 'Portugal')],
      turnNumber: 0,
      oldWorld: RegionData(
        provinces: [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'min1'),
        ],
      ),
      newWorld: const RegionData(),
    );
    final next = setCapitalForMinorNation(
      game: game,
      minorId: 'min1',
      provinceId: 'oldWorld|p1',
      tile: const CapitalTile(
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
    expect(next.minorNations.single.capitalProvinceId, 'oldWorld|p1');
    expect(next.minorNations.single.capitalTile?.x, 0);
    expect(
      next.worldState.portsByProvinceSeaboard['oldWorld|p1|sea1'],
      'oldWorld|p1|0|0',
    );
    expect(next.worldState.tileState.roadLevel('oldWorld|p1|0|0'), 4);
  }),
  rs('setCapitalForTribe updates tribe and WorldState port/road', () {
    final grid = [
      ['nw1', 'sea1'],
      ['nw1', 'nw1'],
    ];
    final topology = MapTopology(
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
    final game = TestFixtures.minimalGame(
      id: 'g1',
      players: const [],
      tribes: [Tribe(id: 'tribe1', displayName: 'Aztec')],
      turnNumber: 0,
      oldWorld: const RegionData(),
      newWorld: RegionData(
        provinces: [
          Province(id: 'newWorld|nw1', regionId: 'newWorld', ownerId: 'tribe1'),
        ],
      ),
    );
    final next = setCapitalForTribe(
      game: game,
      tribeId: 'tribe1',
      provinceId: 'newWorld|nw1',
      tile: const CapitalTile(
        regionId: 'newWorld',
        provinceId: 'newWorld|nw1',
        x: 0,
        y: 0,
      ),
      topology: topology,
      tileMapByRegion: {
        'newWorld': TileMapResult(width: 2, height: 2, grid: grid),
      },
    );
    expect(next.tribes.single.capitalProvinceId, 'newWorld|nw1');
    expect(next.tribes.single.capitalTile?.regionId, 'newWorld');
    expect(
      next.worldState.portsByProvinceSeaboard['newWorld|nw1|sea1'],
      'newWorld|nw1|0|0',
    );
  }),
  ...capitalChoiceAssignmentScenariosMore(),
];
