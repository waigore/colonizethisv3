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
    );  });
}
