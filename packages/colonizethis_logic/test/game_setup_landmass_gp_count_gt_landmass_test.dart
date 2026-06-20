import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('GameSetup', () {
    test(
      'each Great Power stays on one P–P landmass when gpCount > landmassCount',
      () {
        // Three disconnected land components (e.g. three continents). Four GPs
        // must share landmasses; each GP must still own provinces on only one
        // component (regression: one-GP-per-landmass left some GPs unconstrained).
        // Continent A needs nine land provinces so fair GP targets (3+3+3+3) can
        // pack: three GPs on A plus one on B; with only eight on A the greedy
        // packer drops the GP budget to 11 and repair often exhausts.
        TopologyNode p(String id) => TopologyNode(
          id: id,
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        );
        const seaA = TopologyNode(
          id: 'sea_a',
          regionId: 'oldWorld',
          type: TopologyNodeType.seaZone,
        );
        const seaB = TopologyNode(
          id: 'sea_b',
          regionId: 'oldWorld',
          type: TopologyNodeType.seaZone,
        );
        const seaC = TopologyNode(
          id: 'sea_c',
          regionId: 'oldWorld',
          type: TopologyNodeType.seaZone,
        );

        final owNodes = <TopologyNode>[
          p('pa1'),
          p('pa2'),
          p('pa3'),
          p('pa4'),
          p('pa5'),
          p('pa6'),
          p('pa7'),
          p('pa8'),
          p('pa9'),
          p('pb1'),
          p('pb2'),
          p('pb3'),
          p('pb4'),
          p('pc1'),
          p('pc2'),
          p('pc3'),
          p('pc4'),
          seaA,
          seaB,
          seaC,
        ];

        final owEdges = <TopologyEdge>[
          const TopologyEdge(id1: 'pa1', id2: 'sea_a'),
          const TopologyEdge(id1: 'pa2', id2: 'sea_a'),
          const TopologyEdge(id1: 'pa3', id2: 'sea_a'),
          const TopologyEdge(id1: 'pa9', id2: 'sea_a'),
          for (var i = 1; i < 9; i++)
            TopologyEdge(id1: 'pa$i', id2: 'pa${i + 1}'),
          const TopologyEdge(id1: 'pb1', id2: 'sea_b'),
          for (var i = 1; i < 4; i++)
            TopologyEdge(id1: 'pb$i', id2: 'pb${i + 1}'),
          const TopologyEdge(id1: 'pc1', id2: 'sea_c'),
          for (var i = 1; i < 4; i++)
            TopologyEdge(id1: 'pc$i', id2: 'pc${i + 1}'),
        ];

        final owTopology = MapTopology(nodes: owNodes, edges: owEdges);
        // Each province column has sea immediately to its right so every
        // sea-bound province has a coastal tile (capital port placement).
        final owGrid = <List<String>>[
          for (var i = 0; i < 9; i++)
            [
              'pa${i + 1}',
              'sea_a',
              if (i < 4) 'pb${i + 1}' else 'pb4',
              'sea_b',
              if (i < 4) 'pc${i + 1}' else 'pc4',
              'sea_c',
            ],
        ];
        final owTileMap = TileMapResult(width: 6, height: 9, grid: owGrid);

        final nwGrid = [
          ['nw1', 'sea1'],
        ];
        final nwTopology = MapTopology(
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
        final nwTileMap = TileMapResult(width: 2, height: 1, grid: nwGrid);

        final config = GameSetupConfig(
          selectedGreatPowerIds: ['england', 'france', 'spain', 'portugal'],
          continentCount: 3,
          minorNationCount: 2,
          tribeCount: 1,
          numProvincesOldWorld: 17,
          numProvincesNewWorld: 1,
          minProvincesPerMinor: 2,
          seed: 42,
        );

        final result = createGameFromGeneratedMaps(
          config: config,
          tileMapOldWorld: owTileMap,
          topologyOldWorld: owTopology,
          tileMapNewWorld: nwTileMap,
          topologyNewWorld: nwTopology,
          gameId: 'multi-landmass-gp',
        );

        String landGroup(String prefixedProvinceId) {
          final local = prefixedProvinceId.split('|').last;
          if (local.startsWith('pa')) return 'A';
          if (local.startsWith('pb')) return 'B';
          if (local.startsWith('pc')) return 'C';
          return '?';
        }

        for (final player in result.game.players) {
          final owned = result.game.worldState.oldWorld.provinces
              .where((p) => p.ownerId == player.id)
              .toList();
          expect(owned, isNotEmpty, reason: '${player.id} owns no provinces');
          final g0 = landGroup(owned.first.id);
          for (final prov in owned.skip(1)) {
            expect(
              landGroup(prov.id),
              g0,
              reason:
                  '${player.id} must not span landmasses (province ${prov.id})',
            );
          }
        }
      },
    );
  });
}
