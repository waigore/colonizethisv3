import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:test/test.dart';

void main() {
  group('GameSetup', () {
    test('createGameFromGeneratedMaps produces Game with GPs, minors, tribes and capitals', () {
      // OW: 2 provinces (p1 sea-bound, p2 inland)
      final owGrid = [
        ['p1', 'sea1'],
        ['p2', 'p1'],
      ];
      final owTopology = MapTopology(
        nodes: [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [
          TopologyEdge(id1: 'p1', id2: 'sea1'),
          TopologyEdge(id1: 'p2', id2: 'p1'),
        ],
      );
      final owTileMap = TileMapResult(width: 2, height: 2, grid: owGrid);

      // NW: 1 province (nw1 sea-bound)
      final nwGrid = [
        ['nw1', 'sea1'],
        ['nw1', 'nw1'],
      ];
      final nwTopology = MapTopology(
        nodes: [
          TopologyNode(id: 'nw1', regionId: 'newWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'newWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [TopologyEdge(id1: 'nw1', id2: 'sea1')],
      );
      final nwTileMap = TileMapResult(width: 2, height: 2, grid: nwGrid);

      const config = GameSetupConfig(
        greatPowerCount: 1,
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 2,
        numProvincesNewWorld: 1,
      );

      final result = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: owTileMap,
        topologyOldWorld: owTopology,
        tileMapNewWorld: nwTileMap,
        topologyNewWorld: nwTopology,
        gameId: 'test-game',
      );

      expect(result.game.id, 'test-game');
      expect(result.game.players.length, 1);
      expect(result.game.players.first.id, 'gp1');
      expect(result.game.players.first.capitalProvinceId, 'p1');
      expect(result.game.players.first.capitalTile?.provinceId, 'p1');

      expect(result.game.minorNations, isEmpty);
      expect(result.game.tribes.length, 1);
      expect(result.game.tribes.first.id, 'tribe1');
      expect(result.game.tribes.first.capitalProvinceId, 'nw1');
      expect(result.game.tribes.first.capitalTile?.regionId, 'newWorld');

      expect(result.game.worldState.oldWorld.provinces.length, 2);
      expect(result.game.worldState.newWorld.provinces.length, 1);
      expect(result.game.worldState.portsByProvinceSeaboard.containsKey('p1|sea1'), true);
      expect(result.game.worldState.portsByProvinceSeaboard.containsKey('nw1|sea1'), true);

      expect(result.tileMapByRegion['oldWorld'], owTileMap);
      expect(result.topologyByRegion['oldWorld'], owTopology);
    });
  });
}
