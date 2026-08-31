import 'package:colonizethis_app/features/game/flame/minimap/minimap.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'game_region_minimap_widget_test_support.dart';

void main() {
  suppressLogsForTests();

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
