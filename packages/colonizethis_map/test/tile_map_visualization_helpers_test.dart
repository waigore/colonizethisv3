import 'dart:io';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';

import 'tile_map_visualization_test_fixtures.dart';

void main() {
  group('writeTileMapImageToTempFile', () {
    test('returns path and file exists with content', () {
      final path = writeTileMapImageToTempFile(
        visualizationSmallResult,
        visualizationTopology,
      );
      expect(path, isNotEmpty);
      final file = File(path);
      expect(file.existsSync(), isTrue);
      expect(file.lengthSync(), greaterThan(100));
    });
  });

  group('geographicGameWorldResourceGlyphLetter', () {
    test('returns letters only for grain, timber, iron resource ids', () {
      expect(geographicGameWorldResourceGlyphLetter('grain'), 'g');
      expect(geographicGameWorldResourceGlyphLetter('timber'), 't');
      expect(geographicGameWorldResourceGlyphLetter('iron'), 'i');
    });

    test(
      'returns null for ids outside geographic subset, empty, or invalid',
      () {
        expect(geographicGameWorldResourceGlyphLetter('gold'), isNull);
        expect(geographicGameWorldResourceGlyphLetter('notAResource'), isNull);
        expect(geographicGameWorldResourceGlyphLetter(null), isNull);
        expect(geographicGameWorldResourceGlyphLetter(''), isNull);
      },
    );
  });

  group('geographicGameWorldLegendResources', () {
    test('is grain, timber, iron per SPEC geographic legend scope', () {
      expect(geographicGameWorldLegendResources, const [
        Resource.grain,
        Resource.timber,
        Resource.iron,
      ]);
    });
  });

  group('resource glyph helper iterables', () {
    test('tileMapResourceGlyphs yields only non-null resources', () {
      final result = TileMapResult(
        width: 2,
        height: 2,
        grid: [
          ['p1', 'p1'],
          ['p1', 'p1'],
        ],
        resourceGrid: [
          [Resource.grain, null],
          [Resource.iron, null],
        ],
      );
      final glyphs = tileMapResourceGlyphs(result).toList();
      expect(glyphs, hasLength(2));
      expect(glyphs[0], (x: 0, y: 0, letter: 'g'));
      expect(glyphs[1], (x: 0, y: 1, letter: 'i'));
    });

    test(
      'geographicGameWorldResourceGlyphs yields only subset resource ids',
      () {
        final cells = [
          const CellViewData(
            x: 0,
            y: 0,
            regionCellId: 'p1',
            isSea: false,
            resourceId: 'grain',
          ),
          const CellViewData(
            x: 1,
            y: 0,
            regionCellId: 'p1',
            isSea: false,
            resourceId: 'gold',
          ),
          const CellViewData(
            x: 0,
            y: 1,
            regionCellId: 'p1',
            isSea: false,
            resourceId: null,
          ),
        ];
        final glyphs = geographicGameWorldResourceGlyphs(cells).toList();
        expect(glyphs, hasLength(1));
        expect(glyphs.single, (x: 0, y: 0, letter: 'g'));
      },
    );
  });

  group('openInDefaultViewer', () {
    test('does not throw; returns bool', () {
      final path = writeTileMapImageToTempFile(
        visualizationSmallResult,
        visualizationTopology,
      );
      final result = openInDefaultViewer(path);
      expect(result, isA<bool>());
    });

    test('returns false when SUPPRESS_IMAGE_VIEWER is 1', () {
      if (Platform.environment['SUPPRESS_IMAGE_VIEWER'] == '1') {
        expect(openInDefaultViewer('dummy_path'), isFalse);
      }
    });
  });
}
