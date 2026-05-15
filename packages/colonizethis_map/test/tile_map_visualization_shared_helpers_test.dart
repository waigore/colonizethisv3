import 'package:image/image.dart' as img;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_map/src/tile_map_visualization_shared.dart';

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
