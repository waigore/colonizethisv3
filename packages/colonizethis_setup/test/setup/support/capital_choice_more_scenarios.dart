// Scenario table densify (Refs #4349 Slice C).

import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_setup/colonizethis_setup.dart';
import 'scenario_runner.dart';

List<RunnableScenario> capitalChoiceScenariosMore() => [
  rs(
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
  ),
  rs(
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
  ),
  rs(
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
  ),
  rs('pickCapitalForFaction for GP throws when no coastal tile exists', () {
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
      () =>
          pickCapitalForFaction(['oldWorld|p1'], 'oldWorld', topology, tileMap),
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
  }),
];
