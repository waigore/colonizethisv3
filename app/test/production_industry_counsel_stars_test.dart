// Industry counsel stars on Production Allocation rows. SPEC/ui/production-panel.md.

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/production/production_industry_counsel_star.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app_fixtures/demo/production_panel_demo_data.dart';
import 'production_panel_test_support.dart';
import 'widget_test_pumps.dart';

IndustryCounselRecommendation _produceRecommendation(String recipeId) {
  return IndustryCounselRecommendation(
    recommendationId: 'produce:$recipeId',
    kind: IndustryCounselRecommendationKind.produceRecipe,
    rankScore: 20,
    briefReasonKey: IndustryCounselReasonKey.outputShortage,
    detailReasonKeys: const [IndustryCounselReasonKey.outputShortage],
    recipeId: recipeId,
    suggestedDesiredOutput: 2,
  );
}

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
              recipeId: _produceRecommendation(recipeId),
          },
          onOpenCounsel: ({String? highlightRecommendationId}) {},
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.byType(ProductionIndustryCounselStar), findsNWidgets(2));
    });

    testWidgets('star tap forwards highlight recommendation id', (
      WidgetTester tester,
    ) async {
      String? openedHighlightId;
      await tester.pumpWidget(
        buildProductionPanel(
          player: fullPlayer,
          starredProduceRecommendationsByRecipeId: {
            'lumber_from_timber': _produceRecommendation('lumber_from_timber'),
          },
          onOpenCounsel: ({String? highlightRecommendationId}) {
            openedHighlightId = highlightRecommendationId;
          },
        ),
      );
      await pumpSettleCapped(tester);

      await tester.tap(find.byType(ProductionIndustryCounselStar));
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
            'fabric_from_cotton': _produceRecommendation('fabric_from_cotton'),
          },
          onOpenCounsel: ({String? highlightRecommendationId}) {},
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.byType(ProductionIndustryCounselStar), findsNothing);
      expect(find.textContaining('(locked)'), findsOneWidget);
    });

    testWidgets('star exposes semantic label with brief reason', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildProductionPanel(
          player: fullPlayer,
          starredProduceRecommendationsByRecipeId: {
            'lumber_from_timber': _produceRecommendation('lumber_from_timber'),
          },
          onOpenCounsel: ({String? highlightRecommendationId}) {},
        ),
      );
      await pumpSettleCapped(tester);

      final semantics = tester.getSemantics(
        find.byKey(const ValueKey<String>('production_industry_counsel_star')),
      );
      expect(
        semantics.label,
        contains('Your stocks of this output are low'),
      );
    });
  });
}
