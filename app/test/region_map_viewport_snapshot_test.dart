import 'package:colonizethis_app/features/game/flame/region_map/region_map_viewport_snapshot.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('RegionMapViewportSnapshot.matches', () {
    RegionMapViewportSnapshot base({
      double zoom = 2.0,
      double fitMapZoom = 1.0,
    }) {
      return RegionMapViewportSnapshot(
        regionId: 'r1',
        cellSizePx: 24,
        mapWidthWorld: 96,
        mapHeightWorld: 96,
        cameraCenterX: 48,
        cameraCenterY: 48,
        zoom: zoom,
        fitMapZoom: fitMapZoom,
        viewportWidthLogical: 400,
        viewportHeightLogical: 400,
      );
    }

    test('identical logical state matches', () {
      final a = base();
      final b = base();
      expect(a.matches(b), isTrue);
    });

    test('small zoom delta does not match (minimap slider steps must apply)', () {
      final a = base(zoom: 10.0);
      final b = base(zoom: 10.3);
      expect(a.matches(b), isFalse);
    });

    test('small fitMapZoom delta does not match', () {
      final a = base(fitMapZoom: 0.5);
      final b = base(fitMapZoom: 0.50002);
      expect(a.matches(b), isFalse);
    });

    test('sub-epsilon zoom noise still matches', () {
      final a = base(zoom: 2.0);
      final b = base(zoom: 2.0 + 1e-7);
      expect(a.matches(b), isTrue);
    });
  });
}
