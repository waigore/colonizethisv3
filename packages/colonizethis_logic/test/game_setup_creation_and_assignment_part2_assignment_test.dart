import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('GameSetup', () {
    test(
      'Old World assignment reserves provinces for minors based on config',
      () {
        // Simple OW topology with 12 provinces in a line, p1 and p2 sea-bound.
        final owNodes = <TopologyNode>[
          const TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          for (var i = 1; i <= 12; i++)
            TopologyNode(
              id: 'p$i',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
        ];
        final owEdges = <TopologyEdge>[
          const TopologyEdge(id1: 'p1', id2: 'sea1'),
          const TopologyEdge(id1: 'p2', id2: 'sea1'),
          const TopologyEdge(id1: 'p12', id2: 'sea1'),
          for (var i = 1; i < 12; i++)
            TopologyEdge(id1: 'p$i', id2: 'p${i + 1}'),
        ];
        final owTopology = MapTopology(nodes: owNodes, edges: owEdges);
        final owTileMap = TileMapResult(
          width: 12,
          height: 2,
          grid: [
            [for (var i = 1; i <= 12; i++) 'p$i'],
            [for (var i = 1; i <= 12; i++) 'sea1'],
          ],
        );

        // NW not relevant for this assertion; keep minimal valid data.
        final nwTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'nw1',
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'nwSea',
              regionId: 'newWorld',
              type: TopologyNodeType.seaZone,
            ),
          ],
          edges: const [TopologyEdge(id1: 'nw1', id2: 'nwSea')],
        );
        final nwTileMap = TileMapResult(
          width: 1,
          height: 2,
          grid: const [
            ['nw1'],
            ['nwSea'],
          ],
        );

        const minorCount = 2;
        const minPerMinor = 3;
        const totalOw = 12;
        const availableForGps = totalOw - (minorCount * minPerMinor);

        final config = GameSetupConfig(
          selectedGreatPowerIds: ['england', 'france'],
          continentCount: 1,
          minorNationCount: minorCount,
          tribeCount: 1,
          numProvincesOldWorld: totalOw,
          numProvincesNewWorld: 1,
          minProvincesPerMinor: minPerMinor,
        );

        final result = createGameFromGeneratedMaps(
          config: config,
          tileMapOldWorld: owTileMap,
          topologyOldWorld: owTopology,
          tileMapNewWorld: nwTileMap,
          topologyNewWorld: nwTopology,
          gameId: 'ow-reservation',
        );

        final ow = result.game.worldState.oldWorld.provinces;
        final gpOwned = ow
            .where((p) => p.ownerId == 'gp1' || p.ownerId == 'gp2')
            .length;
        final minorOwned = ow
            .where((p) => p.ownerId == 'minor1' || p.ownerId == 'minor2')
            .length;

        expect(gpOwned, availableForGps);
        expect(minorOwned, totalOw - availableForGps);
        for (final minor in result.game.minorNations) {
          final minorCapitalTile = minor.capitalTile;
          expect(minorCapitalTile, isNotNull);
          final minorUnits = result.game.worldState.oldWorld.units
              .where((u) => u.ownerId == minor.id && u.tileKey != null)
              .toList();
          expect(minorUnits, isNotEmpty);
          for (final unit in minorUnits) {
            expect(unit.tileKey, minorCapitalTile!.toTileKey());
          }
        }
      },
    );

    test('New World assignment balances tribes by province count', () {
      // NW: 9 provinces in a 3x3 grid; simple adjacency.
      final nwGrid = [
        ['n1', 'n2', 'n3'],
        ['n4', 'n5', 'n6'],
        ['n7', 'n8', 'n9'],
      ];
      final nwNodes = <TopologyNode>[
        for (final id in ['n1', 'n2', 'n3', 'n4', 'n5', 'n6', 'n7', 'n8', 'n9'])
          TopologyNode(
            id: id,
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
      ];
      final nwEdges = <TopologyEdge>[];
      List<String> neighboursOf(int x, int y) {
        final coords = <String>[];
        for (final d in const [
          [1, 0],
          [-1, 0],
          [0, 1],
          [0, -1],
        ]) {
          final nx = x + d[0];
          final ny = y + d[1];
          if (nx >= 0 && nx < 3 && ny >= 0 && ny < 3) {
            coords.add(nwGrid[ny][nx]);
          }
        }
        return coords;
      }

      for (var y = 0; y < 3; y++) {
        for (var x = 0; x < 3; x++) {
          final id = nwGrid[y][x];
          for (final nb in neighboursOf(x, y)) {
            nwEdges.add(TopologyEdge(id1: id, id2: nb));
          }
        }
      }

      final nwTopology = MapTopology(nodes: nwNodes, edges: nwEdges);
      final nwTileMap = TileMapResult(width: 3, height: 3, grid: nwGrid);

      // Minimal OW to satisfy config; single GP and no minors.
      final owTopology = MapTopology(
        nodes: const [
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
        edges: const [TopologyEdge(id1: 'p1', id2: 'sea1')],
      );
      final owTileMap = TileMapResult(
        width: 1,
        height: 2,
        grid: const [
          ['p1'],
          ['sea1'],
        ],
      );

      const tribeCount = 3;
      const totalNw = 9;
      const basePerTribe = totalNw ~/ tribeCount; // 3

      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: tribeCount,
        numProvincesOldWorld: 1,
        numProvincesNewWorld: totalNw,
        minProvincesPerMinor: 0,
      );

      final result = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: owTileMap,
        topologyOldWorld: owTopology,
        tileMapNewWorld: nwTileMap,
        topologyNewWorld: nwTopology,
        gameId: 'nw-balance',
      );

      final nwProvs = result.game.worldState.newWorld.provinces;
      final countsByTribe = <String, int>{};
      for (final p in nwProvs) {
        final ownerId = p.ownerId ?? '';
        countsByTribe[ownerId] = (countsByTribe[ownerId] ?? 0) + 1;
      }

      expect(countsByTribe.length, tribeCount);
      for (final count in countsByTribe.values) {
        expect(count, inInclusiveRange(basePerTribe - 1, basePerTribe + 1));
      }
    });

    test('Old World minor assignment balances minors by province count', () {
      // OW: 24 provinces in a line, p1 and p2 sea-bound. 2 GPs, 6 minors.
      // reservedForMinors = 6 * 2 = 12, availableForGps = 12.
      // Minors get 12 provinces, basePerMinor = 2 each.
      final owNodes = <TopologyNode>[
        const TopologyNode(
          id: 'sea1',
          regionId: 'oldWorld',
          type: TopologyNodeType.seaZone,
        ),
        for (var i = 1; i <= 24; i++)
          TopologyNode(
            id: 'p$i',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
      ];
      final owEdges = <TopologyEdge>[
        const TopologyEdge(id1: 'p1', id2: 'sea1'),
        const TopologyEdge(id1: 'p2', id2: 'sea1'),
        const TopologyEdge(id1: 'p24', id2: 'sea1'),
        for (var i = 1; i < 24; i++) TopologyEdge(id1: 'p$i', id2: 'p${i + 1}'),
      ];
      final owTopology = MapTopology(nodes: owNodes, edges: owEdges);
      final owTileMap = TileMapResult(
        width: 24,
        height: 2,
        grid: [
          [for (var i = 1; i <= 24; i++) 'p$i'],
          [for (var i = 1; i <= 24; i++) 'sea1'],
        ],
      );

      final nwTopology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'nw1',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'nwSea',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'nw1', id2: 'nwSea')],
      );
      final nwTileMap = TileMapResult(
        width: 1,
        height: 2,
        grid: const [
          ['nw1'],
          ['nwSea'],
        ],
      );

      const minorCount = 6;
      const minPerMinor = 2;
      const totalOw = 24;
      const reservedForMinors = minorCount * minPerMinor; // 12
      const basePerMinor = reservedForMinors ~/ minorCount; // 2

      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england', 'france'],
        continentCount: 1,
        minorNationCount: minorCount,
        tribeCount: 1,
        numProvincesOldWorld: totalOw,
        numProvincesNewWorld: 1,
        minProvincesPerMinor: minPerMinor,
      );

      final result = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: owTileMap,
        topologyOldWorld: owTopology,
        tileMapNewWorld: nwTileMap,
        topologyNewWorld: nwTopology,
        gameId: 'ow-minor-balance',
      );

      final owProvs = result.game.worldState.oldWorld.provinces;
      final minorCounts = <String, int>{};
      for (final p in owProvs) {
        final ownerId = p.ownerId ?? '';
        if (ownerId.startsWith('minor')) {
          minorCounts[ownerId] = (minorCounts[ownerId] ?? 0) + 1;
        }
      }

      expect(
        minorCounts.length,
        minorCount,
        reason: 'Every minor should have at least one province',
      );
      for (final count in minorCounts.values) {
        expect(
          count,
          greaterThanOrEqualTo(1),
          reason: 'Each minor must have at least 1 province',
        );
        expect(
          count,
          inInclusiveRange(basePerMinor - 1, basePerMinor + 1),
          reason: 'Minor province counts should be within ±1 of equal split',
        );
      }
    });
  });
}
