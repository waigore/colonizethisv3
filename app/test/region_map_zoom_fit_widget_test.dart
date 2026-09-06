import 'package:colonizethis_app/features/game/flame/caches/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map_viewport_snapshot.dart';
import 'package:colonizethis_app/features/game/flame/caches/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/caches/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/tilesets/tilesets.dart';
import 'package:colonizethis_app/features/game/flame/caches/town_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/widgets/ct_region_map.dart' show CtRegionMap;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_region_map_test_support.dart';
import 'region_map_zoom_fit_support.dart';

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    await terrainTilesetCache.load();
    await transportOverlayTilesetCache.load();
    await resourceIconCache.load();
    await civilianIconCache.load();
    await townIconCache.load();
    await provinceLabelIconCache.load();
  });

  testWidgets(
    'CtRegionMap starts at fit baseline (m=1) and bus zoom clamps to band',
    (WidgetTester tester) async {
      final region = ctRegionMapTestOldWorldRegion();
      final bus = AppEventBus.create();
      RegionMapViewportSnapshot? snap;

      await tester.pumpWidget(
        ctRegionMapTestHarness(
          region: region,
          cellSizePx: region.cellSize.toDouble(),
          visibilityMode: CtMapVisibilityMode.full,
          bus: bus,
          onViewportSnapshotChanged: (s) => snap = s,
        ),
      );

      await pumpUntilCtRegionMapFitBaseline(tester, () => snap);

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
          zoomMultiplier: 8.0,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(snap!.zoomMultiplier, closeTo(kRegionMapZoomMultiplierMax, 0.06));

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
          zoomMultiplier: 8.0,
        ),
      );
      await tester.pump();
      final zoomAfterWrongRegion = snap!.zoomMultiplier;
      expect(zoomAfterWrongRegion, closeTo(0.5, 0.06));

      bus.dispose();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );

  testWidgets(
    'CtRegionMap pinch zoom matches slider/bus absolute multiplier (same zoom)',
    (WidgetTester tester) async {
      final region = ctRegionMapTestOldWorldRegion();
      final bus = AppEventBus.create();
      RegionMapViewportSnapshot? snap;

      await tester.pumpWidget(
        ctRegionMapTestHarness(
          region: region,
          cellSizePx: region.cellSize.toDouble(),
          visibilityMode: CtMapVisibilityMode.full,
          bus: bus,
          onViewportSnapshotChanged: (s) => snap = s,
        ),
      );

      await pumpUntilCtRegionMapFitBaseline(tester, () => snap);
      final zFit = snap!.fitMapZoom;

      final center = tester.getCenter(find.byType(CtRegionMap));

      await pinchZoomOutOnCenter(tester, center);
      await tester.pump(const Duration(milliseconds: 80));

      if (snap!.zoomMultiplier <= 1.03) {
        await pinchZoomOutOnCenter(tester, center);
        await tester.pump(const Duration(milliseconds: 80));
      }

      expect(
        snap!.zoomMultiplier,
        greaterThan(1.03),
        reason:
            'pinch-out should increase fit-relative zoom like zoom-in slider drag',
      );
      expect(
        snap!.zoomMultiplier,
        lessThanOrEqualTo(kRegionMapZoomMultiplierMax),
      );
      final mAfterPinch = snap!.zoomMultiplier;
      final zAfterPinch = snap!.zoom;

      bus.emit(
        RequestRegionMapSetZoomMultiplierEvent(
          regionId: region.regionId,
          zoomMultiplier: 1.0,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(snap!.zoomMultiplier, closeTo(1.0, 0.08));

      bus.emit(
        RequestRegionMapSetZoomMultiplierEvent(
          regionId: region.regionId,
          zoomMultiplier: mAfterPinch,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));

      expect(snap!.zoomMultiplier, closeTo(mAfterPinch, 0.08));
      expect(snap!.zoom, closeTo(zAfterPinch, zFit * 0.04));

      bus.dispose();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
}
