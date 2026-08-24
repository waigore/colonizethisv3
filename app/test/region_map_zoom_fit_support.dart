// Fit-baseline pump helpers for region map zoom tests (Refs #4642 Slice B).

import 'package:colonizethis_app/features/game/flame/region_map/region_map_viewport_snapshot.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';

/// Max wall time ~9.1s; stops early once the map reports a stable fit baseline
/// (no [pumpAndSettle] — Flame never idles).
///
/// CI shard load can delay first snapshot emission for a few extra seconds.
const int kCtRegionMapReadyMaxSteps = 240;
const Duration kCtRegionMapReadyStep = Duration(milliseconds: 38);

bool snapshotAtFitBaseline(RegionMapViewportSnapshot? s) {
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
  for (var i = 0; i < kCtRegionMapReadyMaxSteps; i++) {
    await tester.pump(kCtRegionMapReadyStep);
    final s = getSnap();
    if (snapshotAtFitBaseline(s)) {
      return s!;
    }
  }
  fail(
    'CtRegionMap did not reach fit baseline (m≈1) within '
    '${kCtRegionMapReadyMaxSteps * kCtRegionMapReadyStep.inMilliseconds}ms; '
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
