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

  group('dark editorial-monocle chrome (Refs #2861 S5)', () {
    testWidgets(
      'panel ancestor decoration uses --bg-deep fill + --border outline',
      (WidgetTester tester) async {
        final mb = RegionMinimapTestBus()..disposeLater();
        await pumpRegionMinimapTiny(
          tester,
          regionId: 'minimapChromePanelRegion',
          bus: mb.bus,
        );

        final paintCtx = tester.element(regionMinimapCustomPaintFinder);
        DecoratedBox? panel;
        paintCtx.visitAncestorElements((element) {
          final widget = element.widget;
          if (widget is DecoratedBox) {
            final deco = widget.decoration;
            if (deco is BoxDecoration &&
                deco.color == EditorialMonoclePalette.bgDeep) {
              panel = widget;
              return false;
            }
          }
          return true;
        });
        expect(panel, isNotNull);
        final deco = panel!.decoration as BoxDecoration;
        expect(deco.color, EditorialMonoclePalette.bgDeep);
        expectRegionMinimapBorderColor(deco, EditorialMonoclePalette.border);
      },
    );

    testWidgets(
      'no light-theme Material chrome or Material design buttons inside minimap',
      (WidgetTester tester) async {
        final mb = RegionMinimapTestBus()..disposeLater();
        await pumpRegionMinimapTiny(
          tester,
          regionId: 'minimapChromeNoLightThemeRegion',
          bus: mb.bus,
        );

        for (final m in tester.widgetList<Material>(
          find.descendant(
            of: find.byType(GameRegionMinimap),
            matching: find.byType(Material),
          ),
        )) {
          expect(m.color, isNot(equals(Colors.white)));
          expect(m.color, isNot(equals(Colors.black)));
        }
        for (final type in const <Type>[
          ElevatedButton,
          OutlinedButton,
          FilledButton,
          IconButton,
        ]) {
          expect(
            find.descendant(
              of: find.byType(GameRegionMinimap),
              matching: find.byType(type),
            ),
            findsNothing,
          );
        }
      },
    );

    testWidgets(
      'toggle default and hover paint editorial-monocle glyph/outline tokens',
      (WidgetTester tester) async {
        final mb = RegionMinimapTestBus()..disposeLater();
        await pumpRegionMinimapTiny(
          tester,
          regionId: 'minimapToggleDarkChrome',
          bus: mb.bus,
        );

        expect(regionMinimapToggleFinder, findsOneWidget);

        AnimatedContainer animatedOf(Finder root) =>
            tester.widget<AnimatedContainer>(
              find.descendant(
                of: root,
                matching: find.byType(AnimatedContainer),
              ),
            );
        ColorFiltered filterOf(Finder root) => tester.widget<ColorFiltered>(
          find.descendant(of: root, matching: find.byType(ColorFiltered)),
        );

        final defaultDeco =
            animatedOf(regionMinimapToggleFinder).decoration! as BoxDecoration;
        expect(defaultDeco.color, EditorialMonoclePalette.bgDeep);
        expectRegionMinimapBorderColor(defaultDeco, EditorialMonoclePalette.border);
        expect(
          filterOf(regionMinimapToggleFinder).colorFilter,
          regionMinimapAccentFilter(EditorialMonoclePalette.accentDim),
        );
        final icon = tester.widget<StrictAssetIcon>(
          find.descendant(
            of: regionMinimapToggleFinder,
            matching: find.byType(StrictAssetIcon),
          ),
        );
        expect(icon.width, 20);
        expect(icon.height, 20);

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        await gesture.addPointer(location: Offset.zero);
        await gesture.moveTo(tester.getCenter(regionMinimapToggleFinder));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        final hoverDeco =
            animatedOf(regionMinimapToggleFinder).decoration! as BoxDecoration;
        expect(
          (hoverDeco.border! as Border).top.color,
          EditorialMonoclePalette.accentDim,
        );
        expect(
          filterOf(regionMinimapToggleFinder).colorFilter,
          regionMinimapAccentFilter(EditorialMonoclePalette.accentBright),
        );
      },
    );

    testWidgets(
      'panel padding does not affect minimap gesture local coordinates',
      (WidgetTester tester) async {
        final bus = AppEventBus.create();
        final centers =
            captureRegionMinimapBusEvents<RequestRegionMapCameraCenterWorldEvent>(
              bus,
            );
        final region = await pumpRegionMinimapTiny(
          tester,
          regionId: 'minimapPanelPaddingRegion',
          bus: bus,
        );
        final (mw, mh) = regionMinimapWorldDims(region);

        final gestureBox = tester.getSize(regionMinimapGestureFinder);
        expect(gestureBox.width, 132);
        expect(gestureBox.height, 132);

        final topLeft = tester.getTopLeft(regionMinimapGestureFinder);
        await tester.tapAt(topLeft + const Offset(2, 2));
        await tester.pump();

        expect(centers, hasLength(1));
        final expected = minimapLocalToWorldCenter(
          localOnMinimap: const Offset(2, 2),
          minimapSize: const Size(132, 132),
          mapWidthWorld: mw,
          mapHeightWorld: mh,
        );
        expect(centers.single.worldCenterX, closeTo(expected.dx, 1e-6));
        expect(centers.single.worldCenterY, closeTo(expected.dy, 1e-6));
      },
    );
  });
}
