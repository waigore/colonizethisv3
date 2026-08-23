// ProductionPanel remaining allocation/layout ACs (Refs #4606 Slice D).
// SPEC/ui/production-panel.md. Host: production_panel_available_and_allocation_test.dart.
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

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

  group('ProductionPanel allocation and layout', () {
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
