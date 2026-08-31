import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/widgets/ct_resource_cell.dart';
import 'package:colonizethis_app/widgets/ct_spacing.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'ct_resource_cell_test_helpers.dart';

void main() {
  suppressLogsForTests();
  group('CtResourceCell panel-wide amount alignment (#3999)', () {
    testWidgets(
      'quantity 0 with null delta stays visible at grid width',
      (tester) async {
        await pumpCtResourceCellFixedWidth(
          tester,
          CtResourceCell(
            iconBuilder: ctResourceCellTinyIcon,
            name: 'Grain',
            quantity: 0,
          ),
          width: kCtResourceCellGridCellWidth,
        );
        expect(find.text('0'), findsOneWidget);
        expect(
          ctResourceCellQuantityWidth(tester, find.byType(CtResourceCell)),
          greaterThan(1),
        );
      },
    );

    testWidgets(
      'quantity 0 with negative delta shows both values at grid width',
      (tester) async {
        await pumpCtResourceCellFixedWidth(
          tester,
          CtResourceCell(
            iconBuilder: ctResourceCellTinyIcon,
            name: 'Grain',
            quantity: 0,
            delta: -16,
          ),
          width: kCtResourceCellGridCellWidth,
        );
        expect(find.text('0'), findsOneWidget);
        expect(find.text('-16'), findsOneWidget);
        expect(
          ctResourceCellQuantityWidth(tester, find.byType(CtResourceCell)),
          greaterThan(1),
        );
      },
    );

    testWidgets(
      'quantity 0 with positive delta shows both values at grid width',
      (tester) async {
        await pumpCtResourceCellFixedWidth(
          tester,
          CtResourceCell(
            iconBuilder: ctResourceCellTinyIcon,
            name: 'Grain',
            quantity: 0,
            delta: 12,
          ),
          width: kCtResourceCellGridCellWidth,
        );
        expect(find.text('0'), findsOneWidget);
        expect(find.text('+12'), findsOneWidget);
      },
    );

    testWidgets(
      'different label lengths share the same quantity right-edge x',
      (tester) async {
        const Key tinKey = ValueKey<String>('cell_tin');
        const Key sugarKey = ValueKey<String>('cell_sugar');
        const Key refinedKey = ValueKey<String>('cell_refined');
        await pumpCtResourceCellAlignedColumn(
          tester,
          <Widget>[
            CtResourceCell(
              key: tinKey,
              iconBuilder: ctResourceCellTinyIcon,
              name: 'Tin',
              quantity: 4,
            ),
            CtResourceCell(
              key: sugarKey,
              iconBuilder: ctResourceCellTinyIcon,
              name: 'Sugar Cane',
              quantity: 4,
            ),
            CtResourceCell(
              key: refinedKey,
              iconBuilder: ctResourceCellTinyIcon,
              name: 'Refined Sugar',
              quantity: 4,
            ),
          ],
          cellWidth: kCtResourceCellGridCellWidth,
        );
        final double tinX = ctResourceCellQuantityRight(tester, find.byKey(tinKey));
        final double sugarX =
            ctResourceCellQuantityRight(tester, find.byKey(sugarKey));
        final double refinedX =
            ctResourceCellQuantityRight(tester, find.byKey(refinedKey));
        expect(tinX, closeTo(sugarX, 0.5));
        expect(sugarX, closeTo(refinedX, 0.5));
      },
    );

    testWidgets(
      'wide-layout painted trailing inset matches leading icon inset',
      (tester) async {
        const Key nullDeltaKey = ValueKey<String>('inset_null');
        const Key withDeltaKey = ValueKey<String>('inset_delta');
        const double wideCellWidth = 240;
        await pumpCtResourceCellAlignedColumn(
          tester,
          <Widget>[
            CtResourceCell(
              key: nullDeltaKey,
              iconBuilder: ctResourceCellTinyIcon,
              name: 'Meat',
              quantity: 0,
            ),
            CtResourceCell(
              key: withDeltaKey,
              iconBuilder: ctResourceCellTinyIcon,
              name: 'Grain',
              quantity: 0,
              delta: -16,
            ),
          ],
          cellWidth: wideCellWidth,
        );

        for (final Key key in <Key>[nullDeltaKey, withDeltaKey]) {
          final Finder cellFinder = find.byKey(key);
          final Rect cellBox = tester.getRect(cellFinder);
          final double iconLeft = tester
              .getTopLeft(
                find.descendant(
                  of: cellFinder,
                  matching: find.byKey(const Key('test-icon')),
                ),
              )
              .dx;
          final bool hasDelta = key == withDeltaKey;
          final Finder trailing = hasDelta
              ? find.descendant(
                  of: cellFinder,
                  matching: find.byKey(CtResourceCell.deltaTextKey),
                )
              : find.descendant(
                  of: cellFinder,
                  matching: find.byKey(CtResourceCell.quantityTextKey),
                );
          final double trailingRight = tester.getTopRight(trailing).dx;
          final double leftInset = iconLeft - cellBox.left;
          final double rightInset = cellBox.right - trailingRight;
          expect(leftInset, closeTo(CtSpacing.s, 1.0));
          expect(rightInset, closeTo(leftInset, 1.0));
        }
      },
    );

    testWidgets(
      'label-length alignment still holds after inset parity (null deltas)',
      (tester) async {
        const Key shortKey = ValueKey<String>('parity_short');
        const Key longKey = ValueKey<String>('parity_long');
        await pumpCtResourceCellAlignedColumn(
          tester,
          <Widget>[
            CtResourceCell(
              key: shortKey,
              iconBuilder: ctResourceCellTinyIcon,
              name: 'Tin',
              quantity: 4,
            ),
            CtResourceCell(
              key: longKey,
              iconBuilder: ctResourceCellTinyIcon,
              name: 'Refined Sugar',
              quantity: 4,
            ),
          ],
          cellWidth: 240,
        );
        expect(
          ctResourceCellQuantityRight(tester, find.byKey(shortKey)),
          closeTo(ctResourceCellQuantityRight(tester, find.byKey(longKey)), 0.5),
        );
      },
    );

    testWidgets(
      'worker counts follow the same quantity alignment rule',
      (tester) async {
        const Key shortKey = ValueKey<String>('worker_short');
        const Key longKey = ValueKey<String>('worker_long');
        await pumpCtResourceCellAlignedColumn(
          tester,
          <Widget>[
            CtResourceCell(
              key: shortKey,
              iconBuilder: ctResourceCellTinyIcon,
              name: 'Masters',
              quantity: 6,
            ),
            CtResourceCell(
              key: longKey,
              iconBuilder: ctResourceCellTinyIcon,
              name: 'Journeymen',
              quantity: 6,
            ),
          ],
          cellWidth: 160,
        );
        expect(
          ctResourceCellQuantityRight(tester, find.byKey(shortKey)),
          closeTo(ctResourceCellQuantityRight(tester, find.byKey(longKey)), 0.5),
        );
      },
    );
  });
}
