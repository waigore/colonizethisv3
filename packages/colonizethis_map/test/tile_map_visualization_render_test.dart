import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

import 'support/init_game_map_view_fixtures.dart';
import 'package:colonizethis_map/src/render/tile_map_visualization_legend_layout.dart'
    show legendHeightForLineCount;
import 'tile_map_visualization_test_fixtures.dart';

void main() {
  group('renderTileMapToPng', () {
    test('returns non-empty PNG bytes', () {
      final bytes = renderTileMapToPng(
        visualizationSmallResult,
        visualizationTopology,
        cellSize: 4,
      );
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('decoded image has expected dimensions (map + legend)', () {
      const cellSize = 8;
      final decoded = decodeRenderedPng(
        renderTileMapToPng(
          visualizationSmallResult,
          visualizationTopology,
          cellSize: cellSize,
        ),
      );
      expect(decoded.width, 32);
      expect(decoded.height, greaterThanOrEqualTo(24));
    });

    test(
      'dimensions with terrain: width and height match map + terrain legend',
      () {
        const cellSize = 8;
        final decoded = decodeRenderedPng(
          renderTileMapToPng(
            visualizationResultWithTerrain,
            visualizationTopology,
            cellSize: cellSize,
          ),
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
      final decoded = decodeRenderedPng(
        renderTileMapToPng(
          visualizationResultWithTerrain,
          visualizationTopology,
          cellSize: cellSize,
        ),
      );
      final (x, y) = cellCenterPixel(1, 1, cellSize);
      expectPixelNearRgb(decoded, x, y, visualizationSeaRgb);
    });

    test('land terrain color: center pixel of plains cell matches palette', () {
      const cellSize = 8;
      final decoded = decodeRenderedPng(
        renderTileMapToPng(
          visualizationResultWithTerrain,
          visualizationTopology,
          cellSize: cellSize,
        ),
      );
      final (x, y) = cellCenterPixel(0, 0, cellSize);
      expectPixelNearRgb(decoded, x, y, visualizationPlainsRgb);
    });

    test('border pixel is black between different region ids (land border)', () {
      const cellSize = 8;
      final decoded = decodeRenderedPng(
        renderTileMapToPng(
          visualizationResultWithTerrain,
          visualizationTopology,
          cellSize: cellSize,
        ),
      );
      final pixel = decoded.getPixel(2 * cellSize, cellSize ~/ 2);
      expect(pixel.r, lessThanOrEqualTo(5));
      expect(pixel.g, lessThanOrEqualTo(5));
      expect(pixel.b, lessThanOrEqualTo(5));
    });

    test('sea zone border is light blue when two sea zones are adjacent', () {
      const cellSize = 8;
      final decoded = decodeRenderedPng(
        renderTileMapToPng(
          mapTileGrid([['s1', 's2']]),
          twoAdjacentSeaZonesTopology('oldWorld'),
          cellSize: cellSize,
        ),
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
        final decoded = decodeRenderedPng(
          renderTileMapToPng(
            visualizationResultWithTerrain,
            visualizationTopology,
            cellSize: cellSize,
          ),
        );
        final mapH = visualizationResultWithTerrain.height * cellSize;
        final legendLines = 2 + 1 + TerrainType.values.length;
        expect(decoded.height, mapH + legendHeightForLineCount(legendLines));
      },
    );

    test('fallback no terrain: valid PNG, region dimensions, no throw', () {
      final decoded = decodeRenderedPng(
        renderTileMapToPng(
          visualizationSmallResult,
          visualizationTopology,
          cellSize: 8,
        ),
      );
      expect(decoded.width, 32);
      expect(decoded.height, greaterThanOrEqualTo(24));
    });

    test(
      'with landSeedPositions only (no continent indices): single Land seeds legend row',
      () {
        const cellSize = 8;
        final decoded = decodeRenderedPng(
          renderTileMapToPng(
            visualizationSmallResult,
            visualizationTopology,
            cellSize: cellSize,
            landSeedPositions: [(0, 0), (1, 1)],
          ),
        );
        expect(
          decoded.height,
          greaterThan(3 * cellSize),
          reason: 'Legend includes land seeds row',
        );
      },
    );

    test(
      'with landSeedPositions: marker at cell center and extra legend row',
      () {
        const cellSize = 8;
        final bytesWithout = renderTileMapToPng(
          visualizationSmallResult,
          visualizationTopology,
          cellSize: cellSize,
        );
        final decodedWith = decodeRenderedPng(
          renderTileMapToPng(
            visualizationSmallResult,
            visualizationTopology,
            cellSize: cellSize,
            landSeedPositions: [(0, 0), (1, 1)],
          ),
        );
        expect(
          decodedWith.height,
          greaterThan(decodeRenderedPng(bytesWithout).height),
          reason: 'Extra legend row when land seeds shown',
        );
        final (cx, cy) = cellCenterPixel(0, 0, cellSize);
        expectPixelNearRgb(decodedWith, cx, cy, landSeedMarkerRgb);
      },
    );

    test(
      'with continentSeedPositions only: extra legend row for continent seeds',
      () {
        const cellSize = 8;
        final decodedWith = decodeRenderedPng(
          renderTileMapToPng(
            visualizationResultWithTerrain,
            visualizationTopology,
            cellSize: cellSize,
            continentSeedPositions: [(0, 0)],
          ),
        );
        final decodedWithout = decodeRenderedPng(
          renderTileMapToPng(
            visualizationResultWithTerrain,
            visualizationTopology,
            cellSize: cellSize,
          ),
        );
        expect(
          decodedWith.height,
          greaterThan(decodedWithout.height),
          reason: 'Continent seeds add a legend row',
        );
      },
    );

    test(
      'with continentSeedPositions and landSeedPositions: two legend rows and distinct markers',
      () {
        const cellSize = 8;
        final decoded = decodeRenderedPng(
          renderTileMapToPng(
            visualizationResultWithTerrain,
            visualizationTopology,
            cellSize: cellSize,
            landSeedPositions: [(2, 2)],
            continentSeedPositions: [(0, 0)],
          ),
        );
        final bytesLandOnly = renderTileMapToPng(
          visualizationResultWithTerrain,
          visualizationTopology,
          cellSize: cellSize,
          landSeedPositions: [(2, 2)],
        );
        expect(
          decoded.height,
          greaterThan(decodeRenderedPng(bytesLandOnly).height),
          reason: 'Extra legend row when continent seeds also shown',
        );
        final (cx, cy) = cellCenterPixel(0, 0, cellSize);
        expectPixelNearRgb(decoded, cx, cy, continentSeedMarkerRgb);
      },
    );

    test(
      'with landSeedContinentIndices: markers colored by continent and legend has one row per continent',
      () {
        const cellSize = 24;
        final decoded = decodeRenderedPng(
          renderTileMapToPng(
            visualizationResultWithTerrain,
            visualizationTopology,
            cellSize: cellSize,
            landSeedPositions: [(0, 0), (2, 2)],
            landSeedContinentIndices: [0, 1],
          ),
        );
        final bytesSingleRow = renderTileMapToPng(
          visualizationResultWithTerrain,
          visualizationTopology,
          cellSize: cellSize,
          landSeedPositions: [(0, 0), (2, 2)],
        );
        expect(
          decoded.height,
          greaterThan(decodeRenderedPng(bytesSingleRow).height),
          reason:
              'Per-continent legend adds two rows (Continent 0, Continent 1)',
        );
      },
    );

    test(
      'with resourceGrid: image height larger and legend includes resource rows',
      () {
        const cellSize = 8;
        final decodedWithout = decodeRenderedPng(
          renderTileMapToPng(
            visualizationResultWithTerrain,
            visualizationTopology,
            cellSize: cellSize,
          ),
        );
        final decodedWith = decodeRenderedPng(
          renderTileMapToPng(
            visualizationResultWithTerrainAndResources,
            visualizationTopology,
            cellSize: cellSize,
          ),
        );
        expect(
          decodedWith.height,
          greaterThan(decodedWithout.height),
          reason: 'Legend has extra lines for resources',
        );
      },
    );

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
      final decoded = decodeRenderedPng(
        renderTileMapToPng(
          visualizationSmallResult,
          visualizationTopology,
          cellSize: cellSize,
        ),
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
