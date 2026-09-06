// CtResourceCell widget-test pump/assert helpers (Refs #2862, #3999, #4117).
//
// Owns harness helpers previously duplicated inline in
// `ct_resource_cell_test.dart` so the near-cap suite keeps only AC groups.

import 'package:colonizethis_app/widgets/ct_resource_cell.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';

/// Representative Available 3-column cell width (~800 dp wide Production
/// with side-by-side subpanels → ~120–130 dp slots).
const double kCtResourceCellGridCellWidth = 120;

CtResourceCell ctResourceCellSample({
  required String name,
  required int quantity,
  int? delta,
}) =>
    CtResourceCell(
      iconBuilder: ctResourceCellTinyIcon,
      name: name,
      quantity: quantity,
      delta: delta,
    );

Widget ctResourceCellTinyIcon(BuildContext context) => const SizedBox(
      key: Key('test-icon'),
      width: 20,
      height: 20,
    );

Future<void> pumpCtResourceCell(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    buildAppShell(
      child: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(width: 240, child: child),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> pumpCtResourceCellFixedWidth(
  WidgetTester tester,
  Widget cell, {
  required double width,
}) async {
  await tester.pumpWidget(
    buildAppShell(
      child: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(width: width, child: cell),
        ),
      ),
    ),
  );
  await tester.pump();
}

Future<void> pumpCtResourceCellAlignedColumn(
  WidgetTester tester,
  List<Widget> cells, {
  required double cellWidth,
}) async {
  await tester.pumpWidget(
    buildAppShell(
      child: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: cellWidth,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: cells,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

RenderParagraph ctResourceCellParagraphFor(WidgetTester tester, String text) {
  return tester.renderObject<RenderParagraph>(
    find.descendant(
      of: find.byType(CtResourceCell),
      matching: find.text(text),
    ),
  );
}

double ctResourceCellQuantityRight(WidgetTester tester, Finder cellFinder) {
  final Finder qty = find.descendant(
    of: cellFinder,
    matching: find.byKey(CtResourceCell.quantityTextKey),
  );
  expect(qty, findsOneWidget);
  return tester.getTopRight(qty).dx;
}

double ctResourceCellQuantityWidth(WidgetTester tester, Finder cellFinder) {
  final Finder qty = find.descendant(
    of: cellFinder,
    matching: find.byKey(CtResourceCell.quantityTextKey),
  );
  expect(qty, findsOneWidget);
  return tester.getSize(qty).width;
}

/// Magnitude matrix rows for panel-wide amount alignment (#3999).
const List<({String id, int qty, int? delta, String qtyText})>
    kCtResourceCellMagnitudeMatrixCases =
    <({String id, int qty, int? delta, String qtyText})>[
  (id: 'A', qty: 0, delta: null, qtyText: '0'),
  (id: 'B', qty: 0, delta: -16, qtyText: '0'),
  (id: 'C', qty: 0, delta: 12, qtyText: '0'),
  (id: 'D', qty: 4, delta: null, qtyText: '4'),
  (id: 'E', qty: 999, delta: null, qtyText: '999'),
  (id: 'F', qty: 9999, delta: null, qtyText: '9,999'),
  (id: 'G', qty: 9999, delta: -999, qtyText: '9,999'),
  (id: 'H', qty: -5, delta: null, qtyText: '-5'),
];
