import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('GameSetup', () {
    test(
      'Prussia with Frederick William variant uses variant province pool and sets leaderKey',
      () {
        // OW: 3 provinces in a line, p1 sea-bound. Single GP (Prussia).
        final owTopology = MapTopology(
          nodes: const [
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
              id: 'sea1',
              regionId: 'oldWorld',
              type: TopologyNodeType.seaZone,
            ),
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
        expect(
          provinceNames.contains('Berlin'),
          true,
          reason: 'Capital must be Berlin',
        );
        expect(
          provinceNames.any((n) => n == 'Prussia' || n == 'Farther Pomerania'),
          true,
          reason:
              'Frederick William pool includes Prussia and Farther Pomerania',
        );
      },
    );

    test('GP province naming names all owned OW provinces on one landmass', () {
      // Single connected OW landmass: p1 (sea)–p2–p3–p4. One GP owns all four; tile map
      // places sea under the coastal strip so capital port placement succeeds.
      final owTopology = MapTopology(
        nodes: const [
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
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [
          TopologyEdge(id1: 'p1', id2: 'sea1'),
          TopologyEdge(id1: 'p1', id2: 'p2'),
          TopologyEdge(id1: 'p2', id2: 'p3'),
          TopologyEdge(id1: 'p3', id2: 'p4'),
        ],
      );
      final owTileMap = TileMapResult(
        width: 4,
        height: 2,
        grid: const [
          ['p1', 'p2', 'p3', 'p4'],
          ['sea1', 'sea1', 'sea1', 'sea1'],
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
      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england'],
        continentCount: 1,
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
        gameId: 'single-landmass-naming',
        namingSeed: 42,
      );
      final gp = result.game.players.first;
      expect(gp.id, 'gp1');
      final ownedOw = result.game.worldState.oldWorld.provinces
          .where((p) => p.ownerId == gp.id)
          .toList();
      expect(ownedOw.length, 4, reason: 'GP should own all 4 OW provinces');
      for (final p in ownedOw) {
        expect(
          p.displayName,
          isNotNull,
          reason: '${p.id} must have displayName',
        );
        expect(
          p.displayName!.isNotEmpty,
          isTrue,
          reason: '${p.id} must have non-empty name',
        );
      }
      final capitalProv = ownedOw.firstWhere(
        (p) => p.id == gp.capitalProvinceId,
      );
      expect(
        capitalProv.displayName,
        'London',
        reason: 'Capital province gets capital city name',
      );
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
        [
          'sea',
          'sea',
          'sea',
          'sea',
          'sea',
          'sea',
          'sea',
          'sea',
          'sea',
          'sea',
          'sea',
        ],
      ];
      final nwNodes = <TopologyNode>[
        const TopologyNode(
          id: 'sea',
          regionId: 'newWorld',
          type: TopologyNodeType.seaZone,
        ),
        for (var i = 1; i <= 11; i++)
          TopologyNode(
            id: 'n$i',
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
      ];
      final nwEdges = <TopologyEdge>[
        for (var i = 1; i <= 11; i++) TopologyEdge(id1: 'n$i', id2: 'sea'),
        for (var i = 1; i < 11; i++) TopologyEdge(id1: 'n$i', id2: 'n${i + 1}'),
      ];
      final nwTopology = MapTopology(nodes: nwNodes, edges: nwEdges);
      final nwTileMap = TileMapResult(width: 11, height: 2, grid: nwGrid);

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
        expect(p.displayName, isNotNull, reason: p.id);
        expect(p.displayName!.isNotEmpty, isTrue, reason: p.id);
      }
      final nwProvinces = result.game.worldState.newWorld.provinces;
      expect(result.game.tribes.length, 11);
      final tribe11 = result.game.tribes.firstWhere((t) => t.id == 'tribe11');
      final tribe11Provinces = nwProvinces
          .where((p) => p.ownerId == tribe11.id)
          .toList();
      expect(tribe11Provinces, isNotEmpty);
      for (final p in tribe11Provinces) {
        expect(p.displayName, isNotNull);
        expect(
          p.displayName!.isNotEmpty,
          isTrue,
          reason: 'tribe11 fallback must produce non-empty name',
        );
      }
    });

  });
}
