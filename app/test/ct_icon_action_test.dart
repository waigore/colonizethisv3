// Tests for the CtIconAction glyph-only action primitive. Mirrors
// SPEC/ui/pixel-art-ui-catalog.md § Pixel-art component catalog —
// CtIconAction. Refs #2914 (Phase 1 §S8).

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  Future<void> pumpIconAction(WidgetTester tester, Widget child) async {
    await pumpAppShell(
      tester,
      child: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  AnimatedContainer bodyContainer(WidgetTester tester) {
    return tester.widget<AnimatedContainer>(
      find.descendant(
        of: find.byType(CtIconAction),
        matching: find.byType(AnimatedContainer),
      ),
    );
  }

  Color bodyColor(WidgetTester tester) {
    final BoxDecoration deco = bodyContainer(tester).decoration! as BoxDecoration;
    return deco.color!;
  }

  Icon glyphIcon(WidgetTester tester) {
    return tester.widget<Icon>(
      find.descendant(
        of: find.byType(CtIconAction),
        matching: find.byType(Icon),
      ),
    );
  }

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

  group('CtIconAction disabled state', () {
    testWidgets(
      'enabled:false renders 0.4 opacity per shared disabled convention',
      (tester) async {
        await pumpIconAction(
          tester,
          const CtIconAction(
            icon: Icons.my_location,
            onPressed: null,
            enabled: false,
          ),
        );
        final Opacity opacity = tester.widget<Opacity>(
          find.descendant(
            of: find.byType(CtIconAction),
            matching: find.byType(Opacity),
          ),
        );
        expect(opacity.opacity, CtBackButton.disabledOpacity);
        expect(opacity.opacity, 0.4);
      },
    );

    testWidgets(
      'onPressed:null also yields the disabled chrome (no GestureDetector)',
      (tester) async {
        await pumpIconAction(
          tester,
          const CtIconAction(icon: Icons.my_location, onPressed: null),
        );
        expect(
          find.descendant(
            of: find.byType(CtIconAction),
            matching: find.byType(GestureDetector),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(CtIconAction),
            matching: find.byType(MouseRegion),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'disabled does not invoke onPressed on tap (negative path)',
      (tester) async {
        int taps = 0;
        await pumpIconAction(
          tester,
          CtIconAction(
            icon: Icons.my_location,
            enabled: false,
            onPressed: () => taps++,
          ),
        );
        await tester.tap(find.byType(CtIconAction), warnIfMissed: false);
        expect(taps, 0);
      },
    );

    testWidgets(
      'disabled freezes the AnimatedContainer (duration = Duration.zero)',
      (tester) async {
        await pumpIconAction(
          tester,
          const CtIconAction(icon: Icons.my_location, onPressed: null),
        );
        expect(bodyContainer(tester).duration, Duration.zero);
      },
    );

    testWidgets(
      'disabled glyph falls back to disabledIconColor override when set',
      (tester) async {
        await pumpIconAction(
          tester,
          CtIconAction(
            icon: Icons.handyman,
            enabled: false,
            onPressed: () {},
            disabledIconColor: EditorialMonoclePalette.muted,
          ),
        );
        expect(glyphIcon(tester).color, EditorialMonoclePalette.muted);
      },
    );

    testWidgets(
      'enabled wraps without an Opacity (negative path)',
      (tester) async {
        await pumpIconAction(
          tester,
          CtIconAction(icon: Icons.menu, onPressed: () {}),
        );
        expect(
          find.descendant(
            of: find.byType(CtIconAction),
            matching: find.byType(Opacity),
          ),
          findsNothing,
        );
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

  group('CtIconAction colour overrides', () {
    testWidgets(
      'iconColor overrides the idle --accent-dim default',
      (tester) async {
        await pumpIconAction(
          tester,
          CtIconAction(
            icon: Icons.my_location,
            iconColor: EditorialMonoclePalette.muted,
            onPressed: () {},
          ),
        );
        expect(glyphIcon(tester).color, EditorialMonoclePalette.muted);
      },
    );

    testWidgets(
      'iconSize honours per-call overrides (e.g. 24 dp menu)',
      (tester) async {
        await pumpIconAction(
          tester,
          CtIconAction(
            icon: Icons.menu,
            iconSize: 24,
            onPressed: () {},
          ),
        );
        final Size size = tester.getSize(find.byType(CtIconAction));
        expect(size.width, 24 + CtIconAction.defaultHitPadding * 2);
        expect(glyphIcon(tester).size, 24);
      },
    );
  });

  group('CtIconAction accessibility', () {
    testWidgets(
      'semanticLabel surfaces through Semantics when supplied',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await pumpIconAction(
          tester,
          CtIconAction(
            icon: Icons.my_location,
            semanticLabel: 'Locate tile',
            onPressed: () {},
          ),
        );
        expect(find.bySemanticsLabel('Locate tile'), findsOneWidget);
        handle.dispose();
      },
    );

    testWidgets(
      'tooltip is used as a fallback semantic label when semanticLabel is null',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await pumpIconAction(
          tester,
          CtIconAction(
            icon: Icons.my_location,
            tooltip: 'Locate',
            onPressed: () {},
          ),
        );
        // The tooltip widget itself adds a Semantics node with the same label,
        // so we expect at least one matching node.
        expect(find.bySemanticsLabel('Locate'), findsWidgets);
        handle.dispose();
      },
    );
  });
}
