// Visual goldens for Production Available panel-wide amount alignment (Refs #3999).
// Grain visibility golden: production_panel_available_grain_visibility_golden_test.dart.
// SPEC: SPEC/ui/production-panel.md § Acceptance Criteria (Refs #3999).

import 'package:colonizethis_app/features/game/widgets/production/production_available_grid.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_panel_constants.dart';
import 'package:colonizethis_app/widgets/ct_resource_cell.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'production_panel_available_alignment_golden_support.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: Available mixed labels + deltas align amounts at grid width '
    '(Refs #3999)',
    (WidgetTester tester) async {
      const double cellWidth = 120;
      const double gridWidth =
          cellWidth * 3 + AvailableCellGrid.columnSpacing * 2;
      const Key boundaryKey = ValueKey<String>(
        'production_available_alignment_grid_golden',
      );
      const Key tinKey = ValueKey<String>('align_tin');
      const Key sugarKey = ValueKey<String>('align_sugar');
      const Key refinedKey = ValueKey<String>('align_refined');
      const Key grainKey = ValueKey<String>('align_grain');
      const Key meatKey = ValueKey<String>('align_meat');
      const Key woolKey = ValueKey<String>('align_wool');

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(420, 360),
        center: false,
        child: Padding(
          padding: const EdgeInsets.all(CtSpacing.m),
          child: SizedBox(
            width: gridWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: cellWidth,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      CtResourceCell(
                        key: tinKey,
                        iconBuilder: productionAvailableAlignmentTinyIcon,
                        name: 'Tin',
                        quantity: 4,
                      ),
                      CtResourceCell(
                        key: sugarKey,
                        iconBuilder: productionAvailableAlignmentTinyIcon,
                        name: 'Sugar Cane',
                        quantity: 4,
                      ),
                      CtResourceCell(
                        key: refinedKey,
                        iconBuilder: productionAvailableAlignmentTinyIcon,
                        name: 'Refined Sugar',
                        quantity: 4,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: CtSpacing.m),
                AvailableCellGrid(
                  columnCount: kProductionAvailableCommodityGridColumns,
                  cells: <Widget>[
                    CtResourceCell(
                      key: grainKey,
                      iconBuilder: productionAvailableAlignmentTinyIcon,
                      name: 'Grain',
                      quantity: 0,
                      delta: -16,
                    ),
                    CtResourceCell(
                      key: meatKey,
                      iconBuilder: productionAvailableAlignmentTinyIcon,
                      name: 'Meat',
                      quantity: 0,
                    ),
                    CtResourceCell(
                      key: woolKey,
                      iconBuilder: productionAvailableAlignmentTinyIcon,
                      name: 'Wool',
                      quantity: 0,
                      delta: 12,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      );
      await pumpSettleCapped(tester);

      expect(tester.takeException(), isNull);
      expect(find.text('0'), findsNWidgets(3));
      expect(find.text('-16'), findsOneWidget);
      expect(find.text('+12'), findsOneWidget);
      expect(find.text('4'), findsNWidgets(3));

      final double tinX =
          productionAvailableAlignmentQuantityRight(tester, find.byKey(tinKey));
      final double sugarX = productionAvailableAlignmentQuantityRight(
        tester,
        find.byKey(sugarKey),
      );
      final double refinedX = productionAvailableAlignmentQuantityRight(
        tester,
        find.byKey(refinedKey),
      );
      expect(tinX, closeTo(sugarX, 0.5));
      expect(sugarX, closeTo(refinedX, 0.5));

      final Finder grainQty = find.descendant(
        of: find.byKey(grainKey),
        matching: find.byKey(CtResourceCell.quantityTextKey),
      );
      expect(tester.getSize(grainQty).width, greaterThan(1));
      expect(
        find.descendant(of: find.byKey(meatKey), matching: find.text('0')),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/production_available_amount_alignment_grid.png',
        ),
      );
    },
  );
}
