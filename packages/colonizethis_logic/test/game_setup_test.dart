import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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

      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 2,
        numProvincesNewWorld: 1,
        minProvincesPerMinor: 0,
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
      expect(result.game.players.first.capitalProvinceId, 'oldWorld|p1');
      expect(result.game.players.first.capitalTile?.provinceId, 'oldWorld|p1');

      expect(result.game.minorNations, isEmpty);
      expect(result.game.tribes.length, 1);
      expect(result.game.tribes.first.id, 'tribe1');
      expect(result.game.tribes.first.capitalProvinceId, 'newWorld|nw1');
      expect(result.game.tribes.first.capitalTile?.regionId, 'newWorld');

      expect(result.game.worldState.oldWorld.provinces.length, 2);
      expect(result.game.worldState.newWorld.provinces.length, 1);
      expect(result.game.worldState.portsByProvinceSeaboard.containsKey('oldWorld|p1|sea1'), true);
      expect(result.game.worldState.portsByProvinceSeaboard.containsKey('newWorld|nw1|sea1'), true);

      // SPEC capital-and-connectivity § Town per province: every province has townTileKey set.
      final gp = result.game.players.first;
      for (final p in allProvinces(result.game.worldState)) {
        expect(p.townTileKey, isNotNull, reason: 'province ${p.id} must have townTileKey');
      }
      final capitalProvince = result.game.worldState.oldWorld.provinces.firstWhere((p) => p.id == gp.capitalProvinceId);
      expect(capitalProvince.townTileKey, gp.capitalTile?.toTileKey(), reason: 'Capital province townTileKey must equal capital tile key');

      // Province naming: mandatory; GP capital gets capital city name, others from pool.
      expect(result.game.players.first.displayName, 'England');
      for (final p in allProvinces(result.game.worldState)) {
        expect(p.displayName, isNotNull, reason: 'province ${p.id} must have displayName');
      }
      final p1 = result.game.worldState.oldWorld.provinces.firstWhere((p) => p.id == 'oldWorld|p1');
      expect(p1.displayName, 'London');
      final nw1 = result.game.worldState.newWorld.provinces.firstWhere((p) => p.id == 'newWorld|nw1');
      expect(nw1.displayName, 'Mexica');
      expect(result.game.tribes.first.displayName, 'Aztec');

      expect(result.tileMapByRegion['oldWorld'], owTileMap);
      expect(result.topologyByRegion['oldWorld'], owTopology);

      // Initial visibility: Old World starts fogged/visible, New World unknown.
      final visibility = result.game.worldState.playerVisibilityByTile;
      expect(visibility, isNotEmpty);
      final gp1Visibility = visibility[result.game.players.first.id] ?? const {};
      expect(gp1Visibility.keys, isNotEmpty);
      // All initial visible tiles for the starting GP are in Old World; New
      // World tiles are unknown (absent from visibility map).
      expect(
        gp1Visibility.keys.every((tk) => tk.startsWith('oldWorld|')),
        isTrue,
      );
    });

    test('each Great Power has enough resources to build 5 improvements (bootstrap)', () {
      // SPEC/program/game-setup-pipeline.md §7f: initialImprovementSlots default 5.
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
      final nwGrid = [['nw1', 'sea1'], ['nw1', 'nw1']];
      final nwTopology = MapTopology(
        nodes: [
          TopologyNode(id: 'nw1', regionId: 'newWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'newWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [TopologyEdge(id1: 'nw1', id2: 'sea1')],
      );
      final nwTileMap = TileMapResult(width: 2, height: 2, grid: nwGrid);
      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 2,
        numProvincesNewWorld: 1,
        minProvincesPerMinor: 0,
      );
      final result = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: owTileMap,
        topologyOldWorld: owTopology,
        tileMapNewWorld: nwTileMap,
        topologyNewWorld: nwTopology,
        gameId: 'test-bootstrap',
      );
      final start = config.startingResources;
      final expectedGrain = start.initialPeasants * start.initialGrainTurns;
      for (final player in result.game.players) {
        expect(
          player.stockpile.quantityOf(CommodityCatalog.grain.id),
          expectedGrain,
          reason: '${player.id} grain',
        );
        expect(
          player.stockpile.quantityOf(CommodityCatalog.lumber.id),
          start.initialImprovementSlots,
          reason: '${player.id} lumber for 5 improvements',
        );
        expect(
          player.stockpile.quantityOf(CommodityCatalog.castIron.id),
          start.initialImprovementSlots,
          reason: '${player.id} castIron for 5 improvements',
        );
        expect(
          player.stockpile.quantityOf(CommodityCatalog.wool.id),
          start.initialWool,
          reason: '${player.id} starting wool',
        );
      }
    });

    test('Old World assignment reserves provinces for minors based on config', () {
      // Simple OW topology with 12 provinces in a line, p1 and p2 sea-bound.
      final owNodes = <TopologyNode>[
        const TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        for (var i = 1; i <= 12; i++)
          TopologyNode(id: 'p$i', regionId: 'oldWorld', type: TopologyNodeType.province),
      ];
      final owEdges = <TopologyEdge>[
        const TopologyEdge(id1: 'p1', id2: 'sea1'),
        const TopologyEdge(id1: 'p2', id2: 'sea1'),
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
          TopologyNode(id: 'nw1', regionId: 'newWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'nwSea', regionId: 'newWorld', type: TopologyNodeType.seaZone),
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
      final gpOwned = ow.where((p) => p.ownerId == 'gp1' || p.ownerId == 'gp2').length;
      final minorOwned = ow.where((p) => p.ownerId == 'minor1' || p.ownerId == 'minor2').length;

      expect(gpOwned, availableForGps);
      expect(minorOwned, totalOw - availableForGps);
    });

    test('New World assignment balances tribes by province count', () {
      // NW: 9 provinces in a 3x3 grid; simple adjacency.
      final nwGrid = [
        ['n1', 'n2', 'n3'],
        ['n4', 'n5', 'n6'],
        ['n7', 'n8', 'n9'],
      ];
      final nwNodes = <TopologyNode>[
        for (final id in ['n1', 'n2', 'n3', 'n4', 'n5', 'n6', 'n7', 'n8', 'n9'])
          TopologyNode(id: id, regionId: 'newWorld', type: TopologyNodeType.province),
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
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
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
        const TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        for (var i = 1; i <= 24; i++)
          TopologyNode(id: 'p$i', regionId: 'oldWorld', type: TopologyNodeType.province),
      ];
      final owEdges = <TopologyEdge>[
        const TopologyEdge(id1: 'p1', id2: 'sea1'),
        const TopologyEdge(id1: 'p2', id2: 'sea1'),
        for (var i = 1; i < 24; i++)
          TopologyEdge(id1: 'p$i', id2: 'p${i + 1}'),
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
          TopologyNode(id: 'nw1', regionId: 'newWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'nwSea', regionId: 'newWorld', type: TopologyNodeType.seaZone),
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

      expect(minorCounts.length, minorCount, reason: 'Every minor should have at least one province');
      for (final count in minorCounts.values) {
        expect(count, greaterThanOrEqualTo(1), reason: 'Each minor must have at least 1 province');
        expect(count, inInclusiveRange(basePerMinor - 1, basePerMinor + 1),
            reason: 'Minor province counts should be within ±1 of equal split');
      }
    });

    test('Prussia with Frederick William variant uses variant province pool and sets leaderKey', () {
      // OW: 3 provinces in a line, p1 sea-bound. Single GP (Prussia).
      final owTopology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p3', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [
          TopologyEdge(id1: 'p1', id2: 'sea1'),
          TopologyEdge(id1: 'p1', id2: 'p2'),
          TopologyEdge(id1: 'p2', id2: 'p3'),
        ],
      );
      final owTileMap = TileMapResult(
        width: 3,
        height: 2,
        grid: const [
          ['p1', 'p2', 'p3'],
          ['sea1', 'sea1', 'sea1'],
        ],
      );

      final nwTopology = MapTopology(
        nodes: const [
          TopologyNode(id: 'nw1', regionId: 'newWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'nwSea', regionId: 'newWorld', type: TopologyNodeType.seaZone),
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

      final config = GameSetupConfig(
        selectedGreatPowerIds: ['prussia'],
        leaderVariantByGpId: {'prussia': prussiaVariantFrederickWilliam},
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 3,
        numProvincesNewWorld: 1,
        minProvincesPerMinor: 0,
        seed: 12345,
      );

      final result = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: owTileMap,
        topologyOldWorld: owTopology,
        tileMapNewWorld: nwTileMap,
        topologyNewWorld: nwTopology,
        gameId: 'prussia-fw',
        namingSeed: 12345,
      );

      expect(result.game.players.length, 1);
      final prussiaPlayer = result.game.players.first;
      expect(prussiaPlayer.displayName, 'Prussia');
      expect(prussiaPlayer.leaderKey, 'prussia_reserve_leader');

      final owProvinces = result.game.worldState.oldWorld.provinces;
      final provinceNames = owProvinces.map((p) => p.displayName).toSet();
      expect(provinceNames.contains('Berlin'), true, reason: 'Capital must be Berlin');
      expect(
        provinceNames.any((n) => n == 'Prussia' || n == 'Farther Pomerania'),
        true,
        reason: 'Frederick William pool includes Prussia and Farther Pomerania',
      );
    });

    test('GP province naming names all owned OW provinces across landmasses', () {
      // Two disconnected OW landmasses: A = p1 (sea), p2; B = p3 (sea), p4. One GP gets all 4.
      final owTopology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p3', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p4', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
          TopologyNode(id: 'sea2', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [
          TopologyEdge(id1: 'p1', id2: 'sea1'),
          TopologyEdge(id1: 'p1', id2: 'p2'),
          TopologyEdge(id1: 'p3', id2: 'sea2'),
          TopologyEdge(id1: 'p3', id2: 'p4'),
        ],
      );
      final owTileMap = TileMapResult(
        width: 4,
        height: 2,
        grid: const [
          ['p1', 'p2', 'p3', 'p4'],
          ['sea1', 'sea1', 'sea2', 'sea2'],
        ],
      );
      final nwTopology = MapTopology(
        nodes: const [
          TopologyNode(id: 'nw1', regionId: 'newWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'nwSea', regionId: 'newWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [TopologyEdge(id1: 'nw1', id2: 'nwSea')],
      );
      final nwTileMap = TileMapResult(
        width: 1,
        height: 2,
        grid: const [['nw1'], ['nwSea']],
      );
      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england'],
        continentCount: 2,
        minorNationCount: 0,
        tribeCount: 1,
        numProvincesOldWorld: 4,
        numProvincesNewWorld: 1,
        minProvincesPerMinor: 0,
        seed: 42,
      );
      final result = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: owTileMap,
        topologyOldWorld: owTopology,
        tileMapNewWorld: nwTileMap,
        topologyNewWorld: nwTopology,
        gameId: 'multi-landmass-naming',
        namingSeed: 42,
      );
      final gp = result.game.players.first;
      expect(gp.id, 'gp1');
      final ownedOw = result.game.worldState.oldWorld.provinces
          .where((p) => p.ownerId == gp.id)
          .toList();
      expect(ownedOw.length, 4, reason: 'GP should own all 4 OW provinces');
      for (final p in ownedOw) {
        expect(p.displayName, isNotNull, reason: '${p.id} must have displayName');
        expect(p.displayName!.isNotEmpty, isTrue, reason: '${p.id} must have non-empty name');
      }
      final capitalProv = ownedOw.firstWhere((p) => p.id == gp.capitalProvinceId);
      expect(capitalProv.displayName, 'London', reason: 'Capital province gets capital city name');
    });

    test('allGreatPowerIds has 7 entries (no prussia_reserve)', () {
      expect(allGreatPowerIds.length, 7);
      expect(allGreatPowerIds, contains('prussia'));
      expect(allGreatPowerIds, isNot(contains('prussia_reserve')));
    });

    test('province naming fallback when tribe count exceeds naming config', () {
      // Default naming has tribe1..tribe10. Use 11 tribes so tribe11 uses fallback.
      final nwGrid = [
        ['n1', 'n2', 'n3', 'n4', 'n5', 'n6', 'n7', 'n8', 'n9', 'n10', 'n11'],
        ['sea', 'sea', 'sea', 'sea', 'sea', 'sea', 'sea', 'sea', 'sea', 'sea', 'sea'],
      ];
      final nwNodes = <TopologyNode>[
        const TopologyNode(id: 'sea', regionId: 'newWorld', type: TopologyNodeType.seaZone),
        for (var i = 1; i <= 11; i++)
          TopologyNode(id: 'n$i', regionId: 'newWorld', type: TopologyNodeType.province),
      ];
      final nwEdges = <TopologyEdge>[
        for (var i = 1; i <= 11; i++) TopologyEdge(id1: 'n$i', id2: 'sea'),
        for (var i = 1; i < 11; i++) TopologyEdge(id1: 'n$i', id2: 'n${i + 1}'),
      ];
      final nwTopology = MapTopology(nodes: nwNodes, edges: nwEdges);
      final nwTileMap = TileMapResult(width: 11, height: 2, grid: nwGrid);

      final owTopology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 'sea1')],
      );
      final owTileMap = TileMapResult(
        width: 1,
        height: 2,
        grid: const [['p1'], ['sea1']],
      );

      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england'],
        continentCount: 1,
        minorNationCount: 0,
        tribeCount: 11,
        numProvincesOldWorld: 1,
        numProvincesNewWorld: 11,
        minProvincesPerMinor: 0,
      );

      final result = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: owTileMap,
        topologyOldWorld: owTopology,
        tileMapNewWorld: nwTileMap,
        topologyNewWorld: nwTopology,
        gameId: 'fallback-test',
      );

      for (final p in allProvinces(result.game.worldState)) {
        expect(p.displayName, isNotNull, reason: '${p.id}');
        expect(p.displayName!.isNotEmpty, isTrue, reason: '${p.id}');
      }
      final nwProvinces = result.game.worldState.newWorld.provinces;
      expect(result.game.tribes.length, 11);
      final tribe11 = result.game.tribes.firstWhere((t) => t.id == 'tribe11');
      final tribe11Provinces = nwProvinces.where((p) => p.ownerId == tribe11.id).toList();
      expect(tribe11Provinces, isNotEmpty);
      for (final p in tribe11Provinces) {
        expect(p.displayName, isNotNull);
        expect(p.displayName!.isNotEmpty, isTrue, reason: 'tribe11 fallback must produce non-empty name');
      }
    });

    test('regional faction discovery - same-region relations initialized, cross-region undiscovered', () {
      // OW: 2 provinces for 1 GP, 1 Minor
      final owTopology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
          TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p3', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'p2', id2: 'p1'),
          TopologyEdge(id1: 'p2', id2: 'p3'),
        ],
      );
      final owTileMap = TileMapResult(
        width: 2,
        height: 2,
        grid: const [
          ['p2', 'p3'],
          ['p1', 'p1'],
        ],
      );

      // NW: 1 province for 1 Tribe
      final nwTopology = MapTopology(
        nodes: const [
          TopologyNode(id: 'nw1', regionId: 'newWorld', type: TopologyNodeType.seaZone),
          TopologyNode(id: 'nw2', regionId: 'newWorld', type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'nw2', id2: 'nw1')],
      );
      final nwTileMap = TileMapResult(
        width: 1,
        height: 2,
        grid: const [
          ['nw2'],
          ['nw1'],
        ],
      );

      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england'],
        continentCount: 1,
        minorNationCount: 1,
        tribeCount: 1,
        numProvincesOldWorld: 2,
        numProvincesNewWorld: 1,
        minProvincesPerMinor: 0,
      );

      final result = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: owTileMap,
        topologyOldWorld: owTopology,
        tileMapNewWorld: nwTileMap,
        topologyNewWorld: nwTopology,
        gameId: 'regional-discovery',
      );

      // Old World pairs should have relations initialized
      // gp1-minor1 (OW-OW) should have a relation
      final owRelation = result.game.diplomacyRelations.firstWhere(
        (r) => (r.factionId1 == 'gp1' && r.factionId2 == 'minor1') ||
               (r.factionId1 == 'minor1' && r.factionId2 == 'gp1'),
        orElse: () => throw Exception('GP-Minor relation not found'),
      );
      expect(owRelation.state, RelationState.atPeace);
      expect(owRelation.score, 50);

      // Cross-region pairs should be absent (undiscovered)
      final crossRelationCount = result.game.diplomacyRelations.where(
        (r) => (r.factionId1 == 'gp1' && r.factionId2 == 'tribe1') ||
               (r.factionId2 == 'gp1' && r.factionId1 == 'tribe1') ||
               (r.factionId1 == 'minor1' && r.factionId2 == 'tribe1') ||
               (r.factionId2 == 'minor1' && r.factionId1 == 'tribe1'),
      ).length;
      expect(crossRelationCount, 0, reason: 'No cross-region relations should exist');
    });

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
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p3', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p4', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p5', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p6', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
          TopologyNode(id: 'sea2', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
          TopologyNode(id: 'sea3', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
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
          TopologyNode(id: 'nw1', regionId: 'newWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'sea1', regionId: 'newWorld', type: TopologyNodeType.seaZone),
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
      expect(gp1Provinces.isNotEmpty, true, reason: 'GP1 should have provinces');
      expect(gp2Provinces.isNotEmpty, true, reason: 'GP2 should have provinces');

      // Compute landmass IDs for each province
      // Landmass A: p1, p2, p3 (connected via p1-p2-p3)
      // Landmass B: p4, p5, p6 (connected via p4-p5-p6)
      final landmassAPart1 = {'p1', 'p2', 'p3'};
      final landmassBPart1 = {'p4', 'p5', 'p6'};

      // Check that each GP's provinces are all on the same landmass
      final gp1OnLandmassA = gp1Provinces.any((p) => landmassAPart1.contains(p));
      final gp1OnLandmassB = gp1Provinces.any((p) => landmassBPart1.contains(p));
      final gp2OnLandmassA = gp2Provinces.any((p) => landmassAPart1.contains(p));
      final gp2OnLandmassB = gp2Provinces.any((p) => landmassBPart1.contains(p));

      // Each GP should be on exactly one landmass
      expect(gp1OnLandmassA && !gp1OnLandmassB || !gp1OnLandmassA && gp1OnLandmassB, true,
          reason: 'GP1 should be on exactly one landmass, got: $gp1Provinces');
      expect(gp2OnLandmassA && !gp2OnLandmassB || !gp2OnLandmassA && gp2OnLandmassB, true,
          reason: 'GP2 should be on exactly one landmass, got: $gp2Provinces');

      // GPs should be on different landmasses
      expect(gp1OnLandmassA != gp2OnLandmassA || gp1OnLandmassB != gp2OnLandmassB, true,
          reason: 'GPs should be on different landmasses');
    });
  });
}
