import 'dart:ui' show Offset, Size;

import 'package:colonizethis_app/features/game/flame/region_map/region_map_viewport_snapshot.dart';
import 'package:colonizethis_app/features/game/flame/region_minimap_math.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('region_minimap_math', () {
    test('minimapLocalToWorldCenter maps corners to world extents', () {
      const mapSize = Size(100, 50);
      const minimap = Size(100, 50);
      expect(
        minimapLocalToWorldCenter(
          localOnMinimap: Offset.zero,
          minimapSize: minimap,
          mapWidthWorld: mapSize.width,
          mapHeightWorld: mapSize.height,
        ),
        Offset.zero,
      );
      expect(
        minimapLocalToWorldCenter(
          localOnMinimap: const Offset(100, 50),
          minimapSize: minimap,
          mapWidthWorld: mapSize.width,
          mapHeightWorld: mapSize.height,
        ),
        const Offset(100, 50),
      );
    });

    test('minimapDeltaToWorldDelta scales by world per minimap pixel', () {
      const minimap = Size(50, 25);
      expect(
        minimapDeltaToWorldDelta(
          minimapDelta: const Offset(5, 5),
          minimapSize: minimap,
          mapWidthWorld: 200,
          mapHeightWorld: 100,
        ),
        const Offset(20, 20),
      );
    });

    test('minimapViewportIndicatorRect centers minimum span when zoomed in', () {
      const viewport = RegionMapViewportSnapshot(
        regionId: 'oldWorld',
        cellSizePx: 24,
        mapWidthWorld: 240,
        mapHeightWorld: 240,
        cameraCenterX: 120,
        cameraCenterY: 120,
        zoom: 16.0,
        fitMapZoom: 200 / 240,
        viewportWidthLogical: 200,
        viewportHeightLogical: 200,
      );
      const minimap = Size(60, 60);
      final r = minimapViewportIndicatorRect(
        viewport: viewport,
        minimapSize: minimap,
        mapWidthWorld: 240,
        mapHeightWorld: 240,
        minMinimapSpan: 10,
      );
      expect(r.width, greaterThanOrEqualTo(10));
      expect(r.height, greaterThanOrEqualTo(10));
    });
  });
}
