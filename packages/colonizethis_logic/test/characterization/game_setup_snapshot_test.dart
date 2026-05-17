import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';

void main() {
  group('GameSetup characterization', () {
    late GameSetupResult result;

    setUpAll(() {
      final owGrid = [
        ['p1', 'p2', 'p3', 'p4', 'p5', 'p6'],
        ['sea1', 'sea1', 'p7', 'p8', 'p9', 'p10'],
      ];
      final owTopology = MapTopology(
        nodes: [
          for (var i = 1; i <= 10; i++)
            TopologyNode(
              id: 'p$i',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          const TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [
          const TopologyEdge(id1: 'p1', id2: 'sea1'),
          const TopologyEdge(id1: 'p2', id2: 'sea1'),
          const TopologyEdge(id1: 'p1', id2: 'p2'),
          const TopologyEdge(id1: 'p2', id2: 'p3'),
          const TopologyEdge(id1: 'p3', id2: 'p4'),
          const TopologyEdge(id1: 'p4', id2: 'p5'),
          const TopologyEdge(id1: 'p5', id2: 'p6'),
          const TopologyEdge(id1: 'p3', id2: 'p7'),
          const TopologyEdge(id1: 'p7', id2: 'p8'),
          const TopologyEdge(id1: 'p8', id2: 'p9'),
          const TopologyEdge(id1: 'p9', id2: 'p10'),
          const TopologyEdge(id1: 'p4', id2: 'p8'),
          const TopologyEdge(id1: 'p5', id2: 'p9'),
          const TopologyEdge(id1: 'p6', id2: 'p10'),
          const TopologyEdge(id1: 'p7', id2: 'sea1'),
        ],
      );
      final owTileMap = TileMapResult(width: 6, height: 2, grid: owGrid);

      final nwGrid = [
        ['nw1', 'nw2', 'nw3'],
        ['nwSea', 'nwSea', 'nwSea'],
      ];
      final nwTopology = MapTopology(
        nodes: [
          for (final id in ['nw1', 'nw2', 'nw3'])
            TopologyNode(
              id: id,
              regionId: 'newWorld',
              type: TopologyNodeType.province,
            ),
          const TopologyNode(
            id: 'nwSea',
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [
          const TopologyEdge(id1: 'nw1', id2: 'nwSea'),
          const TopologyEdge(id1: 'nw2', id2: 'nwSea'),
          const TopologyEdge(id1: 'nw3', id2: 'nwSea'),
          const TopologyEdge(id1: 'nw1', id2: 'nw2'),
          const TopologyEdge(id1: 'nw2', id2: 'nw3'),
        ],
      );
      final nwTileMap = TileMapResult(width: 3, height: 2, grid: nwGrid);

      final config = GameSetupConfig(
        selectedGreatPowerIds: ['england', 'france'],
        continentCount: 1,
        minorNationCount: 1,
        tribeCount: 3,
        numProvincesOldWorld: 10,
        numProvincesNewWorld: 3,
        minProvincesPerMinor: 2,
        seed: 42,
      );

      result = createGameFromGeneratedMaps(
        config: config,
        tileMapOldWorld: owTileMap,
        topologyOldWorld: owTopology,
        tileMapNewWorld: nwTileMap,
        topologyNewWorld: nwTopology,
        gameId: 'char-snapshot',
        namingSeed: 42,
      );
    });

    test('player count and ids', () {
      expect(result.game.players.length, 2);
      expect(result.game.players[0].id, 'gp1');
      expect(result.game.players[1].id, 'gp2');
    });

    test('minor and tribe counts', () {
      expect(result.game.minorNations.length, 1);
      expect(result.game.tribes.length, 3);
    });

    test('OW province assignment is deterministic', () {
      final owProvinces = result.game.worldState.oldWorld.provinces;
      expect(owProvinces.length, 10);
      final ownerById = {for (final p in owProvinces) p.id: p.ownerId};

      // GPs should own (10 - 1*2) = 8 provinces, 4 each
      final gp1Count = ownerById.values.where((o) => o == 'gp1').length;
      final gp2Count = ownerById.values.where((o) => o == 'gp2').length;
      expect(gp1Count + gp2Count, 8);
      expect(gp1Count, 4);
      expect(gp2Count, 4);

      // Minor should own 2 provinces
      final minorCount = ownerById.values.where((o) => o == 'minor1').length;
      expect(minorCount, 2);
    });

    test('NW province assignment is deterministic', () {
      final nwProvinces = result.game.worldState.newWorld.provinces;
      expect(nwProvinces.length, 3);
      final ownerById = {for (final p in nwProvinces) p.id: p.ownerId};
      for (final tribeId in ['tribe1', 'tribe2', 'tribe3']) {
        expect(ownerById.values.where((o) => o == tribeId).length, 1);
      }
    });

    test('capitals are assigned for all factions', () {
      for (final p in result.game.players) {
        expect(
          p.capitalProvinceId,
          isNotNull,
          reason: '${p.id} must have capital',
        );
        expect(
          p.capitalTile,
          isNotNull,
          reason: '${p.id} must have capital tile',
        );
      }
      for (final m in result.game.minorNations) {
        expect(
          m.capitalProvinceId,
          isNotNull,
          reason: '${m.id} must have capital',
        );
      }
      for (final t in result.game.tribes) {
        expect(
          t.capitalProvinceId,
          isNotNull,
          reason: '${t.id} must have capital',
        );
      }
    });

    test('naming is applied to all provinces', () {
      for (final p in allProvinces(result.game.worldState)) {
        expect(p.displayName, isNotNull, reason: '${p.id} must have name');
        expect(
          p.displayName,
          isNotEmpty,
          reason: '${p.id} must have non-empty name',
        );
      }
    });

    test('land province display names are unique within each region', () {
      final owNames = result.game.worldState.oldWorld.provinces
          .map((p) => p.displayName!)
          .toList();
      expect(owNames.length, owNames.toSet().length);
      final nwNames = result.game.worldState.newWorld.provinces
          .map((p) => p.displayName!)
          .toList();
      expect(nwNames.length, nwNames.toSet().length);
    });

    test('within-faction province names are distinct in snapshot fixture', () {
      final ws = result.game.worldState;
      for (final owner in ['gp1', 'gp2', 'minor1']) {
        final names = ws.oldWorld.provinces
            .where((p) => p.ownerId == owner)
            .map((p) => p.displayName!)
            .toList();
        expect(names.length, names.toSet().length, reason: owner);
      }
      for (final owner in ['tribe1', 'tribe2', 'tribe3']) {
        final names = ws.newWorld.provinces
            .where((p) => p.ownerId == owner)
            .map((p) => p.displayName!)
            .toList();
        expect(names.length, names.toSet().length, reason: owner);
      }
    });

    test('GP display names and leader keys set from naming config', () {
      expect(result.game.players[0].displayName, 'England');
      expect(result.game.players[1].displayName, 'France');
      expect(result.game.players[0].leaderKey, isNotNull);
      expect(result.game.players[1].leaderKey, isNotNull);
    });

    test('initial visibility is set for all GPs', () {
      final vis = result.game.worldState.playerVisibilityByTile;
      for (final p in result.game.players) {
        expect(
          vis.containsKey(p.id),
          isTrue,
          reason: '${p.id} must have visibility',
        );
        expect(
          vis[p.id],
          isNotEmpty,
          reason: '${p.id} must have non-empty visibility',
        );
      }
    });

    test('starting units are spawned in capital provinces', () {
      final allUnits = [
        ...result.game.worldState.oldWorld.units,
        ...result.game.worldState.newWorld.units,
      ];
      for (final p in result.game.players) {
        final playerUnits = allUnits.where((u) => u.ownerId == p.id).toList();
        expect(
          playerUnits,
          isNotEmpty,
          reason: '${p.id} must have starting units',
        );
        for (final u in playerUnits) {
          expect(
            u.locationProvinceId,
            p.capitalProvinceId,
            reason: 'Unit ${u.id} must be in capital ${p.capitalProvinceId}',
          );
        }
      }
    });

    test('combined topology merges both regions', () {
      final combined = result.combinedTopology;
      expect(
        combined.nodes.length,
        result.topologyByRegion['oldWorld']!.nodes.length +
            result.topologyByRegion['newWorld']!.nodes.length,
      );
    });

    test('turnTimeMapping is set', () {
      expect(result.game.turnTimeMapping, isNotNull);
    });
  });
}
