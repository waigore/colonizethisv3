import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';

import 'support/game_save_adapter_test_harness.dart';

void main() {
  final harness = GameSaveAdapterHiveHarness(
    hivePath: './.dart_tool/test_hive_save_map',
    boxName: 'games_map',
  );

  setUpAll(harness.open);
  tearDownAll(harness.close);
  setUp(harness.reset);

  group('GameSaveAdapter map data', () {
    test('listGameIds returns saved ids and excludes map-data keys', () {
      final game = minimalSaveGame(id: 'g1');
      harness.adapter.save(harness.box, game);
      harness.adapter.save(harness.box, game.copyWith(id: 'g2'));
      final (tileMap, topo) = minimalSaveMap();
      harness.adapter.saveMapData(
        harness.box,
        'g1',
        tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
        topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
        combinedTopology: topo,
      );
      expect(
        harness.adapter.listGameIds(harness.box),
        containsAll(['g1', 'g2']),
      );
      expect(harness.adapter.listGameIds(harness.box).length, 2);
    });

    test(
      'listGameIds returns game id that ends with suffix when no matching map-data exists',
      () {
        final game = minimalSaveGame(id: 'mygame_tileMapByRegion');
        harness.adapter.save(harness.box, game);
        harness.adapter.save(harness.box, game.copyWith(id: 'normalGame'));

        final ids = harness.adapter.listGameIds(harness.box);
        expect(ids, containsAll(['mygame_tileMapByRegion', 'normalGame']));
        expect(ids.length, 2);
      },
    );

    test(
      'listGameIds excludes map-data keys when corresponding game exists',
      () {
        final game = minimalSaveGame(id: 'gameWithMapData');
        harness.adapter.save(harness.box, game);

        final tileMap = TileMapResult(
          width: 2,
          height: 2,
          grid: [
            ['p1', 'p1'],
            ['p2', 's1'],
          ],
        );
        final topo = MapTopology(
          nodes: [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [],
        );
        harness.adapter.saveMapData(
          harness.box,
          'gameWithMapData',
          tileMapByRegion: {'oldWorld': tileMap},
          topologyByRegion: {'oldWorld': topo},
          combinedTopology: topo,
        );

        final ids = harness.adapter.listGameIds(harness.box);
        expect(ids, contains('gameWithMapData'));
        expect(ids.length, 1);
        expect(ids, isNot(contains('gameWithMapData_tileMapByRegion')));
        expect(ids, isNot(contains('gameWithMapData_topologyByRegion')));
        expect(ids, isNot(contains('gameWithMapData_combinedTopology')));
      },
    );

    test('saveMapData then loadMapData returns same data', () {
      final tileMap = TileMapResult(
        width: 2,
        height: 2,
        grid: [
          ['p1', 'p2'],
          ['s1', 's1'],
        ],
        terrainGrid: [
          [TerrainType.plains, TerrainType.hardwoodForest],
          [null, null],
        ],
        resourceGrid: [
          [Resource.grain, null],
          [null, null],
        ],
      );
      final topo = MapTopology(
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
            id: 's1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [TopologyEdge(id1: 'p1', id2: 'p2')],
      );
      harness.adapter.saveMapData(
        harness.box,
        'mapGame',
        tileMapByRegion: {'oldWorld': tileMap, 'newWorld': tileMap},
        topologyByRegion: {'oldWorld': topo, 'newWorld': topo},
        combinedTopology: topo,
      );
      final loaded = harness.adapter.loadMapData(harness.box, 'mapGame');
      expect(loaded, isNotNull);
      expect(loaded.tileMapByRegion['oldWorld']!.width, 2);
      expect(loaded.tileMapByRegion['oldWorld']!.height, 2);
      expect(loaded.tileMapByRegion['oldWorld']!.cell(0, 0), 'p1');
      expect(
        loaded.tileMapByRegion['oldWorld']!.terrainAt(0, 0),
        TerrainType.plains,
      );
      expect(
        loaded.tileMapByRegion['oldWorld']!.resourceAt(0, 0),
        Resource.grain,
      );
      expect(loaded.combinedTopology.nodes.length, 3);
      expect(loaded.combinedTopology.edges.length, 1);
    });

    test('loadMapData throws when required map data is missing', () {
      expect(
        () => harness.adapter.loadMapData(harness.box, 'noMapData'),
        throwsA(isA<StateError>()),
      );
    });

    test('loadMapData throws for invalid map data JSON', () {
      harness.box.put('invalidMap_tileMapByRegion', {'invalid': 'data'});
      harness.box.put('invalidMap_topologyByRegion', {'nodes': 'not-a-list'});
      harness.box.put('invalidMap_combinedTopology', 'also invalid');
      expect(
        () => harness.adapter.loadMapData(harness.box, 'invalidMap'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
