// Section-header + wide regression pins for
// `ProductionCommodityBreakdownDialog` (PROD20001).
// Chrome + DataTable pins live in
// `production_commodity_breakdown_dialog_320dp_min_viewport_test.dart`.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7;
// `SPEC/ui/production-commodity-breakdown-dialog.md`.
// Refs #2870 S8/S10.

import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'production_commodity_breakdown_dialog_320dp_min_viewport_support.dart';

void main() {
  suppressLogsForTests();

  group('SPEC/ui/mobile-adaptation.md § 7 — ProductionCommodityBreakdownDialog '
      '@ 320 dp (Refs #2870 S8/S10)', () {
    testWidgets(
      'AC (positive) ProductionCommodityBreakdownDialog @ 320×640: at '
      'least one section header (Food / Raw materials / Manufactured) '
      'renders so the body sections from SPEC § Layout / wireframe '
      'still mount at the minimum viewport',
      (WidgetTester tester) async {
        await pumpProductionCommodityBreakdown320(
          tester,
          size: kProductionBreakdown320MinViewport,
        );

        expect(tester.takeException(), isNull);

        // The dialog renders three sections in fixed order — Food,
        // Raw materials, Manufactured. Section headers use small-caps
        // styling so the rendered Text data is the upper-cased label.
        // Section rows are catalog-derived (the static `CommodityCatalog`
        // always has Food commodities), so at least one section header
        // MUST render at 320 dp even with the lightweight tile-less
        // fixture. Asserting on the localized labels (upper-cased by
        // `_sectionHeaderCell`) keeps the AC robust to ruleset commodity
        // rebalances.
        expect(
          find.byWidgetPredicate(
            (Widget w) =>
                w is Text &&
                w.data != null &&
                (w.data == 'FOOD' ||
                    w.data == 'RAW MATERIALS' ||
                    w.data == 'MANUFACTURED'),
          ),
          findsWidgets,
          reason:
              'SPEC § Layout / wireframe: at least one of the three '
              'section headers (Food / Raw materials / Manufactured) '
              'MUST mount inside the DataTable body at the 320 dp '
              'minimum viewport.',
        );
      },
    );
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — ProductionCommodityBreakdownDialog '
      'wide regression sentinel (Refs #2870 S8/S10)', () {
    testWidgets('Negative control: ProductionCommodityBreakdownDialog @ '
        '1024×768 also pumps without exception (regression sentinel '
        'for the overflow contract — keeps the 320 dp positive pins '
        'meaningful)', (WidgetTester tester) async {
      await pumpProductionCommodityBreakdown320(
        tester,
        size: kProductionBreakdown320WideViewport,
      );

      expect(tester.takeException(), isNull);
      expect(find.text('Commodity breakdown'), findsOneWidget);
      expect(find.widgetWithText(CtNinePatchButton, 'Close'), findsOneWidget);
    });
  });
}
