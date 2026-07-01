import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_test/game_test_fixtures.dart';

void main() {
  late final TileMapResult ironTileMap;
  late final TileMapResult grainTileMap;

  setUpAll(() {
    ironTileMap = singleTileMap(Resource.iron);
    grainTileMap = singleTileMap(Resource.grain);
  });

  group('ResourceExtractor', () {
    test('extracts wool and copper when present on tile map', () {
      final grid = [
        ['p1', 'p1'],
        ['p1', 'p1'],
      ];
      final resourceGrid = [
        [Resource.wool, Resource.copper],
        [Resource.timber, Resource.iron],
      ];
      final tileMap = TileMapResult(
        width: 2,
        height: 2,
        grid: grid,
        resourceGrid: resourceGrid,
      );
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 1)
          .setImprovement('oldWorld|p1|1|0', 1)
          .setImprovement('oldWorld|p1|0|1', 1)
          .setImprovement('oldWorld|p1|1|1', 1)
          .setRoadLevel('oldWorld|p1|0|0', 1)
          .setRoadLevel('oldWorld|p1|1|0', 1)
          .setRoadLevel('oldWorld|p1|0|1', 1)
          .setRoadLevel('oldWorld|p1|1|1', 1);
      final connectedTiles = {
        'oldWorld|p1|0|0',
        'oldWorld|p1|1|0',
        'oldWorld|p1|0|1',
        'oldWorld|p1|1|1',
      };
      final game = resourceExtractorGame(
        tileState: tileState,
        playerProspectedTiles: {'pl1': connectedTiles},
      );
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: connectivityFor(connectedTiles),
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1']!.land['wool'], 1);
      expect(result['pl1']!.land['copper'], 1);
      expect(result['pl1']!.land['timber'], 1);
      expect(result['pl1']!.land['iron'], 1);
    });

    test('mineral tiles without prospected are excluded from extraction', () {
      final tileMap = ironTileMap;
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 2)
          .setRoadLevel('oldWorld|p1|0|0', 2);
      final game = resourceExtractorGame(tileState: tileState);
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: connectivityFor({'oldWorld|p1|0|0'}),
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1']!.land['iron'], isNull);
      expect(result['pl1']!.land, isEmpty);
    });

    test('mineral from prospected tile counts in land', () {
      final tileMap = ironTileMap;
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 2)
          .setRoadLevel('oldWorld|p1|0|0', 2);
      final game = resourceExtractorGame(
        tileState: tileState,
        playerProspectedTiles: {
          'pl1': {'oldWorld|p1|0|0'},
        },
      );
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: connectivityFor({'oldWorld|p1|0|0'}),
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1']!.land['iron'], 2);
    });

    test('effective extraction capped by province townDevelopmentLevel', () {
      final tileMap = grainTileMap;
      final tileState = TileMapState()
          .setImprovement('oldWorld|p1|0|0', 4)
          .setRoadLevel('oldWorld|p1|0|0', 4);
      final game = resourceExtractorGame(
        tileState: tileState,
        townDevelopmentLevel: 1,
      );
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: connectivityFor({'oldWorld|p1|0|0'}),
        techCapForPlayer: (_) => 4,
      );
      expect(result['pl1']!.land['grain'], 1);
    });

    test('town-rule-only + non-port: townDevelopmentLevel does NOT cap yield', () {
      final grid = [
        ['p1', 'p1', 'p1'],
        ['p1', 'p2', 'p2'],
        ['p1', 'p2', 'p2'],
      ];
      final resourceGrid = [
        [null, null, null],
        [null, Resource.grain, null],
        [null, null, null],
      ];
      final tileMap = TileMapResult(
        width: 3,
        height: 3,
        grid: grid,
        resourceGrid: resourceGrid,
      );
      final cap = CapitalTile(
        regionId: 'oldWorld',
        provinceId: 'oldWorld|p1',
        x: 0,
        y: 0,
      );
      final tileState = TileMapState()
          .setRoadLevel('oldWorld|p1|0|0', 1)
          .setImprovement('oldWorld|p2|1|1', 4)
          .setRoadLevel('oldWorld|p2|1|1', 0);
      final player = Player(
        id: 'pl1',
        displayName: 'Spain',
        isHuman: true,
        capitalProvinceId: 'oldWorld|p1',
        capitalTile: cap,
      );
      final game = TestFixtures.minimalGame(
        id: 'g1',
        capitalTileGrainBonusPerTurn: 0,
        oldWorld: RegionData(
          provinces: [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              ownerId: 'pl1',
              townTileKey: 'oldWorld|p1|0|0',
              townDevelopmentLevel: 4,
            ),
            Province(
              id: 'oldWorld|p2',
              regionId: 'oldWorld',
              ownerId: 'pl1',
              townTileKey: 'oldWorld|p2|1|0',
              townDevelopmentLevel: 2,
            ),
          ],
        ),
        tileState: tileState,
        players: [player],
      );
      final tileKey = 'oldWorld|p2|1|1';
      final result = computeExtraction(
        game: game,
        tileMapByRegion: {'oldWorld': tileMap},
        connectivityResult: connectivityFor(
          {tileKey},
          pathTransportCap: {tileKey: 4},
        ),
        techCapForPlayer: (_) => 4,
      );
      expect(
        result['pl1']!.land['grain'],
        4,
        reason:
            'town-rule-only tile with non-port town; townDevelopmentLevel=2 must NOT cap '
            'yield of 4 (SPEC/game/extraction-and-improvements.md § Extraction formula)',
      );
    });
  });
}
