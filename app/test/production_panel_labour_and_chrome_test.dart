// ProductionPanel labour / layout ACs. SPEC/ui/production-panel.md.
// Shared pump/finder helpers: production_panel_widget_helpers.dart (Refs #4352).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/widgets/ct_resource_cell.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'widget_test_pumps.dart';
import 'production_panel_test_support.dart';
import 'production_panel_widget_helpers.dart';
import 'production_panel_labour_support.dart';

void main() {
  suppressLogsForTests();

  late Player fullPlayer;
  late Player partialPlayer;

  setUpAll(() {
    fullPlayer = productionPanelTestFullPlayer();
    partialPlayer = productionPanelTestPartialPlayer();
  });

  group('ProductionPanel', () {
    testWidgets('Total labour displayed', (WidgetTester tester) async {
      await pumpProductionPanelSettled(tester, player: fullPlayer);

      expect(find.textContaining('Total labour:'), findsOneWidget);
    });

    testWidgets('Net changes shown when allocations exist', (
      WidgetTester tester,
    ) async {
      await pumpProductionPanelSettled(
        tester,
        player: fullPlayer,
        gameOverride: productionPanelIsolatedGame(
          fullPlayer,
          id: 'production-panel-net',
        ),
        desiredOutputByRecipe: {'lumber_from_timber': 5},
      );

      expect(find.text('Timber'), findsOneWidget);
      expect(find.text('-10'), findsOneWidget);
      expect(find.text('Lumber'), findsOneWidget);
      expect(find.text('+5'), findsOneWidget);
    });

    testWidgets('Partial availability: sliders capped by achievable runs', (
      WidgetTester tester,
    ) async {
      await pumpProductionPanelSettled(tester, player: partialPlayer);

      expect(
        find.byType(CtSlider),
        findsNWidgets(ProductionRecipesCatalog.all.length),
      );
      expect(find.text('Available'), findsOneWidget);
      expect(find.textContaining('Labour this turn: 2'), findsOneWidget);
    });

    testWidgets(
      'Over-allocating labour shows insufficient labour warning in summary',
      (WidgetTester tester) async {
        await pumpProductionPanelSettled(
          tester,
          player: fullPlayer,
          desiredOutputByRecipe: {'lumber_from_timber': 999},
        );

        // Summary line should turn into an error-coloured warning with explanatory text.
        expect(find.textContaining('Total labour:'), findsOneWidget);
        expect(
          find.text(
            'Insufficient labour — production will be capped next turn',
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Unknown recipe ids are ignored when computing total labour (no warning)',
      (WidgetTester tester) async {
        await pumpProductionPanelSettled(
          tester,
          player: fullPlayer,
          desiredOutputByRecipe: {'definitely_not_a_recipe_id': 5},
        );

        expect(find.textContaining('Total labour:'), findsOneWidget);
        expect(
          find.text(
            'Insufficient labour — production will be capped next turn',
          ),
          findsNothing,
        );
      },
    );

    testWidgets('Recipe labels show output with inputs in parentheses', (
      WidgetTester tester,
    ) async {
      await pumpProductionPanelSettled(tester, player: fullPlayer);

      expect(find.textContaining('('), findsWidgets);
      expect(find.textContaining('Lumber'), findsWidgets);
      expect(find.textContaining('Fabric'), findsWidgets);
    });

    testWidgets(
      'Available section labels use CtSectionLabel for Food / Raw Materials / '
      'Manufactured / Workers (Refs #2862 S2)',
      (WidgetTester tester) async {
        await pumpProductionPanelSettled(tester, player: fullPlayer);

        Finder labelWithText(String text) => find.descendant(
          of: find.byType(CtSectionLabel),
          matching: find.text(text),
        );
        expect(labelWithText('FOOD'), findsOneWidget);
        expect(labelWithText('RAW MATERIALS'), findsOneWidget);
        expect(labelWithText('MANUFACTURED'), findsOneWidget);
        expect(labelWithText('WORKERS'), findsOneWidget);
      },
    );

    testWidgets(
      'Available commodity cells use CtResourceCell with sign-prefixed '
      'positive deltas (Refs #2862 S2)',
      (WidgetTester tester) async {
        await pumpProductionPanelSettled(
          tester,
          player: fullPlayer,
          gameOverride: productionPanelIsolatedGame(
            fullPlayer,
            id: 'production-panel-dark-positive',
          ),
          desiredOutputByRecipe: {'lumber_from_timber': 2},
        );

        final lumberCell = find.byKey(
          const ValueKey<String>('production_available_cell_lumber'),
        );
        expect(lumberCell, findsOneWidget);
        expect(
          find.descendant(of: lumberCell, matching: find.text('Lumber')),
          findsOneWidget,
        );
        expect(
          find.descendant(of: lumberCell, matching: find.text('+2')),
          findsOneWidget,
        );
      },
    );

    testWidgets('Available commodity quantity subtracts staged trade offers '
        '(Refs #3093)', (WidgetTester tester) async {
      await tester.pumpWidget(
        buildProductionPanel(
          player: fullPlayer,
          currentOrders: productionPanelFabricOfferOrders(fullPlayer),
        ),
      );
      await pumpSettleCapped(tester);

      final fabricCell = find.byKey(
        const ValueKey<String>('production_available_cell_fabric'),
      );
      expect(fabricCell, findsOneWidget);
      final cellWidget = tester.widget<CtResourceCell>(fabricCell);
      expect(cellWidget.quantity, 46);
    });

    testWidgets(
      'Available commodity cells omit delta region when net change is zero '
      '(Refs #2862 S2)',
      (WidgetTester tester) async {
        await pumpProductionPanelSettled(tester, player: fullPlayer);

        final timberCell = find.byKey(
          const ValueKey<String>('production_available_cell_timber'),
        );
        expect(timberCell, findsOneWidget);
        final cellWidget = tester.widget<CtResourceCell>(timberCell);
        expect(cellWidget.delta, isNull);
      },
    );

    testWidgets('Workers section renders one CtResourceCell per worker tier '
        '(Refs #2862 S2)', (WidgetTester tester) async {
      await pumpProductionPanelSettled(tester, player: fullPlayer);

      for (final tier in const <String>[
        'peasant',
        'apprentice',
        'journeyman',
        'master',
      ]) {
        expect(
          find.byKey(ValueKey<String>('production_available_worker_$tier')),
          findsOneWidget,
          reason: 'Worker cell for $tier should be present',
        );
      }
    });
  });
}
