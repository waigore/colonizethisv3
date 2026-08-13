import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

import 'support/init_game_map_view_fixtures.dart';
import 'support/init_game_map_view_visualization_fixtures.dart';
import 'package:colonizethis_map/src/render/tile_map_visualization_legend_layout.dart'
    show legendHeightForLineCount;
import 'tile_map_visualization_test_fixtures.dart';

void main() {
  group('renderTileMapToPng', () {
    test('returns non-empty PNG bytes', () {
      final bytes = renderTileMapPngBytes(
        visualizationSmallResult,
        visualizationTopology,
        cellSize: 4,
      );
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('decoded image has expected dimensions (map + legend)', () {
      const cellSize = 8;
      final decoded = decodeRenderTileMapToPng(
        visualizationSmallResult,
        visualizationTopology,
        cellSize: cellSize,
      );
      expect(decoded.width, 32);
      expect(decoded.height, greaterThanOrEqualTo(24));
    });

    test(
      'dimensions with terrain: width and height match map + terrain legend',
      () {
        const cellSize = 8;
        final decoded = decodeRenderTileMapToPng(
          visualizationResultWithTerrain,
          visualizationTopology,
          cellSize: cellSize,
        );
        final mapW = visualizationResultWithTerrain.width * cellSize;
        final mapH = visualizationResultWithTerrain.height * cellSize;
        const titleLines = 2;
        final legendLines = titleLines + 1 + TerrainType.values.length;
        expect(decoded.width, mapW);
        expect(decoded.height, mapH + legendHeightForLineCount(legendLines));
      },
    );

    test('sea cell color: center pixel of sea cell is deep blue', () {
      const cellSize = 24;
      final decoded = decodeRenderTileMapToPng(
        visualizationResultWithTerrain,
        visualizationTopology,
        cellSize: cellSize,
      );
      final (x, y) = cellCenterPixel(1, 1, cellSize);
      expectPixelNearRgb(decoded, x, y, visualizationSeaRgb);
    });

    test('land terrain color: center pixel of plains cell matches palette', () {
      const cellSize = 8;
      final decoded = decodeRenderTileMapToPng(
        visualizationResultWithTerrain,
        visualizationTopology,
        cellSize: cellSize,
      );
      final (x, y) = cellCenterPixel(0, 0, cellSize);
      expectPixelNearRgb(decoded, x, y, visualizationPlainsRgb);
    });

    test('border pixel is black between different region ids (land border)', () {
      const cellSize = 8;
      final decoded = decodeRenderTileMapToPng(
        visualizationResultWithTerrain,
        visualizationTopology,
        cellSize: cellSize,
      );
      final pixel = decoded.getPixel(2 * cellSize, cellSize ~/ 2);
      expect(pixel.r, lessThanOrEqualTo(5));
      expect(pixel.g, lessThanOrEqualTo(5));
      expect(pixel.b, lessThanOrEqualTo(5));
    });

    test('sea zone border is light blue when two sea zones are adjacent', () {
      const cellSize = 8;
      final decoded = decodeRenderTileMapToPng(
        mapTileGrid([['s1', 's2']]),
        twoAdjacentSeaZonesTopology('oldWorld'),
        cellSize: cellSize,
      );
      expectPixelNearRgb(
        decoded,
        cellSize,
        cellSize ~/ 2,
        visualizationSeaZoneBorderRgb,
      );
    });

    test(
      'legend height with terrain: total height = map + terrain legend lines',
      () {
        const cellSize = 8;
        final decoded = decodeRenderTileMapToPng(
          visualizationResultWithTerrain,
          visualizationTopology,
          cellSize: cellSize,
        );
        final mapH = visualizationResultWithTerrain.height * cellSize;
        final legendLines = 2 + 1 + TerrainType.values.length;
        expect(decoded.height, mapH + legendHeightForLineCount(legendLines));
      },
    );

    test('fallback no terrain: valid PNG, region dimensions, no throw', () {
      final decoded = decodeRenderTileMapToPng(
        visualizationSmallResult,
        visualizationTopology,
        cellSize: 8,
      );
      expect(decoded.width, 32);
      expect(decoded.height, greaterThanOrEqualTo(24));
    });

    test(
      'resourceIdToLegendLetter covers all Resource values with unique single letters',
      () {
        final letters = <String>{};
        for (final r in Resource.values) {
          final letter = resourceIdToLegendLetter(r.name);
          expect(letter, isNotNull, reason: 'Resource $r should have a legend letter');
          expect(letter!.length, 1, reason: 'Letter for $r should be single character');
          expect(letters.contains(letter), isFalse, reason: 'Duplicate letter $letter for $r');
          letters.add(letter);
        }
      },
    );

    test('region id label is drawn in red at top-left of each cell', () {
      const cellSize = 8;
      const idInset = 2;
      final decoded = decodeRenderTileMapToPng(
        visualizationSmallResult,
        visualizationTopology,
        cellSize: cellSize,
      );
      var foundRed = false;
      for (var py = idInset; py < idInset + 14 && !foundRed; py++) {
        for (var px = idInset; px < idInset + 16 && !foundRed; px++) {
          final pixel = decoded.getPixel(px, py);
          if (pixel.r >= 200 && pixel.g <= 30 && pixel.b <= 30) foundRed = true;
        }
      }
      expect(
        foundRed,
        isTrue,
        reason: 'Region id label (red) should appear in top-left of first cell',
      );
    });
  });
}
