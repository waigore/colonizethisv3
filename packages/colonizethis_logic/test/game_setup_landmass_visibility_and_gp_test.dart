import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('GameSetup', () {
    test('each GP stays on a single landmass (no cross-continent assignment)', () {
      // Create a map with 2 disconnected landmasses:
      // Landmass A: p1 (sea-bound), p2, p3
      // Landmass B: p4 (sea-bound), p5, p6
      // With 2 GPs, each should get one landmass
      // Each province needs coastal access via sea zones.
      // Grid: p1 adjacent to sea1, p4 adjacent to sea2 (p1 and sea1 must be adjacent in grid).
      final owGrid = [
        ['p1', 'sea1', 'p2'],
        ['p3', 'p4', 'sea2'],
        ['p5', 'p6', 'sea3'],
      ];
      final owTopology = MapTopology(
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
            id: 'p3',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p4',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p5',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p6',
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
          TopologyNode(
            id: 'sea3',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [
          // Landmass A: p1 is coastal (sea1), p1-p2, p2-p3
          TopologyEdge(id1: 'p1', id2: 'sea1'),
          TopologyEdge(id1: 'p1', id2: 'p2'),
          TopologyEdge(id1: 'p2', id2: 'p3'),
          // Landmass B: p4 is coastal (sea2), p4-p5, p5-p6
          TopologyEdge(id1: 'p4', id2: 'sea2'),
          TopologyEdge(id1: 'p4', id2: 'p5'),
          TopologyEdge(id1: 'p5', id2: 'p6'),
          // p3 and p6 connect to sea3 for coastal access
          TopologyEdge(id1: 'p3', id2: 'sea3'),
          TopologyEdge(id1: 'p6', id2: 'sea3'),
        ],
      );
      final owTileMap = TileMapResult(width: 3, height: 3, grid: owGrid);

      // NW: 1 province
      final nwGrid = [
        ['nw1', 'sea1'],
        ['nw1', 'nw1'],
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
      final nwTileMap = TileMapResult(width: 2, height: 2, grid: nwGrid);

      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england', 'france'],
        continentCount: 2,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 6,
        numProvincesNewWorld: 1,
        minProvincesPerMinor: 0,
      );

      final result = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: owTileMap,
        topologyOldWorld: owTopology,
        tileMapNewWorld: nwTileMap,
        topologyNewWorld: nwTopology,
        gameId: 'single-landmass-test',
      );

      // Get GP province IDs (extract just the province part from "oldWorld|p1" format)
      final gp1Provinces = result.game.worldState.oldWorld.provinces
          .where((p) => p.ownerId == 'gp1')
          .map((p) => p.id.split('|').last)
          .toList();
      final gp2Provinces = result.game.worldState.oldWorld.provinces
          .where((p) => p.ownerId == 'gp2')
          .map((p) => p.id.split('|').last)
          .toList();

      // Each GP should have provinces
      expect(
        gp1Provinces.isNotEmpty,
        true,
        reason: 'GP1 should have provinces',
      );
      expect(
        gp2Provinces.isNotEmpty,
        true,
        reason: 'GP2 should have provinces',
      );

      // Compute landmass IDs for each province
      // Landmass A: p1, p2, p3 (connected via p1-p2-p3)
      // Landmass B: p4, p5, p6 (connected via p4-p5-p6)
      final landmassAPart1 = {'p1', 'p2', 'p3'};
      final landmassBPart1 = {'p4', 'p5', 'p6'};

      // Check that each GP's provinces are all on the same landmass
      final gp1OnLandmassA = gp1Provinces.any(
        (p) => landmassAPart1.contains(p),
      );
      final gp1OnLandmassB = gp1Provinces.any(
        (p) => landmassBPart1.contains(p),
      );
      final gp2OnLandmassA = gp2Provinces.any(
        (p) => landmassAPart1.contains(p),
      );
      final gp2OnLandmassB = gp2Provinces.any(
        (p) => landmassBPart1.contains(p),
      );

      // Each GP should be on exactly one landmass
      expect(
        gp1OnLandmassA && !gp1OnLandmassB || !gp1OnLandmassA && gp1OnLandmassB,
        true,
        reason: 'GP1 should be on exactly one landmass, got: $gp1Provinces',
      );
      expect(
        gp2OnLandmassA && !gp2OnLandmassB || !gp2OnLandmassA && gp2OnLandmassB,
        true,
        reason: 'GP2 should be on exactly one landmass, got: $gp2Provinces',
      );

      // GPs should be on different landmasses
      expect(
        gp1OnLandmassA != gp2OnLandmassA || gp1OnLandmassB != gp2OnLandmassB,
        true,
        reason: 'GPs should be on different landmasses',
      );
    });

    test('sea tiles have visibility set (OW fogged, NW unknown)', () {
      // OW: 1 province (p1) + 1 sea zone (sea1)
      // NW:1 province (nw1) + 1 sea zone (sea1)
      final owGrid = [
        ['p1', 'sea1'],
      ];
      final owTopology = MapTopology(
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
      final owTileMap = TileMapResult(width: 2, height: 1, grid: owGrid);

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
        selectedGreatPowerIds: ['england'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 1,
        numProvincesNewWorld: 1,
        minProvincesPerMinor: 0,
      );

      final result = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: owTileMap,
        topologyOldWorld: owTopology,
        tileMapNewWorld: nwTileMap,
        topologyNewWorld: nwTopology,
        gameId: 'sea-visibility-test',
      );

      final vis = result.game.worldState.playerVisibilityByTile;
      final gpId = result.game.players.first.id;

      // Old World sea tile (sea1) should be fullyVisible because it's adjacent
      // to the GP's province (p1). Coastal sea zone visibility is applied at
      // game setup per SPEC/program/fog-and-exploration-resolution.md.
      final owSeaTileKey = 'oldWorld|sea1|1|0';
      expect(
        vis[gpId],
        contains(owSeaTileKey),
        reason: 'OW sea tile must be in visibility map',
      );
      expect(
        vis[gpId]![owSeaTileKey],
        'fullyVisible',
        reason:
            'OW sea tile adjacent to owned province should be fullyVisible'
            ' at game setup (coastal sea zone visibility)',
      );

      // New World sea tile (sea1) should be unknown (no GP owns adjacent province)
      final nwSeaTileKey = 'newWorld|sea1|1|0';
      expect(
        vis[gpId],
        contains(nwSeaTileKey),
        reason: 'NW sea tile must be in visibility map',
      );
      expect(
        vis[gpId]![nwSeaTileKey],
        'unknown',
        reason: 'NW sea tile should be unknown (no GP owns adjacent province)',
      );

      // Verify land tiles also have visibility
      final owLandTileKey = 'oldWorld|p1|0|0';
      expect(
        vis[gpId],
        contains(owLandTileKey),
        reason: 'OW land tile must be in visibility map',
      );
      // Own province should be fullyVisible
      expect(
        vis[gpId]![owLandTileKey],
        'fullyVisible',
        reason: 'OW own province should be fully visible',
      );

      final nwLandTileKey = 'newWorld|nw1|0|0';
      expect(
        vis[gpId],
        contains(nwLandTileKey),
        reason: 'NW land tile must be in visibility map',
      );
      // New World should be unknown
      expect(
        vis[gpId]![nwLandTileKey],
        'unknown',
        reason: 'NW land tile should be unknown',
      );
    });

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

/// P–P adjacency only (mirrors game_setup private helper) for setup tests.
Map<String, Set<String>> _provincePpNeighboursForTest(MapTopology topology) {
  final provinces = {
    for (final n in topology.nodes)
      if (n.type == TopologyNodeType.province) n.id,
  };
  final neighbours = <String, Set<String>>{
    for (final id in provinces) id: <String>{},
  };
  for (final edge in topology.edges) {
    final a = edge.id1;
    final b = edge.id2;
    if (!provinces.contains(a) || !provinces.contains(b)) continue;
    neighbours[a]!.add(b);
    neighbours[b]!.add(a);
  }
  return neighbours;
}
