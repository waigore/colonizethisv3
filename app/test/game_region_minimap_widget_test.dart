import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/flame/minimap/minimap.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'game_region_minimap_widget_test_support.dart';

void main() {
  suppressLogsForTests();

  testWidgets('tap center/top-left emit RequestRegionMapCameraCenterWorldEvent', (
    WidgetTester tester,
  ) async {
    const minimapLogical = 132.0;
    for (final case_
        in <
          ({
            String regionId,
            Future<void> Function(WidgetTester t) tap,
            Offset local,
          })
        >[
          (
            regionId: 'minimapTapRegion',
            tap: (t) => t.tap(regionMinimapGestureFinder),
            local: const Offset(minimapLogical / 2, minimapLogical / 2),
          ),
          (
            regionId: 'minimapCornerRegion',
            tap: (t) async {
              final topLeft = t.getTopLeft(regionMinimapGestureFinder);
              await t.tapAt(topLeft + const Offset(2, 2));
            },
            local: const Offset(2, 2),
          ),
        ]) {
      final bus = AppEventBus.create();
      final centers =
          captureRegionMinimapBusEvents<RequestRegionMapCameraCenterWorldEvent>(
            bus,
          );
      final region = await pumpRegionMinimapTiny(
        tester,
        regionId: case_.regionId,
        bus: bus,
      );
      final (mw, mh) = regionMinimapWorldDims(region);
      await case_.tap(tester);
      await tester.pump();
      expect(centers, hasLength(1));
      final e = centers.single;
      expect(e.regionId, region.regionId);
      final expected = minimapLocalToWorldCenter(
        localOnMinimap: case_.local,
        minimapSize: const Size(minimapLogical, minimapLogical),
        mapWidthWorld: mw,
        mapHeightWorld: mh,
      );
      expect(e.worldCenterX, closeTo(expected.dx, 1e-6));
      expect(e.worldCenterY, closeTo(expected.dy, 1e-6));
    }
  });

  testWidgets('pan gesture sums to minimapDeltaToWorldDelta', (
    WidgetTester tester,
  ) async {
    final bus = AppEventBus.create();
    final pans =
        captureRegionMinimapBusEvents<RequestRegionMapCameraPanWorldDeltaEvent>(
          bus,
        );
    final region = await pumpRegionMinimapTiny(
      tester,
      regionId: 'minimapPanRegion',
      bus: bus,
    );
    final (mw, mh) = regionMinimapWorldDims(region);

    const dragLogical = Offset(24, -16);
    await tester.drag(
      regionMinimapGestureFinder,
      dragLogical,
      touchSlopX: 0,
      touchSlopY: 0,
    );
    await tester.pump();

    expect(pans, isNotEmpty);
    var sumDx = 0.0;
    var sumDy = 0.0;
    for (final p in pans) {
      expect(p.regionId, region.regionId);
      sumDx += p.worldDx;
      sumDy += p.worldDy;
    }
    final expected = minimapDeltaToWorldDelta(
      minimapDelta: dragLogical,
      minimapSize: const Size(132, 132),
      mapWidthWorld: mw,
      mapHeightWorld: mh,
    );
    expect(sumDx, closeTo(expected.dx, 0.02));
    expect(sumDy, closeTo(expected.dy, 0.02));
  });

  testWidgets(
    'matching viewport snapshot shows slider value from zoomMultiplier',
    (WidgetTester tester) async {
      final mb = RegionMinimapTestBus()..disposeLater();
      final region = regionMinimapTinyRegion(regionId: 'minimapZoomRegion');
      await pumpRegionMinimapTiny(
        tester,
        regionId: 'minimapZoomRegion',
        bus: mb.bus,
        viewportSnapshot: regionMinimapSnapshotFor(region, zoom: 2.0),
      );

      expect(find.text('200%'), findsOneWidget);
      final slider = tester.widget<CtSlider>(regionMinimapZoomSliderFinder);
      expect(slider.value, closeTo(2.0, 1e-9));
    },
  );

  testWidgets(
    'zoom slider emits RequestRegionMapSetZoomMultiplierEvent (single + multi tap)',
    (WidgetTester tester) async {
      final bus = AppEventBus.create();
      final zooms =
          captureRegionMinimapBusEvents<RequestRegionMapSetZoomMultiplierEvent>(
            bus,
          );
      final region = regionMinimapTinyRegion(regionId: 'minimapSliderEmitRegion');
      await pumpRegionMinimapTiny(
        tester,
        regionId: 'minimapSliderEmitRegion',
        bus: bus,
        viewportSnapshot: regionMinimapSnapshotFor(region, zoom: 1.0),
      );

      await tapRegionMinimapZoomTrack(tester, fractionFromLeft: 0.75);
      expect(zooms, isNotEmpty);
      expect(zooms.last.regionId, region.regionId);
      expect(zooms.last.zoomMultiplier, greaterThan(1.0));
      expect(
        zooms.last.zoomMultiplier,
        lessThanOrEqualTo(kRegionMinimapZoomMultiplierMaxValue),
      );

      final beforeMulti = zooms.length;
      final box = tester.getRect(regionMinimapZoomSliderFinder);
      final y = box.center.dy;
      for (final x in <double>[box.left + 4, box.center.dx, box.right - 6]) {
        await tester.tapAt(Offset(x, y));
        await tester.pump();
      }
      expect(zooms.length, greaterThan(beforeMulti));
      expect(zooms.every((e) => e.regionId == region.regionId), isTrue);
    },
  );

  testWidgets('toggle hides gesture target but keeps slider row', (
    WidgetTester tester,
  ) async {
    final mb = RegionMinimapTestBus()..disposeLater();
    await pumpRegionMinimapTiny(
      tester,
      regionId: 'minimapToggleRegion',
      bus: mb.bus,
    );

    expect(regionMinimapGestureFinder, findsOneWidget);
    await tester.tap(regionMinimapToggleFinder);
    await tester.pump();

    expect(regionMinimapGestureFinder, findsNothing);
    expect(regionMinimapZoomSliderFinder, findsOneWidget);
  });
}
