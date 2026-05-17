import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('ConnectivityResolver town-rule worklist', () {
    test(
      'multi-province owner with several towns completes (no redundant town enqueue)',
      () {
        const ow = 'oldWorld';
        final grid = [
          ['p1', 'p2', 'p3'],
          ['p1', 'p2', 'p3'],
        ];
        final tileMap = TileMapResult(width: 3, height: 2, grid: grid);
        final topology = MapTopology(
          nodes: [
            TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: 'p2', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: 'p3', regionId: ow, type: TopologyNodeType.province),
          ],
          edges: [],
        );
        final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
        final tileState = TileMapState()
            .setRoadLevel('oldWorld|p1|0|0', 1)
            .setRoadLevel('oldWorld|p1|1|0', 1)
            .setRoadLevel('oldWorld|p1|2|0', 1)
            .setRoadLevel('oldWorld|p2|1|0', 1)
            .setRoadLevel('oldWorld|p2|2|0', 1)
            .setRoadLevel('oldWorld|p3|2|0', 1);
        final player = Player(
          id: 'pl1',
          displayName: 'Spain',
          isHuman: true,
          capitalProvinceId: '$ow|p1',
          capitalTile: cap,
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(provinces: [
              Province(
                id: '$ow|p1',
                regionId: ow,
                ownerId: 'pl1',
                townTileKey: 'oldWorld|p1|0|0',
              ),
              Province(
                id: '$ow|p2',
                regionId: ow,
                ownerId: 'pl1',
                townTileKey: 'oldWorld|p2|1|0',
              ),
              Province(
                id: '$ow|p3',
                regionId: ow,
                ownerId: 'pl1',
                townTileKey: 'oldWorld|p3|2|0',
              ),
            ]),
            newWorld: const RegionData(),
            tileState: tileState,
          ),
          players: [player],
        );
        final result = resolveConnectivity(
          game: game,
          tileMapByRegion: {ow: tileMap},
          topology: topology,
        );
        final connected = result['pl1']!.connected;
        expect(connected.contains('oldWorld|p1|0|0'), isTrue);
        expect(connected.contains('oldWorld|p3|2|0'), isTrue);
        expect(connected.length, greaterThanOrEqualTo(6));
      },
    );

    test('many port registry entries reuse single port map per player resolve', () {
      const ow = 'oldWorld';
      final grid = [
        ['p1', 'p1'],
        ['p1', 'p1'],
      ];
      final tileMap = TileMapResult(width: 2, height: 2, grid: grid);
      final topology = MapTopology(
        nodes: [TopologyNode(id: 'p1', regionId: ow, type: TopologyNodeType.province)],
        edges: [],
      );
      final cap = CapitalTile(regionId: ow, provinceId: '$ow|p1', x: 0, y: 0);
      final ports = <String, String>{
        for (var i = 0; i < 40; i++) '$ow|p1|sea$i': 'oldWorld|p1|1|0',
      };
      final tileState = TileMapState()
          .setRoadLevel('oldWorld|p1|0|0', 1)
          .setRoadLevel('oldWorld|p1|1|0', 1);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: '$ow|p1',
        capitalTile: cap,
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(provinces: [
            Province(id: '$ow|p1', regionId: ow, ownerId: 'pl1'),
          ]),
          newWorld: const RegionData(),
          tileState: tileState,
          portsByProvinceSeaboard: ports,
        ),
        players: [player],
      );
      final result = resolveConnectivity(
        game: game,
        tileMapByRegion: {ow: tileMap},
        topology: topology,
      );
      expect(result['pl1']!.connected.contains('oldWorld|p1|1|0'), isTrue);
    });
  });
}
