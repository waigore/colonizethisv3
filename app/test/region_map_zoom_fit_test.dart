import 'package:colonizethis_app/features/game/flame/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map_viewport_snapshot.dart';
import 'package:colonizethis_app/features/game/flame/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/terrain_tileset.dart';
import 'package:colonizethis_app/features/game/flame/town_icon_cache.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart'
    show CtMapVisibilityMode, CtRegionMap;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_region_map_test_support.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await terrainTilesetCache.load();
    await resourceIconCache.load();
    await townIconCache.load();
    await provinceLabelIconCache.load();
  });

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

  testWidgets(
    'CtRegionMap starts at fit baseline (m=1) and bus zoom clamps to band',
    (WidgetTester tester) async {
      final region = ctRegionMapTestOldWorldRegion();
      final bus = AppEventBus.create();
      RegionMapViewportSnapshot? snap;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 400,
                height: 320,
                child: CtRegionMap(
                  region: region,
                  cellSizePx: region.cellSize.toDouble(),
                  visibilityMode: CtMapVisibilityMode.full,
                  bus: bus,
                  onViewportSnapshotChanged: (s) => snap = s,
                ),
              ),
            ),
          ),
      ),
    );
    await tester.pump();
    // Flame/map may run continuous animations; avoid pumpAndSettle (never idles).
    for (var i = 0; i < 40; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(snap, isNotNull);
      final mw = region.width * region.cellSize.toDouble();
      final mh = region.height * region.cellSize.toDouble();
      final zFit = computeRegionMapFitMapZoom(
        viewportWidthLogical: 400,
        viewportHeightLogical: 320,
        mapWidthWorld: mw,
        mapHeightWorld: mh,
      );
      expect(snap!.fitMapZoom, closeTo(zFit, 0.02));
      expect(snap!.zoom, closeTo(zFit, 0.02));
      expect(snap!.zoomMultiplier, closeTo(1.0, 0.02));

      bus.emit(
        RequestRegionMapSetZoomMultiplierEvent(
          regionId: region.regionId,
          zoomMultiplier: 4.0,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(snap!.zoomMultiplier, closeTo(4.0, 0.06));

      bus.emit(
        RequestRegionMapSetZoomMultiplierEvent(
          regionId: region.regionId,
          zoomMultiplier: 0.1,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      expect(snap!.zoomMultiplier, closeTo(0.5, 0.06));

      bus.emit(
        const RequestRegionMapSetZoomMultiplierEvent(
          regionId: 'newWorld',
          zoomMultiplier: 4.0,
        ),
      );
      await tester.pump();
      final zoomAfterWrongRegion = snap!.zoomMultiplier;
      expect(zoomAfterWrongRegion, closeTo(0.5, 0.06));

      bus.dispose();
    },
    timeout: const Timeout(Duration(seconds: 30)),
  );
}
