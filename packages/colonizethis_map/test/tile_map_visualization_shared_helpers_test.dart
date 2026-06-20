import 'package:image/image.dart' as img;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_map/src/render/tile_map_visualization_shared.dart';

void main() {
  group('seaZoneLocalIdsFromRegionCells', () {
    test('empty list yields empty set', () {
      expect(seaZoneLocalIdsFromRegionCells([]), isEmpty);
    });

    test('collects unique sea zone local ids', () {
      final cells = <CellViewData>[
        const CellViewData(x: 0, y: 0, regionCellId: 'p1', isSea: false),
        const CellViewData(x: 1, y: 0, regionCellId: 's1', isSea: true),
        const CellViewData(x: 2, y: 0, regionCellId: 's1', isSea: true),
        const CellViewData(x: 0, y: 1, regionCellId: 's2', isSea: true),
      ];
      expect(seaZoneLocalIdsFromRegionCells(cells), equals({'s1', 's2'}));
    });
  });

  group('fillCellRect', () {
    test('fills exactly the cellSize block for the target cell', () {
      final image = img.Image(width: 12, height: 12);
      image.clear(image.getColor(0, 0, 0));
      fillCellRect(
        image,
        cellX: 1,
        cellY: 1,
        cellSize: 4,
        color: image.getColor(10, 20, 30),
      );
      // Inside the block (x:4..7, y:4..7) is filled.
      final inside = image.getPixel(5, 6);
      expect(inside.r.toInt(), 10);
      expect(inside.g.toInt(), 20);
      expect(inside.b.toInt(), 30);
      // Block edges inclusive: (4,4) and (7,7) filled.
      expect(image.getPixel(4, 4).r.toInt(), 10);
      expect(image.getPixel(7, 7).b.toInt(), 30);
    });

    test('does not paint neighbouring cells (negative/edge)', () {
      final image = img.Image(width: 12, height: 12);
      image.clear(image.getColor(0, 0, 0));
      fillCellRect(
        image,
        cellX: 1,
        cellY: 1,
        cellSize: 4,
        color: image.getColor(10, 20, 30),
      );
      // One pixel past the block on each axis stays background black.
      final pastX = image.getPixel(8, 5);
      expect(pastX.r.toInt(), 0);
      expect(pastX.g.toInt(), 0);
      final pastY = image.getPixel(5, 8);
      expect(pastY.b.toInt(), 0);
      // Cell origin (0,0) untouched.
      expect(image.getPixel(0, 0).r.toInt(), 0);
    });
  });

  group('fillTileGridCells', () {
    test('fills every cell using the colorAt strategy', () {
      final image = img.Image(width: 6, height: 6);
      image.clear(image.getColor(0, 0, 0));
      fillTileGridCells(
        image,
        height: 3,
        width: 3,
        cellSize: 2,
        // Encode the coordinate in the colour to assert per-cell strategy.
        colorAt: (x, y) => (x * 10, y * 10, 5),
      );
      // Cell (2,1): block x:4..5, y:2..3.
      final c21 = image.getPixel(4, 2);
      expect(c21.r.toInt(), 20);
      expect(c21.g.toInt(), 10);
      expect(c21.b.toInt(), 5);
    });

    test('matches a hand-rolled nested fill loop byte-for-byte (parity)', () {
      (int, int, int) colorAt(int x, int y) => ((x + y) * 7 % 256, x, y);
      const cellSize = 3;
      const height = 4;
      const width = 5;

      final viaHelper = img.Image(
        width: width * cellSize,
        height: height * cellSize,
      );
      viaHelper.clear(viaHelper.getColor(255, 255, 255));
      fillTileGridCells(
        viaHelper,
        height: height,
        width: width,
        cellSize: cellSize,
        colorAt: colorAt,
      );

      final manual = img.Image(
        width: width * cellSize,
        height: height * cellSize,
      );
      manual.clear(manual.getColor(255, 255, 255));
      for (var y = 0; y < height; y++) {
        for (var x = 0; x < width; x++) {
          final (r, g, b) = colorAt(x, y);
          img.fillRect(
            manual,
            x1: x * cellSize,
            y1: y * cellSize,
            x2: (x + 1) * cellSize - 1,
            y2: (y + 1) * cellSize - 1,
            color: manual.getColor(r, g, b),
          );
        }
      }

      expect(img.encodePng(viaHelper), equals(img.encodePng(manual)));
    });
  });

  group('fillRegionViewCells', () {
    test('fills each listed cell at its (x, y) via the strategy', () {
      final image = img.Image(width: 6, height: 6);
      image.clear(image.getColor(0, 0, 0));
      const cells = <CellViewData>[
        CellViewData(x: 0, y: 0, regionCellId: 'p1', isSea: false),
        CellViewData(x: 2, y: 1, regionCellId: 's1', isSea: true),
      ];
      fillRegionViewCells(
        image,
        cells: cells,
        cellSize: 2,
        colorAt: (cell) => cell.isSea ? (0, 0, 200) : (200, 0, 0),
      );
      // Land cell (0,0): block x:0..1, y:0..1.
      expect(image.getPixel(0, 0).r.toInt(), 200);
      // Sea cell (2,1): block x:4..5, y:2..3.
      expect(image.getPixel(4, 2).b.toInt(), 200);
      // An unlisted cell stays background.
      expect(image.getPixel(2, 4).r.toInt(), 0);
    });
  });

  group('drawResourceLegendRows', () {
    test(
      'advances by one legend line height per resource (tile-map columns)',
      () {
        final image = img.Image(width: 320, height: 120);
        final black = image.getColor(0, 0, 0);
        const y0 = 10;
        final yEnd = drawResourceLegendRows(
          image,
          legendY: y0,
          textColor: black,
          resources: const [Resource.grain, Resource.iron],
          style: ResourceLegendRowsStyle.tileMapColumns,
        );
        expect(yEnd, y0 + 2 * legendLineHeight);
      },
    );

    test('advances similarly for compactInline style', () {
      final image = img.Image(width: 320, height: 120);
      final black = image.getColor(0, 0, 0);
      const y0 = 4;
      final yEnd = drawResourceLegendRows(
        image,
        legendY: y0,
        textColor: black,
        resources: geographicGameWorldLegendResources,
        style: ResourceLegendRowsStyle.compactInline,
      );
      expect(
        yEnd,
        y0 + geographicGameWorldLegendResources.length * legendLineHeight,
      );
    });
  });
}
