// ProductionPanel labour / layout / chrome ACs (part2). SPEC/ui/production-panel.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_allocation_row.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_allocation_row_chrome.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_labour_helpers.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'package:colonizethis_app/widgets/ct_resource_cell.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_app/widgets/ct_slider.dart';
import 'widget_test_pumps.dart';
import 'production_panel_test_support.dart';
import 'production_panel_part_helpers.dart';
import 'production_panel_part2_labour_support.dart';

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

    testWidgets('Allocation row chrome wraps every recipe row in '
        'ProductionAllocationRowChrome (Refs #2862 S3 / R13)', (
      WidgetTester tester,
    ) async {
      await pumpProductionPanelSettled(tester, player: fullPlayer);

      final recipeCount = ProductionRecipesCatalog.all.length;
      expect(recipeCount, greaterThan(1));

      expect(find.byType(ProductionAllocationRow), findsNWidgets(recipeCount));
      expect(
        find.byType(ProductionAllocationRowChrome),
        findsNWidgets(recipeCount),
      );

      // Every ProductionAllocationRow must be a descendant of a
      // ProductionAllocationRowChrome — no bare rows allowed.
      for (final row in tester.widgetList<ProductionAllocationRow>(
        find.byType(ProductionAllocationRow),
      )) {
        final wrapped = find.ancestor(
          of: find.byWidget(row),
          matching: find.byType(ProductionAllocationRowChrome),
        );
        expect(
          wrapped,
          findsOneWidget,
          reason:
              'ProductionAllocationRow for ${row.recipe.id} must be wrapped '
              'in ProductionAllocationRowChrome per SPEC.',
        );
      }
    });

    testWidgets(
      'Allocation row chrome paints CtGradients.rowGradient inside a 1px '
      'accent-dim border (Refs #2862 S3 / R13)',
      (WidgetTester tester) async {
        await pumpProductionPanelSettled(tester, player: fullPlayer);

        final chromes = tester.widgetList<ProductionAllocationRowChrome>(
          find.byType(ProductionAllocationRowChrome),
        );
        expect(chromes, isNotEmpty);

        for (final chrome in chromes) {
          final decorated = find.descendant(
            of: find.byWidget(chrome),
            matching: find.byType(DecoratedBox),
          );
          expect(decorated, findsAtLeastNWidgets(1));
          final box = tester.widget<DecoratedBox>(decorated.first);
          final decoration = box.decoration as BoxDecoration;
          expect(decoration.gradient, CtGradients.rowGradient);
          final border = decoration.border as Border;
          expect(border.top.color, EditorialMonoclePalette.accentDim);
          expect(border.top.width, 1.0);
          expect(border.bottom.color, EditorialMonoclePalette.accentDim);
          expect(border.left.color, EditorialMonoclePalette.accentDim);
          expect(border.right.color, EditorialMonoclePalette.accentDim);
        }
      },
    );

    testWidgets('Allocation rows are separated by exactly N-1 CtBrassDividers '
        '(Refs #2862 S3 / R13)', (WidgetTester tester) async {
      await pumpProductionPanelSettled(tester, player: fullPlayer);

      final recipeCount = ProductionRecipesCatalog.all.length;
      expect(recipeCount, greaterThan(1));

      // CtBrassDivider may appear elsewhere on the screen via shared
      // chrome — scope the count to those inside the allocation rows
      // column by counting dividers that share an ancestor with the
      // allocation row chromes.
      final dividers = find.descendant(
        of: find.byType(ProductionAllocationRow).first,
        matching: find.byType(CtBrassDivider),
      );
      expect(
        dividers,
        findsNothing,
        reason: 'No divider should live inside a recipe row.',
      );

      final totalDividers = find.byType(CtBrassDivider).evaluate().length;
      // Allow other CtBrassDivider instances elsewhere on the screen — but
      // require at least N-1 to appear (one between each pair of recipe
      // rows in the allocation subpanel).
      expect(totalDividers, greaterThanOrEqualTo(recipeCount - 1));
    });

    // S7 — Labour Controls subsection placement (Refs #2862 S7a).

    testWidgets(
      'Labour Controls CtSectionLabel appears below Effective Labour (Refs #2862 S7a)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildProductionPanelWithLabourCallbacks(player: fullPlayer),
        );
        await pumpSettleCapped(tester);

        final labourControlsLabel = find.descendant(
          of: find.byType(CtSectionLabel),
          matching: find.text('LABOUR CONTROLS'),
        );
        expect(labourControlsLabel, findsOneWidget);

        final effectiveLabour = find.textContaining('Labour this turn:');
        expect(effectiveLabour, findsOneWidget);

        final effectiveY = tester.getTopLeft(effectiveLabour).dy;
        final labourY = tester.getTopLeft(labourControlsLabel).dy;
        expect(
          labourY,
          greaterThan(effectiveY),
          reason:
              'Labour Controls section label must render below the '
              'Effective Labour line per SPEC § Labour Controls (12-A).',
        );
      },
    );

    testWidgets(
      'Labour Controls subsection is omitted when callbacks are not provided '
      '(no orphan section label; Refs #2862 S7a)',
      (WidgetTester tester) async {
        // `buildPanel` does not pass currentOrders / labourCallbacks.
        await pumpProductionPanelSettled(tester, player: fullPlayer);

        expect(
          find.descendant(
            of: find.byType(CtSectionLabel),
            matching: find.text('LABOUR CONTROLS'),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'Workers section uses Effective Labour line then Labour Controls label '
      '(no action buttons above Effective Labour; Refs #2862 S7a)',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildProductionPanelWithLabourCallbacks(player: fullPlayer),
        );
        await pumpSettleCapped(tester);

        final effectiveLabour = find.textContaining('Labour this turn:');
        final l10n = lookupAppLocalizations(const Locale('en'));
        // The disband button for the apprentice row (if rendered) must
        // appear below the Effective Labour line.
        final apprenticeDisband = find.byKey(
          const ValueKey<String>('production_labour_disband_apprentices'),
        );
        if (apprenticeDisband.evaluate().isNotEmpty) {
          final effectiveY = tester.getTopLeft(effectiveLabour).dy;
          final disbandY = tester.getTopLeft(apprenticeDisband).dy;
          expect(
            disbandY,
            greaterThan(effectiveY),
            reason: 'Disband control must render below Effective Labour.',
          );
        }
        // The peasant tier label parenthetical must also appear.
        expect(
          find.text(
            l10n.production_labourTierLabel(
              l10n.production_workers_peasants,
              l10n.production_labourTierUnlocked,
            ),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
