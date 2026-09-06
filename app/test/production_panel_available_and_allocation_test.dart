// ProductionPanel available / allocation ACs. SPEC/ui/production-panel.md.
// Allocation controls: production_panel_allocation_controls_test.dart.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_resource_cell.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'production_panel_widget_helpers.dart';
import 'production_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  late Player fullPlayer;

  setUpAll(() {
    fullPlayer = productionPanelTestFullPlayer();
  });

  group('ProductionPanel', () {
    testWidgets('Available header has no Breakdown button without callback', (
      WidgetTester tester,
    ) async {
      await pumpProductionPanelSettled(tester, player: fullPlayer);
      expect(find.text('Breakdown'), findsNothing);
    });

    testWidgets(
      'Available header shows Breakdown text button when callback set',
      (WidgetTester tester) async {
        await pumpProductionPanelSettled(
          tester,
          player: fullPlayer,
          onOpenCommodityBreakdown: () {},
        );
        expect(find.text('Breakdown'), findsOneWidget);
      },
    );

    testWidgets(
      'Available header Breakdown renders as CtActionTextButton (Refs #2862 S10b / C11)',
      (WidgetTester tester) async {
        await pumpProductionPanelSettled(
          tester,
          player: fullPlayer,
          onOpenCommodityBreakdown: () {},
        );

        final breakdownFinder = find.widgetWithText(
          CtActionTextButton,
          'Breakdown',
        );
        expect(breakdownFinder, findsOneWidget);
        final breakdown = tester.widget<CtActionTextButton>(breakdownFinder);
        expect(breakdown.label, 'Breakdown');
        expect(breakdown.onPressed, isNotNull);
        expect(breakdown.enabled, isTrue);
      },
    );

    testWidgets(
      'negative: Available header Breakdown does not render as CtNinePatchButton '
      '(Refs #2862 S10b / C11)',
      (WidgetTester tester) async {
        await pumpProductionPanelSettled(
          tester,
          player: fullPlayer,
          onOpenCommodityBreakdown: () {},
        );

        expect(
          productionNinePatchLabeled('Breakdown'),
          findsNothing,
          reason: 'Breakdown must be CtActionTextButton (#2862 C11).',
        );
      },
    );

    testWidgets('Available subpanel shows commodity groups', (
      WidgetTester tester,
    ) async {
      await pumpProductionPanelSettled(tester, player: fullPlayer);

      expect(find.text('Available'), findsOneWidget);
      expect(find.byType(CtSectionLabel), findsAtLeastNWidgets(4));
      expect(find.text('FOOD'), findsOneWidget);
      expect(find.text('RAW MATERIALS'), findsOneWidget);
      expect(find.text('MANUFACTURED'), findsOneWidget);
      expect(find.text('WORKERS'), findsOneWidget);
      expect(find.textContaining('Labour this turn:'), findsOneWidget);
    });

    testWidgets('Available subpanel shows raw materials used as inputs', (
      WidgetTester tester,
    ) async {
      await pumpProductionPanelSettled(tester, player: fullPlayer);

      expect(find.byType(CtResourceCell), findsAtLeastNWidgets(3));
      expect(find.text('Timber'), findsOneWidget);
      expect(find.text('Iron'), findsOneWidget);
      expect(find.text('Coal'), findsOneWidget);
    });

    testWidgets('Allocation subpanel shows recipe labels with inputs', (
      WidgetTester tester,
    ) async {
      await pumpProductionPanelSettled(tester, player: fullPlayer);

      expect(find.text('Allocation'), findsOneWidget);
      expect(
        find.byType(CtSlider),
        findsNWidgets(ProductionRecipesCatalog.all.length),
      );
      expect(find.textContaining('Lumber'), findsWidgets);
      expect(find.textContaining('Fabric'), findsWidgets);
    });

    testWidgets(
      'normalized recipe labels show updated input quantities (Refs #3873)',
      (WidgetTester tester) async {
        await pumpProductionPanelSettled(tester, player: fullPlayer);

        expect(find.textContaining('Tobacco ×2'), findsOneWidget);
        expect(find.textContaining('Timber ×2'), findsAtLeastNWidgets(2));
        expect(find.textContaining('Iron ×1, Coal ×1'), findsOneWidget);
        expect(find.textContaining('×3'), findsNothing);
        expect(find.textContaining('Cast Iron'), findsNothing);
      },
    );

    testWidgets(
      'Full availability: sliders enable comfort headroom at default allocation',
      (WidgetTester tester) async {
        await pumpProductionPanelSettled(tester, player: fullPlayer);

        final sliders = tester
            .widgetList<CtSlider>(find.byType(CtSlider))
            .toList();
        expect(sliders, isNotEmpty);
        expect(sliders.every((s) => s.comfortHeadroomActive), isTrue);
      },
    );
  });
}
