// Tests for the CtIconAction disabled chrome, colour overrides, and semantics. Mirrors
// SPEC/ui/pixel-art-ui-catalog.md § Pixel-art component catalog —
// CtIconAction. Refs #2914 (Phase 1 §S8).

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_icon_action_test_support.dart';

void main() {
  suppressLogsForTests();

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
