// Tests for ProductionAllocationRowChrome. SPEC/ui/production-panel.md
// § Allocation row chrome (Refs #2862 S3 / R13).

import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/production_allocation_row_chrome.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';

import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  Widget wrap(Widget child) => MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(width: 400, child: child),
          ),
        ),
      );

  testWidgets(
    'Paints CtGradients.rowGradient inside a 1px --accent-dim border',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(
          const ProductionAllocationRowChrome(
            child: Text('row'),
          ),
        ),
      );
      await pumpSettleCapped(tester);

      final boxFinder = find.descendant(
        of: find.byType(ProductionAllocationRowChrome),
        matching: find.byType(DecoratedBox),
      );
      expect(boxFinder, findsAtLeastNWidgets(1));

      final box = tester.widget<DecoratedBox>(boxFinder.first);
      final decoration = box.decoration as BoxDecoration;

      expect(decoration.gradient, CtGradients.rowGradient);
      final border = decoration.border as Border;
      expect(border.top.color, EditorialMonoclePalette.accentDim);
      expect(border.top.width, ProductionAllocationRowChrome.borderWidth);
      expect(border.bottom.color, EditorialMonoclePalette.accentDim);
      expect(border.left.color, EditorialMonoclePalette.accentDim);
      expect(border.right.color, EditorialMonoclePalette.accentDim);
    },
  );

  testWidgets('Renders the supplied child inside the gradient surface', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        const ProductionAllocationRowChrome(
          child: Text('inner content'),
        ),
      ),
    );
    await pumpSettleCapped(tester);

    expect(
      find.descendant(
        of: find.byType(ProductionAllocationRowChrome),
        matching: find.text('inner content'),
      ),
      findsOneWidget,
    );
  });
}
