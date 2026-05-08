import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('CapitalChoice classification', () {
    test('setCapital creates one port entry per adjacent sea zone', () {
      final grid = [
        ['sea1', 'p1', 'sea2'],
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
          TopologyNode(
            id: 'sea2',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [
          TopologyEdge(id1: 'p1', id2: 'sea1'),
          TopologyEdge(id1: 'p1', id2: 'sea2'),
        ],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'pl1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
      );
      final next = setCapital(
        game: game,
        playerId: 'pl1',
        provinceId: 'oldWorld|p1',
        tile: const CapitalTile(
          regionId: 'oldWorld',
          provinceId: 'oldWorld|p1',
          x: 1,
          y: 0,
        ),
        topology: topology,
        tileMapByRegion: {
          'oldWorld': TileMapResult(width: 3, height: 2, grid: grid),
        },
      );
      final ports = next.worldState.portsByProvinceSeaboard;
      expect(ports['oldWorld|p1|sea1'], 'oldWorld|p1|1|0');
      expect(ports['oldWorld|p1|sea2'], 'oldWorld|p1|1|0');
      expect(ports.keys.where((k) => k.startsWith('oldWorld|p1|')).length, 2);
    });

    test('setCapital builds seaboard-specific inland ports and road paths', () {
      final grid = [
        ['sea1', 'p1', 'p1', 'sea2'],
        ['p1', 'p1', 'p1', 'p1'],
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
          TopologyNode(
            id: 'sea2',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [
          TopologyEdge(id1: 'p1', id2: 'sea1'),
          TopologyEdge(id1: 'p1', id2: 'sea2'),
        ],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'pl1'),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: [Player(id: 'pl1', displayName: 'Spain', isHuman: true)],
      );
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
        tileMapByRegion: {
          'oldWorld': TileMapResult(width: 4, height: 2, grid: grid),
        },
      );
      final ports = next.worldState.portsByProvinceSeaboard;
      expect(ports['oldWorld|p1|sea1'], 'oldWorld|p1|1|0');
      expect(ports['oldWorld|p1|sea2'], 'oldWorld|p1|2|0');
      final tileState = next.worldState.tileState;
      expect(tileState.roadLevel('oldWorld|p1|1|0'), 4);
      expect(tileState.roadLevel('oldWorld|p1|2|0'), 4);
      expect(tileState.roadLevel('oldWorld|p1|1|1'), 1);
      expect(tileState.roadLevel('oldWorld|p1|2|1'), 1);
    });

    test('classifyCapitalTile returns class A for coastal non-border tile', () {
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
      final tileMap = TileMapResult(width: 2, height: 2, grid: grid);
      final tileClass = classifyCapitalTile(
        x: 0,
        y: 0,
        tileMap: tileMap,
        topology: topology,
        localProvinceId: 'p1',
      );
      expect(tileClass, CapitalTileClass.a);
    });

    test(
      'classifyCapitalTile returns class B for interior non-border tile',
      () {
        final grid = [
          ['sea1', 'sea1', 'sea1', 'sea1', 'sea1'],
          ['sea1', 'p1', 'p1', 'p1', 'sea1'],
          ['sea1', 'p1', 'p1', 'p1', 'sea1'],
          ['sea1', 'p1', 'p1', 'p1', 'sea1'],
          ['sea1', 'sea1', 'sea1', 'sea1', 'sea1'],
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
        final tileMap = TileMapResult(width: 5, height: 5, grid: grid);
        final tileClass = classifyCapitalTile(
          x: 2,
          y: 2,
          tileMap: tileMap,
          topology: topology,
          localProvinceId: 'p1',
        );
        expect(tileClass, CapitalTileClass.b);
      },
    );

    test(
      'classifyCapitalTile returns class C for tile bordering another province',
      () {
        final grid = [
          ['p1', 'p2'],
          ['sea1', 'sea1'],
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
            TopologyEdge(id1: 'p1', id2: 'p2'),
            TopologyEdge(id1: 'p1', id2: 'sea1'),
          ],
        );
        final tileMap = TileMapResult(width: 2, height: 2, grid: grid);
        final tileClass = classifyCapitalTile(
          x: 0,
          y: 0,
          tileMap: tileMap,
          topology: topology,
          localProvinceId: 'p1',
        );
        expect(tileClass, CapitalTileClass.c);
      },
    );
  });
}
