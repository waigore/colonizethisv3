// Pins the dark editorial-monocle chrome contract for
// ProvinceSeaZoneDetailOverlay header + close control.
// SPEC: SPEC/ui/province-sea-zone-detail-overlay.md
// § Style / implementation — Dark-theme chrome (header + close control).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/province_overlay_demo_data.dart'
    show
        demoGameForOverlay,
        sampleProvinceIdForOverlay,
        sampleSeaZoneIdForOverlay;

import 'support/province_overlay_test_harness.dart';

void main() {
  suppressLogsForTests();

  // No asset bundle stubbing is required: per Refs #2859 R2 / S3, `CtPanel`
  // paints its dark editorial-monocle chrome programmatically from
  // `CtGradients.panelGradient` and 1.5 px `--accent-dim` border strips, so
  // it no longer depends on the legacy `ui_button_nine_patch.png` parchment
  // asset or the asynchronous image-decode pipeline that previously leaked
  // `Codec failed to produce an image` warnings in this test. The dark-chrome
  // contract for the panel is pinned by `ct_panel_dark_chrome_test.dart`.

  group(
    'ProvinceSeaZoneDetailOverlay dark editorial-monocle chrome (SPEC § Dark-theme chrome)',
    () {
      testWidgets(
        'province header title resolves to --accent color with 0.05 letter-spacing',
        (WidgetTester tester) async {
          // Use selectedTileKey: null to keep the test focused on header chrome
          // (avoids tile section commodity icons which would require additional
          // asset stubs and cause async decode churn unrelated to this contract).
          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: demoGameForOverlay,
              displayId: sampleProvinceIdForOverlay,
            ),
          );
          await tester.pumpAndSettle();

          final Text title = tester.widget<Text>(find.text('Province'));
          expect(title.style?.color, EditorialMonoclePalette.accent);
          expect(title.style?.letterSpacing, 0.05);
        },
      );

      testWidgets(
        'sea-zone header title resolves to --accent color with 0.05 letter-spacing',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: demoGameForOverlay,
              displayId: sampleSeaZoneIdForOverlay,
            ),
          );
          await tester.pumpAndSettle();

          final Text title = tester.widget<Text>(find.text('Sea zone'));
          expect(title.style?.color, EditorialMonoclePalette.accent);
          expect(title.style?.letterSpacing, 0.05);
        },
      );

      testWidgets(
        'close control border resolves to --accent-dim at 1 px width',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: demoGameForOverlay,
              displayId: sampleProvinceIdForOverlay,
            ),
          );
          await tester.pumpAndSettle();

          final Container closeContainer = tester.widget<Container>(
            find.descendant(
              of: find.byKey(const Key('overlay_close')),
              matching: find.byType(Container),
            ),
          );
          final BoxDecoration decoration =
              closeContainer.decoration! as BoxDecoration;
          final Border border = decoration.border! as Border;
          expect(border.top.color, EditorialMonoclePalette.accentDim);
          expect(border.bottom.color, EditorialMonoclePalette.accentDim);
          expect(border.left.color, EditorialMonoclePalette.accentDim);
          expect(border.right.color, EditorialMonoclePalette.accentDim);
          expect(border.top.width, 1.0);
        },
      );

      testWidgets('close glyph text color resolves to --muted', (
        WidgetTester tester,
      ) async {
        await tester.pumpWidget(
          buildProvinceOverlayDarkThemeShell(
            game: demoGameForOverlay,
            displayId: sampleProvinceIdForOverlay,
          ),
        );
        await tester.pumpAndSettle();

        final Text glyph = tester.widget<Text>(find.text('×'));
        expect(glyph.style?.color, EditorialMonoclePalette.muted);
      });

      testWidgets('close control tap fires onClose exactly once per tap', (
        WidgetTester tester,
      ) async {
        int callCount = 0;
        await tester.pumpWidget(
          buildProvinceOverlayDarkThemeShell(
            game: demoGameForOverlay,
            displayId: sampleProvinceIdForOverlay,
            onClose: () => callCount += 1,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('overlay_close')));
        await tester.pump();

        expect(callCount, 1);
      });

      testWidgets(
        'negative: header chrome does not introduce raw colorScheme.outline border on close control',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: demoGameForOverlay,
              displayId: sampleProvinceIdForOverlay,
            ),
          );
          await tester.pumpAndSettle();

          final Container closeContainer = tester.widget<Container>(
            find.descendant(
              of: find.byKey(const Key('overlay_close')),
              matching: find.byType(Container),
            ),
          );
          final BoxDecoration decoration =
              closeContainer.decoration! as BoxDecoration;
          final Border border = decoration.border! as Border;
          final BuildContext context = tester.element(
            find.byKey(const Key('overlay_close')),
          );
          final Color outline = Theme.of(context).colorScheme.outline;
          expect(
            border.top.color,
            isNot(outline),
            reason:
                'Close button must source border colour from EditorialMonoclePalette.accentDim, not Theme.colorScheme.outline',
          );
        },
      );

      testWidgets(
        'negative: header title does not use a const TextStyle without --accent colour',
        (WidgetTester tester) async {
          await tester.pumpWidget(
            buildProvinceOverlayDarkThemeShell(
              game: demoGameForOverlay,
              displayId: sampleProvinceIdForOverlay,
            ),
          );
          await tester.pumpAndSettle();

          final Text title = tester.widget<Text>(find.text('Province'));
          expect(title.style?.color, isNotNull);
          expect(title.style?.color, isNot(equals(null)));
          expect(title.style?.color, EditorialMonoclePalette.accent);
        },
      );
    },
  );
}
