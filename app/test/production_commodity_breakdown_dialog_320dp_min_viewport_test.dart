// Pin the 320 dp minimum-viewport contract for
// `ProductionCommodityBreakdownDialog` (PROD20001) — chrome + DataTable.
// Section headers + wide sentinel live in
// `production_commodity_breakdown_dialog_320dp_min_viewport_layout_test.dart`.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7;
// `SPEC/ui/production-commodity-breakdown-dialog.md`.
// Refs #2870 S8/S10.

import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'production_commodity_breakdown_dialog_320dp_min_viewport_support.dart';

void main() {
  suppressLogsForTests();

  group('SPEC/ui/mobile-adaptation.md § 7 — ProductionCommodityBreakdownDialog '
      '@ 320 dp (Refs #2870 S8/S10)', () {
    testWidgets(
      'AC (positive) ProductionCommodityBreakdownDialog @ 320×640: no '
      'RenderFlex overflow exception, title + Close action render',
      (WidgetTester tester) async {
        await pumpProductionCommodityBreakdown320(
          tester,
          size: kProductionBreakdown320MinViewport,
        );

        expect(
          tester.takeException(),
          isNull,
          reason:
              'SPEC/ui/mobile-adaptation.md § 7: '
              'ProductionCommodityBreakdownDialog MUST NOT emit a '
              'RenderFlex overflow exception at kMinViewportWidth '
              '(320 dp). The CtDialogShell content column at 320 dp '
              'collapses to ~288 dp — the title row, the '
              'horizontally-scrollable DataTable body, and the '
              'trailing right-aligned Close action must lay out '
              'inside that column without horizontal overflow per '
              'SPEC/ui/production-commodity-breakdown-dialog.md '
              '§ Layout / wireframe.',
        );

        // Localized PROD20001 title from `production_breakdown_title`.
        expect(find.text('Commodity breakdown'), findsOneWidget);

        // Trailing right-aligned Close action — the only interactive
        // affordance on the read-only dialog. The SPEC layout pins it
        // as a `CtNinePatchButton` so the localized `common_close`
        // label must render through `CtNinePatchButton` at the
        // minimum viewport too.
        expect(
          find.widgetWithText(CtNinePatchButton, 'Close'),
          findsOneWidget,
          reason:
              'Trailing Close action MUST render as a CtNinePatchButton '
              'descendant at 320 dp so the dialog remains dismissable '
              'inside the ~288 dp CtDialogShell content column.',
        );
      },
    );

    testWidgets('AC (positive) ProductionCommodityBreakdownDialog @ 320×640: '
        'exactly one DataTable renders with '
        '1 + EconomyPreviewStockpilePhase.values.length + 1 columns and '
        'is wrapped in a horizontal Scrollbar + SingleChildScrollView '
        '(the Wide-table state from SPEC § States and variants)', (
      WidgetTester tester,
    ) async {
      await pumpProductionCommodityBreakdown320(
        tester,
        size: kProductionBreakdown320MinViewport,
      );

      expect(tester.takeException(), isNull);

      // The wide DataTable body shape from
      // SPEC/ui/production-commodity-breakdown-dialog.md
      // § Widget contract MUST survive the narrow viewport — the
      // SPEC's horizontal-scroll contract relies on the full
      // column set being present so the Scrollbar / scroll
      // viewport actually has overflow content to scroll.
      expect(find.byType(DataTable), findsOneWidget);
      final DataTable table = tester.widget<DataTable>(find.byType(DataTable));
      final int expectedColumns =
          1 + EconomyPreviewStockpilePhase.values.length + 1;
      expect(
        table.columns.length,
        expectedColumns,
        reason:
            'SPEC/ui/production-commodity-breakdown-dialog.md '
            '§ Acceptance Criteria: the DataTable column count MUST '
            'remain `1 + EconomyPreviewStockpilePhase.values.length '
            '+ 1` (commodity + per-phase + total) even at the 320 dp '
            'minimum viewport. A regression that dropped phase '
            'columns under narrow widths would silently break the '
            'preview contract.',
      );

      // The horizontal-axis Scrollbar + SingleChildScrollView pair
      // is the SPEC's Wide-table state escape hatch. At 320 dp the
      // table is wider than the ~288 dp content column, so this
      // affordance MUST be present and actually horizontal.
      final Finder horizontalScrollView = find.byWidgetPredicate(
        (Widget w) =>
            w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      );
      expect(
        horizontalScrollView,
        findsOneWidget,
        reason:
            'SPEC § Layout / wireframe: the DataTable MUST live '
            'inside a horizontal SingleChildScrollView at narrow '
            'widths so the wide table stays reachable without '
            'horizontal RenderFlex overflow.',
      );
      expect(
        find.byType(Scrollbar),
        findsWidgets,
        reason:
            'SPEC § Layout / wireframe: the Scrollbar wrapping the '
            'horizontal scroll viewport MUST mount at 320 dp so the '
            'scroll affordance is visible to the user (per the '
            'dialog state\'s `thumbVisibility: true`).',
      );
    });
  });
}
