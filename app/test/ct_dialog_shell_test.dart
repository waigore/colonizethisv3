import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  group('CtDialogShell layout/scroll', () {
    testWidgets('short content: scroll viewport shorter than maxHeight', (
      WidgetTester tester,
    ) async {
      const maxH = 500.0;
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: CtDialogShell(
                maxHeight: maxH,
                maxWidth: 320,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(height: 48, child: Text('Short')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final scrollBox = tester.renderObject<RenderBox>(
        find.descendant(
          of: find.byType(CtDialogShell),
          matching: find.byType(CustomScrollView),
        ),
      );
      expect(scrollBox.size.height, lessThan(maxH - 32));
    });

    testWidgets('tall content: one outer scroll; drag reveals bottom', (
      WidgetTester tester,
    ) async {
      const maxH = 200.0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: CtDialogShell(
                maxHeight: maxH,
                maxWidth: 280,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < 24; i++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Text('block-$i'),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('block-0'), findsOneWidget);
      expect(find.text('block-23').hitTestable(), findsNothing);

      final scrollable = find.descendant(
        of: find.byType(CtDialogShell),
        matching: find.byType(Scrollable),
      );
      expect(scrollable, findsOneWidget);

      final scrollBox = tester.renderObject<RenderBox>(
        find.descendant(
          of: find.byType(CtDialogShell),
          matching: find.byType(CustomScrollView),
        ),
      );
      expect(scrollBox.size.height, lessThanOrEqualTo(maxH + 1));

      await tester.drag(scrollable, const Offset(0, -400));
      await tester.pumpAndSettle();

      expect(find.text('block-23'), findsOneWidget);
    });
  });

  group('CtDialogShell dark frame contract (#2859 R3 / S4)', () {
    Future<void> pumpShell(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemes.editorialMonocle,
          home: const Scaffold(
            body: Center(
              child: CtDialogShell(
                child: Text('Body'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    BoxDecoration frameDecoration(WidgetTester tester) {
      final DecoratedBox decorated = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(CtDialogShell),
          matching: find.byType(DecoratedBox),
        ),
      );
      return decorated.decoration as BoxDecoration;
    }

    testWidgets('renders a 2px --accent-dim border on every side', (
      tester,
    ) async {
      await pumpShell(tester);
      final BoxDecoration deco = frameDecoration(tester);
      final Border? border = deco.border as Border?;
      expect(border, isNotNull);
      const double expectedWidth = 2;
      expect(border!.top.width, expectedWidth);
      expect(border.bottom.width, expectedWidth);
      expect(border.left.width, expectedWidth);
      expect(border.right.width, expectedWidth);
      expect(border.top.color, EditorialMonoclePalette.accentDim);
      expect(border.bottom.color, EditorialMonoclePalette.accentDim);
      expect(border.left.color, EditorialMonoclePalette.accentDim);
      expect(border.right.color, EditorialMonoclePalette.accentDim);
    });

    testWidgets('background gradient resolves to CtGradients.panelGradient', (
      tester,
    ) async {
      await pumpShell(tester);
      final BoxDecoration deco = frameDecoration(tester);
      final Gradient? gradient = deco.gradient;
      expect(gradient, isA<LinearGradient>());
      final LinearGradient actual = gradient! as LinearGradient;
      final LinearGradient expected = CtGradients.panelGradient;
      expect(actual.colors, expected.colors);
      expect(actual.begin, expected.begin);
      expect(actual.end, expected.end);
    });

    testWidgets('does not paint Material AlertDialog/Card chrome', (
      tester,
    ) async {
      await pumpShell(tester);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('renders even when host theme omits the dark palette', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: Center(child: CtDialogShell(child: Text('Body'))),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Body'), findsOneWidget);

      final BoxDecoration deco = frameDecoration(tester);
      final Border? border = deco.border as Border?;
      expect(border, isNotNull);
      expect(border!.bottom.color, EditorialMonoclePalette.accentDim);
    });
  });

  // Refs #2914 S3 — § Hard-coded color ban in SPEC/ui/pixel-art-ui-catalog.md.
  // The CtDialogShell DefaultTextStyle fallback (used when the host theme's
  // TextTheme.bodyMedium is null) must resolve to EditorialMonoclePalette.fg
  // (the canonical --fg primary-text token), not Material's Colors.white.
  //
  // In practice Flutter's `ThemeData` constructor / `MaterialApp` theme
  // pipeline always merges `Typography.englishLike*` defaults onto the
  // supplied `TextTheme`, so `theme.textTheme.bodyMedium` is non-null at
  // runtime and the fallback branch is defensive code that's hard to reach
  // through a normal widget pump. The fallback `TextStyle` is therefore
  // exposed as a `@visibleForTesting` static getter
  // (`CtDialogShell.fallbackBodyTextStyle`) and pinned here, which (a) is
  // the same object the build() method references via the `??` operator —
  // so this assertion is not circular against build() — and (b) directly
  // forbids `Colors.white` and other raw Material color literals from being
  // reintroduced as the fallback color.
  group('CtDialogShell default text style fallback (#2914 S3)', () {
    test('fallbackBodyTextStyle resolves to the --fg palette token', () {
      expect(
        CtDialogShell.fallbackBodyTextStyle.color,
        EditorialMonoclePalette.fg,
        reason:
            'CtDialogShell.fallbackBodyTextStyle must resolve to the '
            'canonical --fg palette token (SPEC/ui/pixel-art-ui-catalog.md '
            '§ Hard-coded color ban; Refs #2914 S3).',
      );
    });

    test('fallbackBodyTextStyle does not use raw Material color literals', () {
      // Explicit negative pins for the most common raw Material colors that
      // have historically been used as defensive defaults. Adding new
      // entries here is cheap and forces a deliberate review if anyone
      // re-introduces a Material literal as the fallback.
      const List<Color> bannedFallbackColors = <Color>[
        Colors.white,
        Colors.black,
        Color(0xFFFFFFFF),
        Color(0xFF000000),
      ];
      for (final Color banned in bannedFallbackColors) {
        expect(
          CtDialogShell.fallbackBodyTextStyle.color,
          isNot(banned),
          reason:
              'CtDialogShell.fallbackBodyTextStyle must resolve from the '
              'editorial-monocle palette tokens, not raw Material literals '
              '(banned: $banned). SPEC/ui/pixel-art-ui-catalog.md '
              '§ Hard-coded color ban; Refs #2914 S3.',
        );
      }
    });

    testWidgets(
      'when theme.textTheme.bodyMedium is present, DefaultTextStyle uses theme color (not the fallback)',
      (tester) async {
        // Behavioral guard: confirm the shell actually consults
        // `theme.textTheme.bodyMedium` (rather than always picking the
        // fallback) by pumping a theme with a deterministic bodyMedium
        // color and inspecting the style the child actually sees.
        const Color themeBodyColor = Color(0xFF123456);
        final ThemeData themeWithBodyMedium = ThemeData(
          useMaterial3: true,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: themeBodyColor),
          ),
        );

        late TextStyle resolvedStyle;
        await tester.pumpWidget(
          MaterialApp(
            theme: themeWithBodyMedium,
            home: Scaffold(
              body: Center(
                child: CtDialogShell(
                  child: Builder(
                    builder: (BuildContext context) {
                      resolvedStyle = DefaultTextStyle.of(context).style;
                      return const Text('Body');
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(resolvedStyle.color, themeBodyColor);
        expect(
          resolvedStyle.color,
          isNot(CtDialogShell.fallbackBodyTextStyle.color),
          reason:
              'Fallback must only activate when bodyMedium is null; the '
              'theme-supplied color must be preserved otherwise.',
        );
      },
    );
  });
}
