import 'dart:io';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:image/image.dart' as img;

/// Sea color and plains color from tile_map_visualization (for pixel assertions).
const (int, int, int) _seaRgb = (20, 60, 140);
const (int, int, int) _plainsRgb = (200, 220, 160);
const (int, int, int) _seaZoneBorderRgb = (173, 216, 230);
const int _colorTolerance = 2;

void main() {
  final topology = MapTopology(
    nodes: [
      const TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      const TopologyNode(
        id: 'p2',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      const TopologyNode(
        id: 's1',
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [
      const TopologyEdge(id1: 'p1', id2: 'p2'),
      const TopologyEdge(id1: 'p1', id2: 's1'),
    ],
  );

  final smallResult = TileMapResult(
    width: 4,
    height: 3,
    grid: [
      ['p1', 'p1', 'p2', 'p2'],
      ['p1', 's1', 's1', 'p2'],
      ['p1', 'p1', 'p2', 'p2'],
    ],
  );

  /// Result with terrain: p1/p2 land, s1 sea; at least one horizontal and one vertical border.
  final resultWithTerrain = TileMapResult(
    width: 4,
    height: 3,
    grid: [
      ['p1', 'p1', 'p2', 'p2'],
      ['p1', 's1', 's1', 'p2'],
      ['p1', 'p1', 'p2', 'p2'],
    ],
    terrainGrid: [
      [
        TerrainType.plains,
        TerrainType.plains,
        TerrainType.hills,
        TerrainType.hills,
      ],
      [TerrainType.plains, null, null, TerrainType.hills],
      [
        TerrainType.plains,
        TerrainType.plains,
        TerrainType.hills,
        TerrainType.hills,
      ],
    ],
  );

  /// Like resultWithTerrain with resourceGrid: (0,0)=grain, (2,0)=timber, (0,2)=iron; others null.
  final resultWithTerrainAndResources = TileMapResult(
    width: 4,
    height: 3,
    grid: resultWithTerrain.grid,
    terrainGrid: resultWithTerrain.terrainGrid,
    resourceGrid: [
      [Resource.grain, null, Resource.timber, null],
      [null, null, null, null],
      [Resource.iron, null, null, null],
    ],
  );

  group('renderTileMapToPng', () {
    test('returns non-empty PNG bytes', () {
      final bytes = renderTileMapToPng(smallResult, topology, cellSize: 4);
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(100));
    });

    test('decoded image has expected dimensions (map + legend)', () {
      final bytes = renderTileMapToPng(smallResult, topology, cellSize: 8);
      final decoded = img.decodeImage(bytes);
      expect(decoded, isNotNull);
      // Map: 4*8 x 3*8 = 32 x 24. Legend below.
      expect(decoded!.width, 32);
      expect(decoded.height, greaterThanOrEqualTo(24));
    });

    test(
      'dimensions with terrain: width and height match map + terrain legend',
      () {
        const cellSize = 8;
        final bytes = renderTileMapToPng(
          resultWithTerrain,
          topology,
          cellSize: cellSize,
        );
        final decoded = img.decodeImage(bytes);
        expect(decoded, isNotNull);
        final mapW = resultWithTerrain.width * cellSize;
        final mapH = resultWithTerrain.height * cellSize;
        const legendPadding = 12;
        const legendLineHeight = 20;
        const titleLines = 2;
        final legendLines = titleLines + 1 + TerrainType.values.length;
        final legendHeight = legendPadding * 2 + legendLines * legendLineHeight;
        expect(decoded!.width, mapW);
        expect(decoded.height, mapH + legendHeight);
      },
    );

    test('sea cell color: center pixel of sea cell is deep blue', () {
      // Use cellSize 24 so region id label (top-left) does not overlap cell center.
      const cellSize = 24;
      final bytes = renderTileMapToPng(
        resultWithTerrain,
        topology,
        cellSize: cellSize,
      );
      final decoded = img.decodeImage(bytes);
      expect(decoded, isNotNull);
      // (1, 1) is s1 (sea). Center of cell: (1*24+12, 1*24+12) = (36, 36).
      final x = 1 * cellSize + cellSize ~/ 2;
      final y = 1 * cellSize + cellSize ~/ 2;
      final pixel = decoded!.getPixel(x, y);
      expect((pixel.r - _seaRgb.$1).abs(), lessThanOrEqualTo(_colorTolerance));
      expect((pixel.g - _seaRgb.$2).abs(), lessThanOrEqualTo(_colorTolerance));
      expect((pixel.b - _seaRgb.$3).abs(), lessThanOrEqualTo(_colorTolerance));
    });

    test('land terrain color: center pixel of plains cell matches palette', () {
      const cellSize = 8;
      final bytes = renderTileMapToPng(
        resultWithTerrain,
        topology,
        cellSize: cellSize,
      );
      final decoded = img.decodeImage(bytes);
      expect(decoded, isNotNull);
      // (0, 0) is p1 with plains. Center: (4, 4).
      final x = 0 * cellSize + cellSize ~/ 2;
      final y = 0 * cellSize + cellSize ~/ 2;
      final pixel = decoded!.getPixel(x, y);
      expect(
        (pixel.r - _plainsRgb.$1).abs(),
        lessThanOrEqualTo(_colorTolerance),
      );
      expect(
        (pixel.g - _plainsRgb.$2).abs(),
        lessThanOrEqualTo(_colorTolerance),
      );
      expect(
        (pixel.b - _plainsRgb.$3).abs(),
        lessThanOrEqualTo(_colorTolerance),
      );
    });

    test('border pixel is black between different region ids (land border)', () {
      const cellSize = 8;
      final bytes = renderTileMapToPng(
        resultWithTerrain,
        topology,
        cellSize: cellSize,
      );
      final decoded = img.decodeImage(bytes);
      expect(decoded, isNotNull);
      // Vertical border between (1,0) p1 and (2,0) p2: right edge of (1,0) at x = 2*8 = 16.
      final edgeX = 2 * cellSize;
      final sampleY = cellSize ~/ 2;
      final pixel = decoded!.getPixel(edgeX, sampleY);
      expect(pixel.r, lessThanOrEqualTo(5));
      expect(pixel.g, lessThanOrEqualTo(5));
      expect(pixel.b, lessThanOrEqualTo(5));
    });

    test('sea zone border is light blue when two sea zones are adjacent', () {
      const cellSize = 8;
      final topologyWithTwoSeas = MapTopology(
        nodes: [
          const TopologyNode(
            id: 's1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          const TopologyNode(
            id: 's2',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [const TopologyEdge(id1: 's1', id2: 's2')],
      );
      final resultWithTwoSeas = TileMapResult(
        width: 2,
        height: 1,
        grid: [
          ['s1', 's2'],
        ],
      );
      final bytes = renderTileMapToPng(
        resultWithTwoSeas,
        topologyWithTwoSeas,
        cellSize: cellSize,
      );
      final decoded = img.decodeImage(bytes);
      expect(decoded, isNotNull);
      // Vertical border between s1 and s2 at x = 1*8 = 8.
      final edgeX = 1 * cellSize;
      final sampleY = cellSize ~/ 2;
      final pixel = decoded!.getPixel(edgeX, sampleY);
      expect(
        (pixel.r - _seaZoneBorderRgb.$1).abs(),
        lessThanOrEqualTo(_colorTolerance),
      );
      expect(
        (pixel.g - _seaZoneBorderRgb.$2).abs(),
        lessThanOrEqualTo(_colorTolerance),
      );
      expect(
        (pixel.b - _seaZoneBorderRgb.$3).abs(),
        lessThanOrEqualTo(_colorTolerance),
      );
    });

    test(
      'legend height with terrain: total height = map + terrain legend lines',
      () {
        const cellSize = 8;
        final bytes = renderTileMapToPng(
          resultWithTerrain,
          topology,
          cellSize: cellSize,
        );
        final decoded = img.decodeImage(bytes);
        expect(decoded, isNotNull);
        final mapH = resultWithTerrain.height * cellSize;
        const legendPadding = 12;
        const legendLineHeight = 20;
        final legendLines = 2 + 1 + TerrainType.values.length;
        final legendHeight = legendPadding * 2 + legendLines * legendLineHeight;
        expect(decoded!.height, mapH + legendHeight);
      },
    );

    test('fallback no terrain: valid PNG, region dimensions, no throw', () {
      final bytes = renderTileMapToPng(smallResult, topology, cellSize: 8);
      expect(bytes, isNotEmpty);
      final decoded = img.decodeImage(bytes);
      expect(decoded, isNotNull);
      expect(decoded!.width, 32);
      expect(decoded.height, greaterThanOrEqualTo(24));
    });

    test(
      'with landSeedPositions only (no continent indices): single Land seeds legend row',
      () {
        const cellSize = 8;
        final bytes = renderTileMapToPng(
          smallResult,
          topology,
          cellSize: cellSize,
          landSeedPositions: [(0, 0), (1, 1)],
        );
        final decoded = img.decodeImage(bytes);
        expect(decoded, isNotNull);
        expect(
          decoded!.height,
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
          smallResult,
          topology,
          cellSize: cellSize,
        );
        final bytesWith = renderTileMapToPng(
          smallResult,
          topology,
          cellSize: cellSize,
          landSeedPositions: [(0, 0), (1, 1)],
        );
        final decodedWith = img.decodeImage(bytesWith);
        expect(decodedWith, isNotNull);
        expect(
          decodedWith!.height,
          greaterThan(img.decodeImage(bytesWithout)!.height),
          reason: 'Extra legend row when land seeds shown',
        );
        final cx = 0 * cellSize + cellSize ~/ 2;
        final cy = 0 * cellSize + cellSize ~/ 2;
        final pixel = decodedWith.getPixel(cx, cy);
        expect(
          (pixel.r - landSeedMarkerRgb.$1).abs(),
          lessThanOrEqualTo(_colorTolerance),
        );
        expect(
          (pixel.g - landSeedMarkerRgb.$2).abs(),
          lessThanOrEqualTo(_colorTolerance),
        );
        expect(
          (pixel.b - landSeedMarkerRgb.$3).abs(),
          lessThanOrEqualTo(_colorTolerance),
        );
      },
    );

    test(
      'with continentSeedPositions only: extra legend row for continent seeds',
      () {
        const cellSize = 8;
        final bytesWithContinent = renderTileMapToPng(
          resultWithTerrain,
          topology,
          cellSize: cellSize,
          continentSeedPositions: [(0, 0)],
        );
        final bytesWithout = renderTileMapToPng(
          resultWithTerrain,
          topology,
          cellSize: cellSize,
        );
        final decodedWith = img.decodeImage(bytesWithContinent);
        final decodedWithout = img.decodeImage(bytesWithout);
        expect(decodedWith, isNotNull);
        expect(decodedWithout, isNotNull);
        expect(
          decodedWith!.height,
          greaterThan(decodedWithout!.height),
          reason: 'Continent seeds add a legend row',
        );
      },
    );

    test(
      'with continentSeedPositions and landSeedPositions: two legend rows and distinct markers',
      () {
        const cellSize = 8;
        final bytesWithBoth = renderTileMapToPng(
          resultWithTerrain,
          topology,
          cellSize: cellSize,
          landSeedPositions: [(2, 2)],
          continentSeedPositions: [(0, 0)],
        );
        final decoded = img.decodeImage(bytesWithBoth);
        expect(decoded, isNotNull);
        final bytesLandOnly = renderTileMapToPng(
          resultWithTerrain,
          topology,
          cellSize: cellSize,
          landSeedPositions: [(2, 2)],
        );
        expect(
          decoded!.height,
          greaterThan(img.decodeImage(bytesLandOnly)!.height),
          reason: 'Extra legend row when continent seeds also shown',
        );
        final continentCx = 0 * cellSize + cellSize ~/ 2;
        final continentCy = 0 * cellSize + cellSize ~/ 2;
        final continentPixel = decoded.getPixel(continentCx, continentCy);
        expect(
          (continentPixel.r - continentSeedMarkerRgb.$1).abs(),
          lessThanOrEqualTo(_colorTolerance),
        );
        expect(
          (continentPixel.g - continentSeedMarkerRgb.$2).abs(),
          lessThanOrEqualTo(_colorTolerance),
        );
        expect(
          (continentPixel.b - continentSeedMarkerRgb.$3).abs(),
          lessThanOrEqualTo(_colorTolerance),
        );
      },
    );

    test(
      'with landSeedContinentIndices: markers colored by continent and legend has one row per continent',
      () {
        const cellSize = 24;
        final bytes = renderTileMapToPng(
          resultWithTerrain,
          topology,
          cellSize: cellSize,
          landSeedPositions: [(0, 0), (2, 2)],
          landSeedContinentIndices: [0, 1],
        );
        final decoded = img.decodeImage(bytes);
        expect(decoded, isNotNull);
        // Region id labels are drawn on top of seeds, so we do not assert exact marker pixel colors.
        // Assert that per-continent legend adds two rows (Continent 0, Continent 1).
        final bytesSingleRow = renderTileMapToPng(
          resultWithTerrain,
          topology,
          cellSize: cellSize,
          landSeedPositions: [(0, 0), (2, 2)],
        );
        expect(
          decoded!.height,
          greaterThan(img.decodeImage(bytesSingleRow)!.height),
          reason:
              'Per-continent legend adds two rows (Continent 0, Continent 1)',
        );
      },
    );

    test(
      'with resourceGrid: image height larger and legend includes resource rows',
      () {
        const cellSize = 8;
        final bytesWithout = renderTileMapToPng(
          resultWithTerrain,
          topology,
          cellSize: cellSize,
        );
        final bytesWith = renderTileMapToPng(
          resultWithTerrainAndResources,
          topology,
          cellSize: cellSize,
        );
        final decodedWithout = img.decodeImage(bytesWithout);
        final decodedWith = img.decodeImage(bytesWith);
        expect(decodedWithout, isNotNull);
        expect(decodedWith, isNotNull);
        expect(
          decodedWith!.height,
          greaterThan(decodedWithout!.height),
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
          expect(
            letter,
            isNotNull,
            reason: 'Resource $r should have a legend letter',
          );
          expect(
            letter!.length,
            1,
            reason: 'Letter for $r should be single character',
          );
          expect(
            letters.contains(letter),
            isFalse,
            reason: 'Duplicate letter $letter for $r',
          );
          letters.add(letter);
        }
      },
    );

    test('region id label is drawn in red at top-left of each cell', () {
      const cellSize = 8;
      const idInset = 2;
      final bytes = renderTileMapToPng(
        smallResult,
        topology,
        cellSize: cellSize,
      );
      final decoded = img.decodeImage(bytes);
      expect(decoded, isNotNull);
      // Region id "p1" is drawn at (0,0) cell: tx=0*cellSize+idInset=2, ty=2. Sample in label area.
      var foundRed = false;
      for (var py = idInset; py < idInset + 14 && !foundRed; py++) {
        for (var px = idInset; px < idInset + 16 && !foundRed; px++) {
          final pixel = decoded!.getPixel(px, py);
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

  group('writeTileMapImageToTempFile', () {
    test('returns path and file exists with content', () {
      final path = writeTileMapImageToTempFile(smallResult, topology);
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
      final path = writeTileMapImageToTempFile(smallResult, topology);
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
