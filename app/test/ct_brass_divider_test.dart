import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/app_shell_harness.dart';

void main() {
  suppressLogsForTests();

  Future<void> pumpInside(WidgetTester tester, Widget child) async {
    await pumpAppShell(
      tester,
      child: Scaffold(
        body: Center(child: child),
      ),
    );
  }

  group('CtBrassDivider visual contract (R7)', () {
    testWidgets('renders with the documented 8px height', (tester) async {
      await pumpInside(
        tester,
        const SizedBox(width: 240, child: CtBrassDivider()),
      );
      final Size renderedSize = tester.getSize(find.byType(CtBrassDivider));
      expect(renderedSize.height, CtBrassDivider.height);
      expect(CtBrassDivider.height, 8.0);
    });

    testWidgets('stretches to the parent width when given infinite room', (
      tester,
    ) async {
      await pumpInside(
        tester,
        const SizedBox(width: 320, child: CtBrassDivider()),
      );
      final Size renderedSize = tester.getSize(find.byType(CtBrassDivider));
      expect(renderedSize.width, 320.0);
    });

    testWidgets('uses #2858 brass tokens (no hard-coded hex)', (tester) async {
      await pumpInside(
        tester,
        const SizedBox(width: 240, child: CtBrassDivider()),
      );
      final CustomPaint paint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(CtBrassDivider),
          matching: find.byType(CustomPaint),
        ),
      );
      final dynamic painter = paint.painter;
      expect(painter, isNotNull);
      expect((painter as dynamic).lineColor, EditorialMonoclePalette.accentDim);
      expect(painter.diamondFill, EditorialMonoclePalette.accent);
      expect(painter.diamondOutline, EditorialMonoclePalette.accentBright);
      expect(painter.dotColor, EditorialMonoclePalette.accentDim);
    });

    test('right-side dot centers follow 6px+4px*i offset rule', () {
      const double width = 240;
      final List<double> centers = ctBrassDividerRightDotCentersForTesting(
        width,
      );
      expect(centers, hasLength(3));
      const double centerX = width / 2;
      const double diamondHalf = 4;
      const double firstOffset = diamondHalf + 6;
      expect(centers[0], closeTo(centerX + firstOffset, 1e-9));
      expect(centers[1], closeTo(centerX + firstOffset + 4, 1e-9));
      expect(centers[2], closeTo(centerX + firstOffset + 8, 1e-9));
    });

    test('diamond bounds are 8x8 centered over the divider', () {
      const double width = 240;
      final Rect diamond = ctBrassDividerDiamondBoundsForTesting(width);
      expect(diamond.width, 8.0);
      expect(diamond.height, 8.0);
      expect(diamond.center.dx, closeTo(width / 2, 1e-9));
      expect(diamond.center.dy, closeTo(CtBrassDivider.height / 2, 1e-9));
    });

    test('minimum width fits diamond + 3 dots/side + dot radii', () {
      const double half = 4;
      const double firstDot = half + 6;
      const double lastDot = firstDot + 8;
      const double expected = 2 * (lastDot + 2);
      expect(ctBrassDividerMinWidthForTesting, closeTo(expected, 1e-9));
    });

    testWidgets('renders without overflow when parent is narrower than the '
        'minimum dot extent (negative path)', (tester) async {
      const double narrowWidth = 12;
      await pumpInside(
        tester,
        const SizedBox(width: narrowWidth, child: CtBrassDivider()),
      );
      expect(tester.takeException(), isNull);
      final Size renderedSize = tester.getSize(find.byType(CtBrassDivider));
      expect(renderedSize.width, narrowWidth);
      expect(renderedSize.height, CtBrassDivider.height);
    });
  });
}
