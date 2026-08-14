// ProductionPanel available / allocation ACs. SPEC/ui/production-panel.md.
// Shared pump/finder helpers: production_panel_widget_helpers.dart (Refs #4352).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_danger_text_button.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_resource_cell.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'widget_test_pumps.dart';
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
      'Allocation rows show right-aligned affordance max · bottleneck',
      (WidgetTester tester) async {
        await pumpProductionPanelSettled(tester, player: fullPlayer);

        expect(
          find.textContaining('·'),
          findsAtLeastNWidgets(ProductionRecipesCatalog.all.length),
        );
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

    testWidgets('Reset button clears all allocations', (
      WidgetTester tester,
    ) async {
      Map<String, int>? lastOutput;
      await pumpProductionPanelSettled(
        tester,
        player: fullPlayer,
        desiredOutputByRecipe: {'lumber_from_timber': 5},
        onDesiredOutputChanged: (next) => lastOutput = Map.from(next),
      );

      final resetFinder = find.byKey(
        const ValueKey<String>('production_allocation_reset_button'),
      );
      expect(resetFinder, findsOneWidget);
      expect(
        find.descendant(of: resetFinder, matching: find.text('Reset')),
        findsOneWidget,
      );
      await tester.tap(resetFinder);
      await pumpSyncFrames(tester);

      expect(lastOutput, isNotNull);
      expect(lastOutput!.isEmpty, isTrue);
    });

    testWidgets(
      'Allocation header Reset renders as CtDangerTextButton (Refs #2862 S8d / C8)',
      (WidgetTester tester) async {
        await pumpProductionPanelSettled(tester, player: fullPlayer);

        final resetFinder = find.byKey(
          const ValueKey<String>('production_allocation_reset_button'),
        );
        expect(resetFinder, findsOneWidget);

        final reset = tester.widget<CtDangerTextButton>(resetFinder);
        expect(reset.label, 'Reset');
        expect(reset.tooltip, 'Reset');
        expect(reset.enabled, isTrue);
        expect(reset.onPressed, isNotNull);

        expect(
          find.descendant(
            of: resetFinder,
            matching: find.byType(CtNinePatchButton),
          ),
          findsNothing,
          reason: 'Reset must not fall back to CtNinePatchButton chrome.',
        );
      },
    );

    testWidgets(
      'negative: production panel does not render Reset as CtNinePatchButton (Refs #2862 S8d / C8)',
      (WidgetTester tester) async {
        await pumpProductionPanelSettled(tester, player: fullPlayer);

        expect(
          productionNinePatchLabeled('Reset'),
          findsNothing,
          reason: 'Reset must be CtDangerTextButton (#2862 C8).',
        );
      },
    );

    testWidgets('allocation increment tap adds one to first recipe', (
      WidgetTester tester,
    ) async {
      Map<String, int>? lastOutput;
      final firstId = ProductionRecipesCatalog.all.first.id;
      await pumpProductionPanelSettled(
        tester,
        player: fullPlayer,
        onDesiredOutputChanged: (next) =>
            lastOutput = Map<String, int>.from(next),
      );
      final l10n = productionEnL10n();
      await tester.tap(
        find.bySemanticsLabel(l10n.production_allocationIncrementRecipe).first,
      );
      await pumpSyncFrames(tester);
      expect(lastOutput, isNotNull);
      expect(lastOutput![firstId], 1);
    });

    testWidgets('allocation decrement subtracts one for lumber recipe', (
      WidgetTester tester,
    ) async {
      Map<String, int>? lastOutput;
      const lumberId = 'lumber_from_timber';
      final lumberIndex = productionRecipeIndex(lumberId);
      final l10n = productionEnL10n();
      await pumpProductionPanelSettled(
        tester,
        player: fullPlayer,
        desiredOutputByRecipe: const {lumberId: 3},
        onDesiredOutputChanged: (next) =>
            lastOutput = Map<String, int>.from(next),
      );
      await tapProductionAllocationSemantic(
        tester,
        semanticLabel: l10n.production_allocationDecrementRecipe,
        recipeIndex: lumberIndex,
      );
      expect(lastOutput, isNotNull);
      expect(lastOutput![lumberId], 2);
    });

    testWidgets('allocation clear removes recipe key', (
      WidgetTester tester,
    ) async {
      Map<String, int>? lastOutput;
      const lumberId = 'lumber_from_timber';
      final lumberIndex = productionRecipeIndex(lumberId);
      final l10n = productionEnL10n();
      await pumpProductionPanelSettled(
        tester,
        player: fullPlayer,
        desiredOutputByRecipe: const {lumberId: 4},
        onDesiredOutputChanged: (next) =>
            lastOutput = Map<String, int>.from(next),
      );
      await tapProductionAllocationSemantic(
        tester,
        semanticLabel: l10n.production_allocationClearRecipe,
        recipeIndex: lumberIndex,
      );
      expect(lastOutput, isNotNull);
      expect(lastOutput!.containsKey(lumberId), isFalse);
    });

    testWidgets('allocation maximize sets lumber to current max', (
      WidgetTester tester,
    ) async {
      Map<String, int>? lastOutput;
      const lumberId = 'lumber_from_timber';
      final lumberIndex = productionRecipeIndex(lumberId);
      final l10n = productionEnL10n();
      await pumpProductionPanelSettled(
        tester,
        player: fullPlayer,
        desiredOutputByRecipe: const {lumberId: 1},
        onDesiredOutputChanged: (next) =>
            lastOutput = Map<String, int>.from(next),
      );
      final expectedMax = expectedLumberMaxForPlayer(
        fullPlayer,
        currentDesired: 1,
      );
      await tapProductionAllocationSemantic(
        tester,
        semanticLabel: l10n.production_allocationMaximizeRecipe,
        recipeIndex: lumberIndex,
      );
      expect(lastOutput, isNotNull);
      expect(lastOutput![lumberId], expectedMax);
    });

    testWidgets(
      'allocation cross-row: lumber maxed disables cast iron increment',
      (WidgetTester tester) async {
        const castIronId = 'castIron_from_iron';
        final castIronIndex = productionRecipeIndex(castIronId);
        final l10n = productionEnL10n();
        await pumpProductionPanelSettled(
          tester,
          player: fullPlayer,
          desiredOutputByRecipe: const {'lumber_from_timber': 50},
        );
        final before = tester
            .widget<CtSlider>(find.byType(CtSlider).at(castIronIndex))
            .value;
        await tapProductionAllocationSemantic(
          tester,
          semanticLabel: l10n.production_allocationIncrementRecipe,
          recipeIndex: castIronIndex,
        );
        final after = tester
            .widget<CtSlider>(find.byType(CtSlider).at(castIronIndex))
            .value;
        expect(after, before);
      },
    );

    testWidgets('Moving slider calls onDesiredOutputChanged', (
      WidgetTester tester,
    ) async {
      Map<String, int>? lastOutput;
      await pumpProductionPanelSettled(
        tester,
        player: fullPlayer,
        onDesiredOutputChanged: (next) => lastOutput = Map.from(next),
      );

      final sliders = find.byType(CtSlider);
      expect(sliders, findsNWidgets(ProductionRecipesCatalog.all.length));
      await tester.drag(sliders.first, const Offset(80, 0));
      await pumpSyncFrames(tester);

      expect(lastOutput, isNotNull);
      expect(lastOutput!.values.any((v) => v > 0), isTrue);
    });

    testWidgets('Narrow viewport stacks subpanels and is scrollable', (
      WidgetTester tester,
    ) async {
      await pumpProductionPanelSettled(
        tester,
        player: fullPlayer,
        width: 400,
        height: 600,
      );

      expect(find.byType(SingleChildScrollView), findsAtLeastNWidgets(1));
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Allocation'), findsOneWidget);
    });

    testWidgets('Wide viewport shows subpanels in row', (
      WidgetTester tester,
    ) async {
      await pumpProductionPanelSettled(
        tester,
        player: fullPlayer,
        width: 800,
        height: 500,
      );

      expect(find.byType(Row), findsWidgets);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Allocation'), findsOneWidget);
    });
  });
}
