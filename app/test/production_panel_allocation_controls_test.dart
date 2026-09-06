// ProductionPanel allocation Reset / increment / decrement controls.
// Available chrome: production_panel_available_and_allocation_test.dart.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_danger_text_button.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'production_panel_test_support.dart';
import 'production_panel_widget_helpers.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  late Player fullPlayer;

  setUpAll(() {
    fullPlayer = productionPanelTestFullPlayer();
  });

  group('ProductionPanel allocation controls (Refs #4734 Slice G)', () {
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
      'negative: production panel does not render Reset as CtNinePatchButton '
      '(Refs #2862 S8d / C8)',
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
  });
}
