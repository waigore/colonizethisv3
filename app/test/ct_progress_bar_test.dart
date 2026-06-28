import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_progress_bar.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  Future<void> pumpBar(WidgetTester tester, Widget child) async {
    await pumpAppShell(
      tester,
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: 200, child: child),
        ),
      ),
    );
  }

  group('CtProgressBar value clamping (R12)', () {
    test('null treated as 0.0', () {
      expect(CtProgressBar.clampValueForTesting(null), 0.0);
    });

    test('values <= 0.0 clamp to 0.0', () {
      expect(CtProgressBar.clampValueForTesting(0.0), 0.0);
      expect(CtProgressBar.clampValueForTesting(-0.5), 0.0);
      expect(CtProgressBar.clampValueForTesting(-99.0), 0.0);
    });

    test('values >= 1.0 clamp to 1.0', () {
      expect(CtProgressBar.clampValueForTesting(1.0), 1.0);
      expect(CtProgressBar.clampValueForTesting(1.5), 1.0);
      expect(CtProgressBar.clampValueForTesting(double.infinity), 1.0);
    });

    test('NaN clamps to 0.0 (defensive)', () {
      expect(CtProgressBar.clampValueForTesting(double.nan), 0.0);
    });

    test('in-range values pass through', () {
      expect(CtProgressBar.clampValueForTesting(0.25), 0.25);
      expect(CtProgressBar.clampValueForTesting(0.75), 0.75);
    });
  });

  group('CtProgressBar visual contract (R12)', () {
    testWidgets('renders with the documented 12px height', (tester) async {
      await pumpBar(tester, const CtProgressBar(value: 0.5));
      final Size barSize = tester.getSize(find.byType(CtProgressBar));
      expect(barSize.height, CtProgressBar.height);
      expect(CtProgressBar.height, 12.0);
    });

    testWidgets('track uses --surface fill and --accent-dim 1px border', (
      tester,
    ) async {
      await pumpBar(tester, const CtProgressBar(value: 0.5));
      final DecoratedBox decorated = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(CtProgressBar),
              matching: find.byType(DecoratedBox),
            ),
          )
          .first;
      final BoxDecoration deco = decorated.decoration as BoxDecoration;
      expect(deco.color, EditorialMonoclePalette.surface);
      final Border border = deco.border! as Border;
      expect(border.top.color, EditorialMonoclePalette.accentDim);
      expect(border.top.width, CtProgressBar.borderWidth);
      expect(border.top.width, 1.0);
    });

    testWidgets('fill region uses --accent color when value > 0', (tester) async {
      await pumpBar(tester, const CtProgressBar(value: 0.5));
      await tester.pump(const Duration(milliseconds: 200));
      final Finder containers = find.descendant(
        of: find.byType(CtProgressBar),
        matching: find.byType(AnimatedContainer),
      );
      expect(containers, findsOneWidget);
      final AnimatedContainer container = tester.widget<AnimatedContainer>(
        containers,
      );
      final BoxDecoration? deco = container.decoration as BoxDecoration?;
      final Color fillColor = deco?.color ?? Colors.transparent;
      expect(fillColor, EditorialMonoclePalette.accent);
    });

    testWidgets('value=0 renders no fill artifact (negative path)', (
      tester,
    ) async {
      await pumpBar(tester, const CtProgressBar(value: 0));
      await tester.pump(const Duration(milliseconds: 200));
      final Finder containers = find.descendant(
        of: find.byType(CtProgressBar),
        matching: find.byType(AnimatedContainer),
      );
      expect(containers, findsNothing);
    });

    testWidgets('value=null renders no fill artifact (negative path)', (
      tester,
    ) async {
      await pumpBar(tester, const CtProgressBar(value: null));
      await tester.pump(const Duration(milliseconds: 200));
      final Finder containers = find.descendant(
        of: find.byType(CtProgressBar),
        matching: find.byType(AnimatedContainer),
      );
      expect(containers, findsNothing);
    });

    testWidgets('value>=1.0 fills entire inner width', (tester) async {
      await pumpBar(tester, const CtProgressBar(value: 1.2));
      await tester.pump(const Duration(milliseconds: 200));
      final AnimatedContainer container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(CtProgressBar),
          matching: find.byType(AnimatedContainer),
        ),
      );
      final double? fillWidth = container.constraints?.maxWidth;
      expect(container.constraints, isNotNull);
      const double expectedInner = 200 - 2 * CtProgressBar.borderWidth;
      expect(fillWidth, closeTo(expectedInner, 0.5));
    });

    testWidgets('animation duration matches the documented 120ms ease-out', (
      tester,
    ) async {
      await pumpBar(tester, const CtProgressBar(value: 0.5));
      final AnimatedContainer container = tester.widget<AnimatedContainer>(
        find.descendant(
          of: find.byType(CtProgressBar),
          matching: find.byType(AnimatedContainer),
        ),
      );
      expect(container.duration, CtProgressBar.animationDuration);
      expect(container.duration, const Duration(milliseconds: 120));
      expect(container.curve, CtProgressBar.animationCurve);
      expect(container.curve, Curves.easeOut);
    });

    testWidgets('non-null label is rendered with --muted color', (tester) async {
      await pumpBar(tester, const CtProgressBar(value: 0.4, label: '40%'));
      expect(find.text('40%'), findsOneWidget);
      final Text text = tester.widget<Text>(find.text('40%'));
      expect(text.style?.color, EditorialMonoclePalette.muted);
    });

    testWidgets('null label is not laid out (no Row wrapper)', (tester) async {
      await pumpBar(tester, const CtProgressBar(value: 0.5));
      expect(
        find.descendant(
          of: find.byType(CtProgressBar),
          matching: find.byType(Row),
        ),
        findsNothing,
      );
    });

    testWidgets('disabled renders at 0.4 opacity', (tester) async {
      await pumpBar(tester, const CtProgressBar(value: 0.5, enabled: false));
      final Opacity opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(CtProgressBar),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.4);
    });

    testWidgets('enabled renders without an Opacity wrapper', (tester) async {
      await pumpBar(tester, const CtProgressBar(value: 0.5));
      expect(
        find.descendant(
          of: find.byType(CtProgressBar),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    });
  });
}
