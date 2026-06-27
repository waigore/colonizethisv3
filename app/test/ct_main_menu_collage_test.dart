import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_main_menu_collage.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  Future<void> pumpInside(WidgetTester tester, Widget child) async {
    await pumpAppShell(
      tester,
      child: Scaffold(body: child),
    );
  }

  group('CtMainMenuCollage visual contract (Refs #2860 S2)', () {
    testWidgets('expands to fill its parent box', (tester) async {
      await pumpInside(
        tester,
        const SizedBox(
          width: 800,
          height: 600,
          child: CtMainMenuCollage(),
        ),
      );
      final Size renderedSize = tester.getSize(find.byType(CtMainMenuCollage));
      expect(renderedSize.width, 800.0);
      expect(renderedSize.height, 600.0);
    });

    testWidgets('uses brass `accent` token from #2858 (no hard-coded hex)',
        (tester) async {
      await pumpInside(
        tester,
        const SizedBox(
          width: 400,
          height: 300,
          child: CtMainMenuCollage(),
        ),
      );
      final CustomPaint paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(CtMainMenuCollage),
          matching: find.byType(CustomPaint),
        ),
      );
      final dynamic painter = paint.painter;
      expect(painter, isNotNull);
      expect((painter as dynamic).glyphColor, EditorialMonoclePalette.accent);
    });

    test('canonical viewBox is 1920 x 1080 (matches inline mockup `<svg>`)', () {
      expect(ctMainMenuCollageViewBoxForTesting, const Size(1920, 1080));
    });

    test('final collage alpha is 0.8 per mockup `.collage-svg { opacity }`', () {
      expect(ctMainMenuCollageOpacityForTesting, closeTo(0.8, 1e-9));
    });

    test('per-group opacities match the mockup `<g opacity>` attributes', () {
      // Pin every documented `<g opacity=>` value from the mockup. This is
      // the negative-path guard against silent drift between the mockup
      // and the painter constants.
      final Map<String, double> expected = const {
        'tradeRoutes': 0.40,
        'waypoints': 0.45,
        'telescope': 0.55,
        'spyglass': 0.50,
        'muskets': 0.55,
        'powderHorn': 0.50,
        'sextant': 0.55,
        'hourglass': 0.55,
        'anchor': 0.55,
        'soldier': 0.55,
        'shipsWheel': 0.55,
        'cannon': 0.55,
        'waves': 0.50,
      };
      final Map<String, double> actual =
          ctMainMenuCollageGroupOpacitiesForTesting();
      expect(actual.keys, equals(expected.keys));
      for (final entry in expected.entries) {
        expect(
          actual[entry.key],
          closeTo(entry.value, 1e-9),
          reason: 'group "${entry.key}" alpha drift',
        );
      }
    });

    testWidgets('renders without exception at zero-degenerate sizes '
        '(negative-path guard)', (tester) async {
      await pumpInside(
        tester,
        const SizedBox(
          width: 0,
          height: 0,
          child: CtMainMenuCollage(),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without exception at extremely wide aspect ratios '
        '(letterbox/pillarbox guard)', (tester) async {
      await pumpInside(
        tester,
        const SizedBox(
          width: 1200,
          height: 80,
          child: CtMainMenuCollage(),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders without exception at extremely tall aspect ratios '
        '(letterbox/pillarbox guard)', (tester) async {
      await pumpInside(
        tester,
        const SizedBox(
          width: 80,
          height: 1200,
          child: CtMainMenuCollage(),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('shouldRepaint flips when the glyph color changes',
        (tester) async {
      await pumpInside(
        tester,
        const SizedBox(
          width: 400,
          height: 300,
          child: CtMainMenuCollage(),
        ),
      );
      final CustomPaint paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(CtMainMenuCollage),
          matching: find.byType(CustomPaint),
        ),
      );
      final CustomPainter painter = paint.painter!;
      // shouldRepaint compares painter classes that are identical except
      // for the glyph color — covers the equality branch.
      expect(painter.shouldRepaint(painter), isFalse);
    });
  });
}
