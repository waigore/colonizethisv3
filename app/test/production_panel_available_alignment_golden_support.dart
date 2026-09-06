// Shared helpers for Production Available alignment goldens (Refs #4734 Slice G).

import 'package:colonizethis_app/widgets/ct_resource_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget productionAvailableAlignmentTinyIcon(BuildContext context) =>
    const SizedBox(
      key: Key('available_alignment_golden_icon'),
      width: 20,
      height: 20,
    );

double productionAvailableAlignmentQuantityRight(
  WidgetTester tester,
  Finder cellFinder,
) {
  final Finder qty = find.descendant(
    of: cellFinder,
    matching: find.byKey(CtResourceCell.quantityTextKey),
  );
  expect(qty, findsOneWidget);
  return tester.getTopRight(qty).dx;
}
