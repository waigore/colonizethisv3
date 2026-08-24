// Scenario table densify (Refs #4349 Slice C).

import 'package:colonizethis_test/game_test_fixtures.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'scenario_runner.dart';

List<RunnableScenario> capitalChoiceAssignmentScenariosMore() => [
  rs(
    'setCapitalForMinorNation succeeds with inland province, no port/road applied',
    () {
      final grid = [
        ['p1', 'p2'],
        ['p2', 'p2'],
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
        ],
        edges: [TopologyEdge(id1: 'p1', id2: 'p2')],
      );
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: const [],
        minorNations: [MinorNation(id: 'min1', displayName: 'Inland Minor')],
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
      expect(next.worldState.portsByProvinceSeaboard.isEmpty, true);
    },
  ),
  rs(
    'setCapitalForTribe succeeds with inland province, no port/road applied',
    () {
      final grid = [
        ['nw1', 'nw2'],
        ['nw2', 'nw2'],
      ];
      final topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'nw1',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'nw2',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [TopologyEdge(id1: 'nw1', id2: 'nw2')],
      );
      final game = TestFixtures.minimalGame(
        id: 'g1',
        players: const [],
        tribes: [Tribe(id: 'tribe1', displayName: 'Inland Tribe')],
        turnNumber: 0,
        oldWorld: const RegionData(),
        newWorld: RegionData(
          provinces: [
            Province(
              id: 'newWorld|nw1',
              regionId: 'newWorld',
              ownerId: 'tribe1',
            ),
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
      expect(next.worldState.portsByProvinceSeaboard.isEmpty, true);
    },
  ),
  rs(
    'init road path: inland capital + port 2+ steps away -> every tile on shortest path has road',
    () {
      final grid = [
        ['p1', 'p1', 'sea1'],
        ['p1', 'p1', 'p1'],
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
        players: [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
        turnNumber: 0,
        oldWorld: RegionData(
          provinces: [
            Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'pl1'),
          ],
        ),
        newWorld: const RegionData(),
      );
      final tileMapByRegion = {
        'oldWorld': TileMapResult(width: 3, height: 2, grid: grid),
      };
      final next = setCapital(
        game: game,
        playerId: 'pl1',
        provinceId: 'oldWorld|p1',
        tile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 1,
          y: 1,
        ),
        topology: topology,
        tileMapByRegion: tileMapByRegion,
      );
      expect(next.players.single.capitalProvinceId, 'oldWorld|p1');
      final ts = next.worldState.tileState;
      expect(ts.roadLevel('oldWorld|p1|1|1'), 1);
      expect(ts.roadLevel('oldWorld|p1|1|0'), 4);
      expect(ts.roadLevel('oldWorld|p1|1|1'), 1);
    },
  ),
];
