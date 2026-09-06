import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_back_button_test_support.dart';

void main() {
  suppressLogsForTests();

  group('CtBackButton visual contract (R11a)', () {
    testWidgets('renders a 28x28 tap target with a 16px chevron', (
      tester,
    ) async {
      await pumpCtBackButton(tester, CtBackButton(onPressed: () {}));
      final Size size = tester.getSize(find.byType(CtBackButton));
      expect(size.width, CtBackButton.size);
      expect(size.height, CtBackButton.size);
      expect(CtBackButton.size, 28);
      final Icon icon = ctBackButtonChevronIcon(tester);
      expect(icon.size, CtBackButton.glyphSize);
      expect(CtBackButton.glyphSize, 16);
    });

    testWidgets(
      'default state: --accent-dim glyph + transparent background',
      (tester) async {
        await pumpCtBackButton(tester, CtBackButton(onPressed: () {}));
        expect(
          ctBackButtonChevronIcon(tester).color,
          EditorialMonoclePalette.accentDim,
        );
        expect(ctBackButtonBodyColor(tester).a, 0);
      },
    );

    testWidgets(
      'default background uses --surface-lite with alpha 0 — animation anchor '
      '(Refs #2914 S4, no raw const Color(0x...) literal)',
      (tester) async {
        await pumpCtBackButton(tester, CtBackButton(onPressed: () {}));
        final Color bg = ctBackButtonBodyColor(tester);
        final Color expected = EditorialMonoclePalette.surfaceLite.withValues(
          alpha: 0,
        );
        expect(bg.r, closeTo(expected.r, 1e-6));
        expect(bg.g, closeTo(expected.g, 1e-6));
        expect(bg.b, closeTo(expected.b, 1e-6));
        expect(bg.a, 0);
      },
    );

    testWidgets(
      'hover state: glyph --accent + --surface-lite background @ 40%',
      (tester) async {
        await pumpCtBackButton(tester, CtBackButton(onPressed: () {}));
        final TestGesture gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        await gesture.addPointer(location: Offset.zero);
        await gesture.moveTo(tester.getCenter(find.byType(CtBackButton)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(
          ctBackButtonChevronIcon(tester).color,
          EditorialMonoclePalette.accent,
        );
        expect(
          ctBackButtonBodyColor(tester).a,
          closeTo(CtBackButton.hoverBackgroundAlpha, 1e-6),
        );
      },
    );

    testWidgets(
      'pressed state: glyph --accent-bright + --surface-lite background @ 60%',
      (tester) async {
        await pumpCtBackButton(tester, CtBackButton(onPressed: () {}));
        final TestGesture press = await tester.startGesture(
          tester.getCenter(find.byType(CtBackButton)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(
          ctBackButtonChevronIcon(tester).color,
          EditorialMonoclePalette.accentBright,
        );
        expect(
          ctBackButtonBodyColor(tester).a,
          closeTo(CtBackButton.pressedBackgroundAlpha, 1e-6),
        );

        await press.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'enabled animation duration matches the documented 120ms ease-out',
      (tester) async {
        await pumpCtBackButton(tester, CtBackButton(onPressed: () {}));
        final AnimatedContainer container = ctBackButtonBodyContainer(tester);
        expect(container.duration, CtBackButton.animationDuration);
        expect(container.duration, const Duration(milliseconds: 120));
        expect(container.curve, CtBackButton.animationCurve);
        expect(container.curve, Curves.easeOut);
      },
    );

    testWidgets('disabled (enabled: false) renders 0.4 opacity', (
      tester,
    ) async {
      await pumpCtBackButton(
        tester,
        const CtBackButton(enabled: false),
      );
      expectCtBackButtonDisabledChrome(tester);
    });

    testWidgets('enabled wraps without an Opacity (negative path)', (
      tester,
    ) async {
      await pumpCtBackButton(tester, CtBackButton(onPressed: () {}));
      expect(
        find.descendant(
          of: find.byType(CtBackButton),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    });
  });

  // Tap behaviour + accessibility: ct_back_button_tap_and_a11y_test.dart
}
