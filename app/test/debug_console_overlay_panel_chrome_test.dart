// DebugConsoleOverlayPanel editorial-monocle chrome pins (Refs #4352).

import 'package:colonizethis_app/features/game/flame/overlays/debug_console_overlay_panel.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'debug_console_overlay_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  group('DebugConsoleOverlayPanel dark editorial-monocle chrome (Refs #2914 '
      'S3 + S8)', () {
    testWidgets(
      'panel close affordance is a CtIconAction (no Material IconButton)',
      (tester) async {
        final bus = debugConsoleBus();
        await pumpDebugConsolePanel(tester, bus: bus);

        final closeFinder = find.byKey(DebugConsoleOverlayPanel.closeButtonKey);
        expect(
          closeFinder,
          findsOneWidget,
          reason:
              'Refs #2914 S8 requires the catalog CtIconAction primitive '
              '(not the banned Material IconButton) for the close affordance.',
        );
        expect(tester.widget(closeFinder), isA<CtIconAction>());
        expect(
          find.descendant(
            of: find.byType(DebugConsoleOverlayPanel),
            matching: find.byType(CtIconAction),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: find.byType(DebugConsoleOverlayPanel),
            matching: find.byType(IconButton),
          ),
          findsNothing,
          reason:
              'Banned Material IconButton must not appear in the panel '
              'subtree (Refs #2914 S8 / SPEC/ui/pixel-art-ui-catalog.md '
              '§ Material design ban).',
        );
      },
    );

    testWidgets('tapping the CtIconAction close affordance invokes onClose', (
      tester,
    ) async {
      final bus = debugConsoleBus();
      var closeCount = 0;
      await pumpDebugConsolePanel(
        tester,
        bus: bus,
        onClose: () => closeCount += 1,
      );

      await tester.tap(find.byKey(DebugConsoleOverlayPanel.closeButtonKey));
      await tester.pump();

      expect(closeCount, 1);
    });

    testWidgets('header title text style colour resolves to '
        'EditorialMonoclePalette.fg (no Material Colors.white)', (
      tester,
    ) async {
      final bus = debugConsoleBus();
      await pumpDebugConsolePanel(tester, bus: bus);

      final headerText = tester.widget<Text>(find.text('Debug Console'));
      expect(headerText.style?.color, EditorialMonoclePalette.fg);
      expect(headerText.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('TextField input style colour resolves to '
        'EditorialMonoclePalette.fg (no Material Colors.white)', (
      tester,
    ) async {
      final bus = debugConsoleBus();
      await pumpDebugConsolePanel(tester, bus: bus);

      final input = tester.widget<TextField>(find.byKey(debugConsoleInputKey));
      expect(input.style?.color, EditorialMonoclePalette.fg);
    });

    testWidgets(
      'TextField hint style colour resolves to EditorialMonoclePalette.muted '
      'with the documented hint alpha (no Material Colors.white)',
      (tester) async {
        final bus = debugConsoleBus();
        await pumpDebugConsolePanel(tester, bus: bus);

        final input = tester.widget<TextField>(
          find.byKey(debugConsoleInputKey),
        );
        final hintColor = input.decoration?.hintStyle?.color;
        final expectedHint = EditorialMonoclePalette.muted.withValues(
          alpha: DebugConsoleOverlayPanel.hintTextAlpha,
        );
        expect(hintColor, expectedHint);
      },
    );

    testWidgets(
      'TextField fill colour resolves to EditorialMonoclePalette.dialogScrim',
      (tester) async {
        final bus = debugConsoleBus();
        await pumpDebugConsolePanel(tester, bus: bus);

        final input = tester.widget<TextField>(
          find.byKey(debugConsoleInputKey),
        );
        expect(input.decoration?.filled, isTrue);
        expect(
          input.decoration?.fillColor,
          EditorialMonoclePalette.dialogScrim,
        );
      },
    );

    testWidgets('outer Material surface colour resolves to '
        'EditorialMonoclePalette.bgDeep at the documented panel alpha '
        '(no Material Colors.black)', (tester) async {
      final bus = debugConsoleBus();
      await pumpDebugConsolePanel(tester, bus: bus);

      final panelMaterial = tester.widget<Material>(
        find
            .descendant(
              of: find.byType(DebugConsoleOverlayPanel),
              matching: find.byType(Material),
            )
            .first,
      );
      final expectedSurface = EditorialMonoclePalette.bgDeep.withValues(
        alpha: DebugConsoleOverlayPanel.panelBackgroundAlpha,
      );
      expect(panelMaterial.color, expectedSurface);
    });
  });
}
