import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

import 'tile_map_visualization_test_fixtures.dart';

void main() {
  group('renderTileMapToPng seed markers', () {
    test(
      'with landSeedPositions only (no continent indices): single Land seeds legend row',
      () {
        const cellSize = 8;
        final decoded = decodeRenderTileMapToPng(
          visualizationSmallResult,
          visualizationTopology,
          cellSize: cellSize,
          landSeedPositions: [(0, 0), (1, 1)],
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
        final bytesWithout = renderTileMapPngBytes(
          visualizationSmallResult,
          visualizationTopology,
          cellSize: cellSize,
        );
        final decodedWith = decodeRenderTileMapToPng(
          visualizationSmallResult,
          visualizationTopology,
          cellSize: cellSize,
          landSeedPositions: [(0, 0), (1, 1)],
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
        final decodedWith = decodeRenderTileMapToPng(
          visualizationResultWithTerrain,
          visualizationTopology,
          cellSize: cellSize,
          continentSeedPositions: [(0, 0)],
        );
        final decodedWithout = decodeRenderTileMapToPng(
          visualizationResultWithTerrain,
          visualizationTopology,
          cellSize: cellSize,
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
        final decoded = decodeRenderTileMapToPng(
          visualizationResultWithTerrain,
          visualizationTopology,
          cellSize: cellSize,
          landSeedPositions: [(2, 2)],
          continentSeedPositions: [(0, 0)],
        );
        final bytesLandOnly = renderTileMapPngBytes(
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
        final decoded = decodeRenderTileMapToPng(
          visualizationResultWithTerrain,
          visualizationTopology,
          cellSize: cellSize,
          landSeedPositions: [(0, 0), (2, 2)],
          landSeedContinentIndices: [0, 1],
        );
        final bytesSingleRow = renderTileMapPngBytes(
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
        final decodedWithout = decodeRenderTileMapToPng(
          visualizationResultWithTerrain,
          visualizationTopology,
          cellSize: cellSize,
        );
        final decodedWith = decodeRenderTileMapToPng(
          visualizationResultWithTerrainAndResources,
          visualizationTopology,
          cellSize: cellSize,
        );
        expect(
          decodedWith.height,
          greaterThan(decodedWithout.height),
          reason: 'Legend has extra lines for resources',
        );
      },
    );
  });
}
