import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/widgets/ct_compass_rose.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  Future<void> pumpInside(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: Scaffold(
          body: Center(child: child),
        ),
      ),
    );
    await tester.pump();
  }

  group('CtCompassRose visual contract (Refs #2860 S1)', () {
    testWidgets('honours its size parameter (default 48x48)', (tester) async {
      await pumpInside(tester, const CtCompassRose());
      final Size renderedSize = tester.getSize(find.byType(CtCompassRose));
      expect(renderedSize.width, 48.0);
      expect(renderedSize.height, 48.0);
    });

    testWidgets('honours a custom size parameter', (tester) async {
      await pumpInside(tester, const CtCompassRose(size: 32));
      final Size renderedSize = tester.getSize(find.byType(CtCompassRose));
      expect(renderedSize.width, 32.0);
      expect(renderedSize.height, 32.0);
    });

    testWidgets('uses brass tokens from issue #2858 (no hard-coded hex)', (
      tester,
    ) async {
      await pumpInside(tester, const CtCompassRose());
      final CustomPaint paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(CtCompassRose),
          matching: find.byType(CustomPaint),
        ),
      );
      final dynamic painter = paint.painter;
      expect(painter, isNotNull);
      expect((painter as dynamic).armColor, EditorialMonoclePalette.accent);
      expect(painter.ringColor, EditorialMonoclePalette.accent);
      expect(painter.medallionColor, EditorialMonoclePalette.accent);
      expect(painter.medallionCoreColor, EditorialMonoclePalette.bgDeep);
    });

    test('cardinal arms paint at 0.8 alpha per the mockup', () {
      expect(ctCompassRoseCardinalArmOpacityForTesting, closeTo(0.8, 1e-9));
    });

    test('diagonal arms paint at 0.45 alpha per the mockup', () {
      expect(ctCompassRoseDiagonalArmOpacityForTesting, closeTo(0.45, 1e-9));
    });

    test('outer ring paints at 0.35 alpha per the mockup', () {
      expect(ctCompassRoseRingOpacityForTesting, closeTo(0.35, 1e-9));
    });

    test('ring diameter is 75% of the parent side', () {
      expect(ctCompassRoseRingDiameterForTesting(48), closeTo(36.0, 1e-9));
      expect(ctCompassRoseRingDiameterForTesting(64), closeTo(48.0, 1e-9));
    });

    test('outer medallion diameter is 25% of the parent side', () {
      expect(ctCompassRoseMedallionDiameterForTesting(48), closeTo(12.0, 1e-9));
      expect(ctCompassRoseMedallionDiameterForTesting(32), closeTo(8.0, 1e-9));
    });

    test('inner medallion pinhole is smaller than the outer medallion', () {
      const double side = 48;
      final double outer = ctCompassRoseMedallionDiameterForTesting(side);
      final double inner = ctCompassRoseMedallionInnerDiameterForTesting(side);
      expect(inner, lessThan(outer));
      expect(inner, greaterThan(0));
    });

    test('diagonal arms are 60% of the parent side long', () {
      expect(
        ctCompassRoseDiagonalArmLengthForTesting(48),
        closeTo(28.8, 1e-9),
      );
      expect(
        ctCompassRoseDiagonalArmLengthForTesting(32),
        closeTo(19.2, 1e-9),
      );
    });

    testWidgets('renders without exception at very small parent sizes '
        '(negative-path / zero-degenerate guard)', (tester) async {
      await pumpInside(
        tester,
        const SizedBox(width: 0, height: 0, child: CtCompassRose(size: 0)),
      );
      expect(tester.takeException(), isNull);
    });
  });
}
