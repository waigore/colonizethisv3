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

    testWidgets(
      'magnitude matrix A–H: visibility + alignment at grid width',
      (tester) async {
        for (final case_ in kCtResourceCellMagnitudeMatrixCases) {
          const Key refKey = ValueKey<String>('matrix_ref');
          final Key caseKey = ValueKey<String>('matrix_${case_.id}');
          await pumpCtResourceCellAlignedColumn(
            tester,
            <Widget>[
              CtResourceCell(
                key: refKey,
                iconBuilder: ctResourceCellTinyIcon,
                name: 'Tin',
                quantity: case_.qty,
                delta: case_.delta,
              ),
              CtResourceCell(
                key: caseKey,
                iconBuilder: ctResourceCellTinyIcon,
                name: 'Refined Sugar',
                quantity: case_.qty,
                delta: case_.delta,
              ),
            ],
            cellWidth: kCtResourceCellGridCellWidth,
          );

          final Finder caseCell = find.byKey(caseKey);
          expect(
            find.descendant(of: caseCell, matching: find.text(case_.qtyText)),
            findsOneWidget,
            reason: 'Case ${case_.id}: quantity ${case_.qtyText} must be visible',
          );
          expect(
            ctResourceCellQuantityWidth(tester, caseCell),
            greaterThan(1),
            reason: 'Case ${case_.id}: quantity must have non-zero layout width',
          );
          if (case_.delta != null) {
            final String? deltaText =
                CtResourceCell.formattedDeltaText(case_.delta);
            expect(
              find.descendant(of: caseCell, matching: find.text(deltaText!)),
              findsOneWidget,
              reason: 'Case ${case_.id}: delta $deltaText must be visible',
            );
          }
          expect(
            ctResourceCellQuantityRight(tester, find.byKey(refKey)),
            closeTo(ctResourceCellQuantityRight(tester, caseCell), 0.5),
            reason: 'Case ${case_.id}: quantity anchors must align',
          );
        }
      },
    );

    testWidgets(
      'delta sits immediately to the right of quantity',
      (tester) async {
        const Key deltaKey = ValueKey<String>('adj_delta');
        await pumpCtResourceCellAlignedColumn(
          tester,
          <Widget>[
            CtResourceCell(
              key: deltaKey,
              iconBuilder: ctResourceCellTinyIcon,
              name: 'Wool',
              quantity: 4,
              delta: -40,
            ),
          ],
          cellWidth: kCtResourceCellGridCellWidth,
        );
        final Finder deltaCell = find.byKey(deltaKey);
        final double qtyRight = ctResourceCellQuantityRight(tester, deltaCell);
        final double deltaLeft =
            tester.getTopLeft(find.descendant(
              of: deltaCell,
              matching: find.text('-40'),
            )).dx;
        expect(
          deltaLeft - qtyRight,
          closeTo(CtResourceCell.quantityToDeltaGap, 1.0),
        );
      },
    );

    testWidgets(
      'painted trailing cluster right edge matches leading icon inset',
      (tester) async {
        await pumpCtResourceCellFixedWidth(
          tester,
          CtResourceCell(
            iconBuilder: ctResourceCellTinyIcon,
            name: 'Timber',
            quantity: 920,
            delta: -40,
          ),
          width: 240,
        );
        final Rect cellBox = tester.getRect(find.byType(CtResourceCell));
        final double iconLeft = tester
            .getTopLeft(find.byKey(const Key('test-icon')))
            .dx;
        final double clusterRight = tester
            .getTopRight(find.byKey(CtResourceCell.deltaTextKey))
            .dx;
        final double leftInset = iconLeft - cellBox.left;
        final double rightInset = cellBox.right - clusterRight;
        expect(leftInset, closeTo(CtSpacing.s, 1.0));
        expect(rightInset, closeTo(leftInset, 1.0));
      },
    );
  });
}
