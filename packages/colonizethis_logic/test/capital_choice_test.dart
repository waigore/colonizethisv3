import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('CapitalChoice', () {
    test('isProvinceSeaBound true when P-S edge exists', () {
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
    });

    test(
      'setCapital updates player and auto-builds port on coastal capital',
      () {
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
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: TurnState(turnNumber: 1, phase: TurnPhase.orders),
            oldWorld: RegionData(
              provinces: [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  ownerId: 'pl1',
                ),
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
      },
    );

    test('pickCapitalForFaction returns sea-bound province and valid tile', () {
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
    });

    test(
      'pickCapitalForFaction throws when no sea-bound province (requireSeaBound: true)',
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
        final tileMap = TileMapResult(width: 2, height: 2, grid: grid);
        expect(
          () => pickCapitalForFaction(
            ['oldWorld|p1', 'oldWorld|p2'],
            'oldWorld',
            topology,
            tileMap,
          ),
          throwsA(
            isA<NoSeaBoundCapitalProvinceException>().having(
              (e) => e.code,
              'code',
              'no_sea_bound_capital_province',
            ),
          ),
        );
      },
    );

    test(
      'pickCapitalForFaction with requireSeaBound: false returns first province when none sea-bound',
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
        final tileMap = TileMapResult(width: 2, height: 2, grid: grid);
        final (provinceId, tile) = pickCapitalForFaction(
          ['oldWorld|p2', 'oldWorld|p1'],
          'oldWorld',
          topology,
          tileMap,
          requireSeaBound: false,
        );
        expect(provinceId, 'oldWorld|p1');
        expect(tile.regionId, 'oldWorld');
        expect(tile.provinceId, 'oldWorld|p1');
      },
    );

    test(
      'pickCapitalForFaction for GP uses coastal Class C when Class A is empty',
      () {
        // p1 is sea-bound. (0,1) is Class B. (1,1) is Class C coastal (adjacent to sea and p2).
        final grid = [
          ['p1', 'p2', 'sea1'],
          ['p1', 'p1', 'sea1'],
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
            TopologyEdge(id1: 'p1', id2: 'p2'),
          ],
        );
        final tileMap = TileMapResult(width: 3, height: 2, grid: grid);
        final (provinceId, tile) = pickCapitalForFaction(
          ['oldWorld|p1'],
          'oldWorld',
          topology,
          tileMap,
        );
        expect(provinceId, 'oldWorld|p1');
        expect(tile.provinceId, 'oldWorld|p1');
        expect(tile.x, 1);
        expect(tile.y, 1);
      },
    );

    test('pickCapitalForFaction for GP throws when no coastal tile exists', () {
      // Contrived invalid map: province is marked sea-bound in topology but tile map has no coastal p1 tile.
      final grid = [
        ['p1', 'p1', 'p2'],
        ['p1', 'p1', 'p2'],
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
          TopologyEdge(id1: 'p1', id2: 'p2'),
        ],
      );
      final tileMap = TileMapResult(width: 3, height: 2, grid: grid);
      expect(
        () => pickCapitalForFaction(
          ['oldWorld|p1'],
          'oldWorld',
          topology,
          tileMap,
        ),
        throwsA(
          isA<NoCoastalCapitalTileForGpException>()
              .having((e) => e.code, 'code', 'no_coastal_capital_tile_for_gp')
              .having(
                (e) => e.message,
                'message',
                contains('No coastal tile found'),
              ),
        ),
      );
    });
  });
}
