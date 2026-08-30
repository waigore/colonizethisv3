// Tests for the CtIconAction glyph-only action primitive. Mirrors
// SPEC/ui/pixel-art-ui-catalog.md § Pixel-art component catalog —
// CtIconAction. Refs #2914 (Phase 1 §S8).

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_icon_action_test_support.dart';

void main() {
  suppressLogsForTests();

  group('CtIconAction visual contract', () {
    testWidgets(
      'default 18 dp glyph yields a 24 dp tap target (18 + 2*3 hit padding)',
      (tester) async {
        await pumpIconAction(
          tester,
          CtIconAction(icon: Icons.my_location, onPressed: () {}),
        );
        final Size size = tester.getSize(find.byType(CtIconAction));
        expect(size.width, 24);
        expect(size.height, 24);
        final Icon icon = glyphIcon(tester);
        expect(icon.size, CtIconAction.defaultIconSize);
        expect(CtIconAction.defaultIconSize, 18);
      },
    );

    testWidgets(
      'idle: --accent-dim glyph + transparent --surface-lite background',
      (tester) async {
        await pumpIconAction(
          tester,
          CtIconAction(icon: Icons.my_location, onPressed: () {}),
        );
        expect(glyphIcon(tester).color, EditorialMonoclePalette.accentDim);
        final Color bg = bodyColor(tester);
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
      'hover: --accent glyph + --surface-lite background @ 40%',
      (tester) async {
        await pumpIconAction(
          tester,
          CtIconAction(icon: Icons.my_location, onPressed: () {}),
        );
        final TestGesture gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        addTearDown(gesture.removePointer);
        await gesture.addPointer(location: Offset.zero);
        await gesture.moveTo(tester.getCenter(find.byType(CtIconAction)));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(glyphIcon(tester).color, EditorialMonoclePalette.accent);
        expect(
          bodyColor(tester).a,
          closeTo(CtBackButton.hoverBackgroundAlpha, 1e-6),
        );
      },
    );

    testWidgets(
      'pressed: --accent-bright glyph + --surface-lite background @ 60%',
      (tester) async {
        await pumpIconAction(
          tester,
          CtIconAction(icon: Icons.my_location, onPressed: () {}),
        );
        final TestGesture press = await tester.startGesture(
          tester.getCenter(find.byType(CtIconAction)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(glyphIcon(tester).color, EditorialMonoclePalette.accentBright);
        expect(
          bodyColor(tester).a,
          closeTo(CtBackButton.pressedBackgroundAlpha, 1e-6),
        );

        await press.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'enabled animation duration matches CtBackButton 120ms ease-out',
      (tester) async {
        await pumpIconAction(
          tester,
          CtIconAction(icon: Icons.my_location, onPressed: () {}),
        );
        final AnimatedContainer container = bodyContainer(tester);
        expect(container.duration, CtBackButton.animationDuration);
        expect(container.duration, const Duration(milliseconds: 120));
        expect(container.curve, CtBackButton.animationCurve);
      },
    );
  });

  group('CtIconAction tap behaviour and tooltip', () {
    testWidgets('onPressed is invoked once per tap', (tester) async {
      int taps = 0;
      await pumpIconAction(
        tester,
        CtIconAction(
          icon: Icons.my_location,
          onPressed: () => taps++,
        ),
      );
      await tester.tap(find.byType(CtIconAction));
      expect(taps, 1);
    });

    testWidgets(
      'tooltip is reachable through find.byTooltip when supplied',
      (tester) async {
        await pumpIconAction(
          tester,
          CtIconAction(
            icon: Icons.my_location,
            tooltip: 'Locate',
            onPressed: () {},
          ),
        );
        expect(find.byTooltip('Locate'), findsOneWidget);
      },
    );

    testWidgets(
      'no Tooltip widget when tooltip is null or empty (negative path)',
      (tester) async {
        await pumpIconAction(
          tester,
          CtIconAction(icon: Icons.menu, onPressed: () {}),
        );
        expect(
          find.descendant(
            of: find.byType(CtIconAction),
            matching: find.byType(Tooltip),
          ),
          findsNothing,
        );
      },
    );
  });

}
