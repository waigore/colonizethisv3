import 'package:colonizethis_app/features/game/flame/region_map/region_map_viewport_snapshot.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'region_map_zoom_fit_support.dart';

void main() {
  suppressLogsForTests();

  group('computeRegionMapFitMapZoom', () {
    test('returns min of viewport-to-map scale (tightest fit axis)', () {
      expect(
        computeRegionMapFitMapZoom(
          viewportWidthLogical: 400,
          viewportHeightLogical: 300,
          mapWidthWorld: 800,
          mapHeightWorld: 200,
        ),
        400 / 800,
      );
    });

    test('returns min of axis ratios for tall viewport', () {
      expect(
        computeRegionMapFitMapZoom(
          viewportWidthLogical: 200,
          viewportHeightLogical: 500,
          mapWidthWorld: 400,
          mapHeightWorld: 400,
        ),
        200 / 400,
      );
    });

    test('returns 1.0 for non-positive inputs', () {
      expect(
        computeRegionMapFitMapZoom(
          viewportWidthLogical: 0,
          viewportHeightLogical: 100,
          mapWidthWorld: 100,
          mapHeightWorld: 100,
        ),
        1.0,
      );
    });
  });
}
