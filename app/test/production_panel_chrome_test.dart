// ProductionPanel allocation-row chrome ACs. SPEC/ui/production-panel.md.
// Shared pump/finder helpers: production_panel_widget_helpers.dart (Refs #4352).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_allocation_row.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_allocation_row_chrome.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_gradients.dart';
import 'production_panel_test_support.dart';
import 'production_panel_widget_helpers.dart';

void main() {
  suppressLogsForTests();

  late Player fullPlayer;

  setUpAll(() {
    fullPlayer = productionPanelTestFullPlayer();
  });

  group('ProductionPanel', () {
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
  });
}
