import 'package:colonizethis_app/features/game/flame/province_label_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/region_map_viewport_snapshot.dart';
import 'package:colonizethis_app/features/game/flame/resource_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/civilian_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/terrain_tileset.dart';
import 'package:colonizethis_app/features/game/flame/town_icon_cache.dart';
import 'package:colonizethis_app/features/game/flame/transport_overlay_tileset.dart';
import 'package:colonizethis_app/features/game/flame/region_map_component.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/widgets/ct_region_map.dart' show CtRegionMap;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_region_map_test_support.dart';

/// Max wall time ~9.1s; stops early once the map reports a stable fit baseline
/// (no [pumpAndSettle] — Flame never idles).
///
/// CI shard load can delay first snapshot emission for a few extra seconds.
const int _kCtRegionMapReadyMaxSteps = 240;
const Duration _kCtRegionMapReadyStep = Duration(milliseconds: 38);

bool _snapshotAtFitBaseline(RegionMapViewportSnapshot? s) {
  if (s == null) return false;
  if (!s.fitMapZoom.isFinite || s.fitMapZoom <= 0) return false;
  if (!s.zoom.isFinite || s.zoom <= 0) return false;
  return (s.zoomMultiplier - 1.0).abs() < 0.09;
}

Future<RegionMapViewportSnapshot> pumpUntilCtRegionMapFitBaseline(
  WidgetTester tester,
  RegionMapViewportSnapshot? Function() getSnap,
) async {
  await tester.pump();
  for (var i = 0; i < _kCtRegionMapReadyMaxSteps; i++) {
    await tester.pump(_kCtRegionMapReadyStep);
    final s = getSnap();
    if (_snapshotAtFitBaseline(s)) {
      return s!;
    }
  }
  fail(
    'CtRegionMap did not reach fit baseline (m≈1) within '
    '${_kCtRegionMapReadyMaxSteps * _kCtRegionMapReadyStep.inMilliseconds}ms; '
    'last=${getSnap()}',
  );
}

/// Stepped pinch-out so the scale recognizer sees continuous updates (more reliable than a single jump).
Future<void> pinchZoomOutOnCenter(
  WidgetTester tester,
  Offset center, {
  double startHalfWidth = 30,
  double endHalfWidth = 105,
  int steps = 10,
}) async {
  final g1 = await tester.startGesture(
    center + Offset(-startHalfWidth, 0),
    kind: PointerDeviceKind.touch,
  );
  final g2 = await tester.startGesture(
    center + Offset(startHalfWidth, 0),
    kind: PointerDeviceKind.touch,
  );
  await tester.pump();
  for (var i = 1; i <= steps; i++) {
    final t = i / steps;
    final half = startHalfWidth + (endHalfWidth - startHalfWidth) * t;
    await g1.moveTo(center + Offset(-half, 0));
    await g2.moveTo(center + Offset(half, 0));
    await tester.pump();
  }
  await g1.up();
  await g2.up();
  await tester.pump();
}

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

  testWidgets(
    'CtRegionMap preserves global zoom multiplier across region switches',
    (WidgetTester tester) async {
      final oldWorld = ctRegionMapTestOldWorldRegion();
      final newWorld = ctRegionMapTestNewWorldRegion();
      final bus = AppEventBus.create();
      RegionMapViewportSnapshot? snap;
      var activeRegion = oldWorld;
      var controlledZoomMultiplier = 1.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: SizedBox(
                    width: 400,
                    height: 320,
                    child: CtRegionMap(
                      region: activeRegion,
                      cellSizePx: activeRegion.cellSize.toDouble(),
                      visibilityMode: CtMapVisibilityMode.full,
                      bus: bus,
                      zoomMultiplier: controlledZoomMultiplier,
                      onViewportSnapshotChanged: (s) {
                        snap = s;
                        controlledZoomMultiplier = s.zoomMultiplier;
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await pumpUntilCtRegionMapFitBaseline(tester, () => snap);

      bus.emit(
        RequestRegionMapSetZoomMultiplierEvent(
          regionId: oldWorld.regionId,
          zoomMultiplier: 2.0,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final zoomBeforeSwitch = snap!.zoomMultiplier;
      expect(zoomBeforeSwitch, closeTo(2.0, 0.08));

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                activeRegion = newWorld;
                return Center(
                  child: SizedBox(
                    width: 400,
                    height: 320,
                    child: CtRegionMap(
                      region: activeRegion,
                      cellSizePx: activeRegion.cellSize.toDouble(),
                      visibilityMode: CtMapVisibilityMode.full,
                      bus: bus,
                      zoomMultiplier: controlledZoomMultiplier,
                      onViewportSnapshotChanged: (s) {
                        snap = s;
                        controlledZoomMultiplier = s.zoomMultiplier;
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(snap, isNotNull);
      expect(snap!.regionId, newWorld.regionId);
      expect(snap!.zoomMultiplier, closeTo(zoomBeforeSwitch, 0.1));

      bus.dispose();
    },
    timeout: const Timeout(Duration(seconds: 20)),
  );
}
