import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:image/image.dart' as img;

import 'support/init_game_map_view_fixtures.dart';

void main() {
  final topology = singleProvinceAndSeaTopology('oldWorld');

  final smallResult = mapTileGrid([
    ['p1', 's1'],
    ['s1', 's1'],
  ]);

  group('renderSingleRegionGameStateMapToPng', () {
    test('returns non-empty PNG with default faction colors', () {
      final bytes = renderSingleRegionGameStateMapToPng(
        result: smallResult,
        topology: topology,
        regionId: 'oldWorld',
        ownerByProvinceId: {'oldWorld|p1': 'gp1'},
        capitalTiles: [],
        cellSize: 8,
      );
      expect(bytes, isNotEmpty);
      final decoded = img.decodeImage(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, 2 * 8);
      expect(decoded.height, greaterThanOrEqualTo(2 * 8));
    });

    test('with factionColorsOverride and capital and port tiles', () {
      final bytes = renderSingleRegionGameStateMapToPng(
        result: smallResult,
        topology: topology,
        regionId: 'oldWorld',
        ownerByProvinceId: {'oldWorld|p1': 'gp1'},
        capitalTiles: [
          (factionId: 'gp1', displayName: 'GP1', x: 0, y: 0),
        ],
        portTiles: [(x: 0, y: 0)],
        cellSize: 8,
        factionColorsOverride: {'gp1': (100, 100, 100)},
      );
      expect(bytes, isNotEmpty);
      final decoded = img.decodeImage(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.height, greaterThan(2 * 8));
    });

    test('resolves ownership via full province id and colors land tile', () {
      final bytes = renderSingleRegionGameStateMapToPng(
        result: smallResult,
        topology: topology,
        regionId: 'oldWorld',
        ownerByProvinceId: {'oldWorld|p1': 'gp1'},
        capitalTiles: [],
        cellSize: 8,
        factionColorsOverride: {'gp1': (10, 20, 30)},
      );
      final decoded = img.decodeImage(bytes);
      expect(decoded, isNotNull);
      final pixel = decoded!.getPixel(4, 4);
      expect(pixel.r.toInt(), equals(10));
      expect(pixel.g.toInt(), equals(20));
      expect(pixel.b.toInt(), equals(30));
    });
  });

  group('renderInitGameMapToPng', () {
    test('returns non-empty PNG for minimal game', () {
      final owMap = smallResult;
      final nwMap = smallResult;
      final owTopology = singleProvinceAndSeaTopology('oldWorld');
      final nwTopology = singleProvinceAndSeaTopology('newWorld');
      final game = minimalGame(
        id: 'g',
        oldWorldProvinces: const [
          Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            displayName: 'OW P1',
            ownerId: 'gp1',
          ),
        ],
        newWorldProvinces: const [
          Province(
            id: 'newWorld|p1',
            regionId: 'newWorld',
            displayName: 'NW P1',
          ),
        ],
        players: const [
          Player(id: 'gp1', displayName: 'GP1', isHuman: false),
        ],
      );

      final bytes = renderInitGameMapToPng(
        game: game,
        tileMapByRegion: {'oldWorld': owMap, 'newWorld': nwMap},
        topologyByRegion: {'oldWorld': owTopology, 'newWorld': nwTopology},
        cellSize: 8,
      );
      expect(bytes, isNotEmpty);
      final decoded = img.decodeImage(bytes);
      expect(decoded, isNotNull);
    });
  });

  group('renderInitGameMapToPngFromViewData', () {
    test('returns non-empty PNG for ownership and geographic mode', () {
      final scenario = dualRegionViewScenario(
        game: minimalGame(
          id: 'g',
          oldWorldProvinces: const [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              ownerId: 'gp1',
            ),
          ],
          newWorldProvinces: const [
            Province(id: 'newWorld|p1', regionId: 'newWorld'),
          ],
          players: const [Player(id: 'gp1', displayName: 'GP1', isHuman: false)],
        ),
        oldWorldMap: smallResult,
        newWorldMap: smallResult,
        oldWorldTopology: singleProvinceAndSeaTopology('oldWorld'),
        newWorldTopology: singleProvinceAndSeaTopology('newWorld'),
      );
      final viewData = buildViewDataForScenario(scenario);

      final bytesOwnership = renderInitGameMapToPngFromViewData(
        viewData: viewData,
        geographicMode: false,
      );
      expect(bytesOwnership, isNotEmpty);
      expect(img.decodeImage(bytesOwnership), isNotNull);

      final bytesGeographic = renderInitGameMapToPngFromViewData(
        viewData: viewData,
        geographicMode: true,
      );
      expect(bytesGeographic, isNotEmpty);
      expect(img.decodeImage(bytesGeographic), isNotNull);
    });
  });
}
