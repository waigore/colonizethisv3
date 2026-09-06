// Industry counsel stars on Production Allocation rows. SPEC/ui/production-panel.md.
// Semantics/read-only: production_industry_counsel_stars_semantics_test.dart.

import 'package:colonizethis_app_fixtures/demo/production_panel_demo_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/production/production_industry_counsel_star.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'production_industry_counsel_stars_support.dart';
import 'production_panel_test_support.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  late Player fullPlayer;

  setUpAll(() {
    fullPlayer = productionPanelTestFullPlayer();
  });

  group('Production industry counsel stars', () {
    testWidgets('shows zero stars when ranking map is empty', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildProductionPanel(
          player: fullPlayer,
          onOpenCounsel: ({String? highlightRecommendationId}) {},
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.byType(ProductionIndustryCounselStar), findsNothing);
      expect(
        find.byKey(const ValueKey<String>('production_allocation_counsel_button')),
        findsOneWidget,
      );
    });

    testWidgets('shows stars only on starred produce recipe rows', (
      WidgetTester tester,
    ) async {
      const starredRecipeIds = ['lumber_from_timber', 'paper_from_timber'];
      await tester.pumpWidget(
        buildProductionPanel(
          player: fullPlayer,
          starredProduceRecommendationsByRecipeId: {
            for (final recipeId in starredRecipeIds)
              recipeId: productionIndustryCounselProduceRecommendation(recipeId),
          },
          onOpenCounsel: ({String? highlightRecommendationId}) {},
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.byType(ProductionIndustryCounselStar), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('production_alloc_row_chrome_castIron_from_iron'),
          ),
          matching: find.byType(ProductionIndustryCounselStar),
        ),
        findsNothing,
      );
    });

    testWidgets('shows exactly three stars when three produce recipes ranked', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildProductionPanel(
          player: fullPlayer,
          starredProduceRecommendationsByRecipeId: {
            for (final recipeId in productionIndustryCounselThreeStarRecipeIds)
              recipeId: productionIndustryCounselProduceRecommendation(recipeId),
          },
          onOpenCounsel: ({String? highlightRecommendationId}) {},
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.byType(ProductionIndustryCounselStar), findsNWidgets(3));
    });

    testWidgets('star tap forwards highlight recommendation id', (
      WidgetTester tester,
    ) async {
      String? openedHighlightId;
      await tester.pumpWidget(
        buildProductionPanel(
          player: fullPlayer,
          starredProduceRecommendationsByRecipeId: {
            'lumber_from_timber':
                productionIndustryCounselProduceRecommendation(
                  'lumber_from_timber',
                ),
          },
          onOpenCounsel: ({String? highlightRecommendationId}) {
            openedHighlightId = highlightRecommendationId;
          },
        ),
      );
      await pumpSettleCapped(tester);

      final star = find.byKey(productionIndustryCounselLumberStarKey);
      await tester.ensureVisible(star);
      await tester.tap(star);
      await pumpSettleCapped(tester);

      expect(openedHighlightId, 'produce:lumber_from_timber');
    });

    testWidgets('header Counsel opens without forced highlight', (
      WidgetTester tester,
    ) async {
      String? openedHighlightId = 'preset';
      await tester.pumpWidget(
        buildProductionPanel(
          player: fullPlayer,
          onOpenCounsel: ({String? highlightRecommendationId}) {
            openedHighlightId = highlightRecommendationId;
          },
        ),
      );
      await pumpSettleCapped(tester);

      await tester.tap(
        find.widgetWithText(CtActionTextButton, 'Counsel'),
      );
      await pumpSettleCapped(tester);

      expect(openedHighlightId, isNull);
    });

    testWidgets('locked recipe never shows counsel star', (
      WidgetTester tester,
    ) async {
      final lockedPlayer = cottonWeavingLockedProductionPlayer();
      await tester.pumpWidget(
        buildProductionPanel(
          player: lockedPlayer,
          starredProduceRecommendationsByRecipeId: {
            'fabric_from_cotton':
                productionIndustryCounselProduceRecommendation(
                  'fabric_from_cotton',
                ),
          },
          onOpenCounsel: ({String? highlightRecommendationId}) {},
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.byType(ProductionIndustryCounselStar), findsNothing);
      expect(find.textContaining('(locked)'), findsOneWidget);
    });
  });
}
