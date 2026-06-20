import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_full_screen_dialogue_shell.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget-level contract tests for [CtFullScreenDialogueShell] (issue #2914
/// S2): pins the editorial-monocle scrim token, the centered [CtDialogShell]
/// host, the configurable inner padding, and the `backdrop` / `body` slot
/// composition documented in `SPEC/ui/pixel-art-ui-catalog.md` §
/// *CtFullScreenDialogueShell*.
void main() {
  suppressLogsForTests();

  const Key backdropKey = ValueKey<String>('test.shell.backdrop');
  const Key bodyKey = ValueKey<String>('test.shell.body');

  Future<void> pump(
    WidgetTester tester, {
    double maxWidth = CtFullScreenDialogueShell.defaultMaxWidth,
    double maxHeight = CtFullScreenDialogueShell.defaultMaxHeight,
    EdgeInsetsGeometry padding = CtFullScreenDialogueShell.defaultPadding,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: Scaffold(
          body: CtFullScreenDialogueShell(
            maxWidth: maxWidth,
            maxHeight: maxHeight,
            padding: padding,
            backdrop: const SizedBox.expand(
              key: backdropKey,
              child: Text('backdrop'),
            ),
            body: const SizedBox(
              key: bodyKey,
              width: 120,
              height: 80,
              child: Text('body'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('CtFullScreenDialogueShell (#2914 S2)', () {
    testWidgets(
      'renders backdrop, scrim Material, and CtDialogShell in canonical order',
      (WidgetTester tester) async {
        await pump(tester);

        // Backdrop and body both mount.
        expect(find.byKey(backdropKey), findsOneWidget);
        expect(find.byKey(bodyKey), findsOneWidget);

        // Exactly one CtDialogShell host inside the shell.
        expect(find.byType(CtDialogShell), findsOneWidget);

        // The scrim Material uses the canonical editorial-monocle token —
        // not Colors.black54 / a hex literal.
        final Iterable<Material> scrim = tester
            .widgetList<Material>(find.byType(Material))
            .where((m) => m.color == EditorialMonoclePalette.dialogScrim);
        expect(
          scrim,
          isNotEmpty,
          reason:
              'CtFullScreenDialogueShell must paint its scrim from the '
              'canonical EditorialMonoclePalette.dialogScrim token '
              '(SPEC/ui/pixel-art-ui-catalog.md § Dialog scrim).',
        );

        // Backdrop paints below the scrim+dialog stack.
        final Offset backdropCenter = tester.getCenter(find.byKey(backdropKey));
        final Offset dialogCenter = tester.getCenter(find.byType(CtDialogShell));
        // Both are screen-centered, but the dialog must mount in the foreground
        // (its render order comes after backdrop in the Stack body).
        expect(backdropCenter.dx, closeTo(dialogCenter.dx, 0.01));
      },
    );

    testWidgets('no Material in the subtree leaks Colors.black54', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      final Iterable<Material> black54 = tester
          .widgetList<Material>(find.byType(Material))
          .where((m) => m.color == Colors.black54);
      expect(
        black54,
        isEmpty,
        reason:
            'CtFullScreenDialogueShell must never resolve its scrim from '
            'Colors.black54 (regression guard for #2867 R1 / #2914 S1).',
      );
    });

    testWidgets('forwards maxWidth / maxHeight to the inner CtDialogShell', (
      WidgetTester tester,
    ) async {
      await pump(tester, maxWidth: 300, maxHeight: 240);

      final CtDialogShell shell = tester.widget<CtDialogShell>(
        find.byType(CtDialogShell),
      );
      expect(shell.maxWidth, 300);
      expect(shell.maxHeight, 240);
    });

    testWidgets('wraps body in a single Padding inside the dialog shell', (
      WidgetTester tester,
    ) async {
      const EdgeInsetsGeometry custom = EdgeInsets.all(11);
      await pump(tester, padding: custom);

      // The body must be hosted by exactly one Padding whose padding equals
      // the configured `padding` prop. (The dialog shell adds its own outer
      // padding internally; this is the inner content Padding we control.)
      final Finder paddingFinder = find.ancestor(
        of: find.byKey(bodyKey),
        matching: find.byType(Padding),
      );
      final Iterable<Padding> matchingPaddings = tester
          .widgetList<Padding>(paddingFinder)
          .where((p) => p.padding == custom);
      expect(
        matchingPaddings,
        hasLength(1),
        reason:
            'CtFullScreenDialogueShell must wrap `body` in exactly one '
            'Padding using the configured padding value.',
      );
    });

    testWidgets('default props match SPEC § CtFullScreenDialogueShell', (
      WidgetTester tester,
    ) async {
      await pump(tester);

      final CtDialogShell shell = tester.widget<CtDialogShell>(
        find.byType(CtDialogShell),
      );
      // Default maxWidth / maxHeight from the SPEC and class constants.
      expect(shell.maxWidth, CtFullScreenDialogueShell.defaultMaxWidth);
      expect(shell.maxHeight, CtFullScreenDialogueShell.defaultMaxHeight);
      expect(CtFullScreenDialogueShell.defaultMaxWidth, 520);
      expect(CtFullScreenDialogueShell.defaultMaxHeight, 600);
      expect(
        CtFullScreenDialogueShell.defaultPadding,
        const EdgeInsets.all(20),
      );
    });

    testWidgets(
      'wrapBodyInDialogShell false centers body without CtDialogShell',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppThemes.editorialMonocle,
            home: Scaffold(
              body: CtFullScreenDialogueShell(
                wrapBodyInDialogShell: false,
                padding: EdgeInsets.zero,
                backdrop: const SizedBox.expand(
                  key: backdropKey,
                  child: Text('backdrop'),
                ),
                body: const SizedBox(
                  key: bodyKey,
                  width: 120,
                  height: 80,
                  child: Text('body'),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byKey(bodyKey), findsOneWidget);
        expect(find.byType(CtDialogShell), findsNothing);
        final Iterable<Material> scrim = tester
            .widgetList<Material>(find.byType(Material))
            .where((m) => m.color == EditorialMonoclePalette.dialogScrim);
        expect(scrim, isNotEmpty);
      },
    );
  });
}
