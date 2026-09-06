import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_dialog_shell_test_support.dart';

void main() {
  suppressLogsForTests();

  group('CtDialogShell layout/scroll', () {
    testWidgets('short content: scroll viewport shorter than maxHeight', (
      WidgetTester tester,
    ) async {
      const maxH = 500.0;
      await tester.pumpWidget(
        ctDialogShellTestHost(
          const Scaffold(
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
        ctDialogShellTestHost(
          Scaffold(
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
    testWidgets('renders a 2px --accent-dim border on every side', (
      tester,
    ) async {
      await pumpCtDialogShellDefault(tester);
      final BoxDecoration deco = ctDialogShellFrameDecoration(tester);
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
      await pumpCtDialogShellDefault(tester);
      final BoxDecoration deco = ctDialogShellFrameDecoration(tester);
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
      await pumpCtDialogShellDefault(tester);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(Card), findsNothing);
    });

    testWidgets('renders even when host theme omits the dark palette', (
      tester,
    ) async {
      await tester.pumpWidget(
        ctDialogShellTestHost(
          const Scaffold(
            body: Center(child: CtDialogShell(child: Text('Body'))),
          ),
          themeOverride: ThemeData.light(),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.text('Body'), findsOneWidget);

      final BoxDecoration deco = ctDialogShellFrameDecoration(tester);
      final Border? border = deco.border as Border?;
      expect(border, isNotNull);
      expect(border!.bottom.color, EditorialMonoclePalette.accentDim);
    });
  });

  group('CtDialogShell default text style fallback (#2914 S3)', () {
    test('fallbackBodyTextStyle resolves to the --fg palette token', () {
      expect(
        CtDialogShell.fallbackBodyTextStyle.color,
        EditorialMonoclePalette.fg,
      );
    });

    test('fallbackBodyTextStyle does not use raw Material color literals', () {
      const List<Color> bannedFallbackColors = <Color>[
        Colors.white,
        Colors.black,
        Color(0xFFFFFFFF),
        Color(0xFF000000),
      ];
      for (final Color banned in bannedFallbackColors) {
        expect(CtDialogShell.fallbackBodyTextStyle.color, isNot(banned));
      }
    });

    testWidgets(
      'when theme.textTheme.bodyMedium is present, DefaultTextStyle uses theme color (not the fallback)',
      (tester) async {
        const Color themeBodyColor = Color(0xFF123456);
        final ThemeData themeWithBodyMedium = ThemeData(
          useMaterial3: true,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(color: themeBodyColor),
          ),
        );

        late TextStyle resolvedStyle;
        await tester.pumpWidget(
          ctDialogShellTestHost(
            Scaffold(
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
            themeOverride: themeWithBodyMedium,
          ),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(resolvedStyle.color, themeBodyColor);
        expect(
          resolvedStyle.color,
          isNot(CtDialogShell.fallbackBodyTextStyle.color),
        );
      },
    );
  });
}
