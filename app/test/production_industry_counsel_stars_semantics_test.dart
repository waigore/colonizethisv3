// Industry counsel star semantics, tooltip, and read-only chrome (Refs #4734 Slice G).
// Visibility/interaction: production_industry_counsel_stars_test.dart.

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

  group('Production industry counsel stars — semantics (Refs #4734 Slice G)', () {
    testWidgets('star exposes semantic label with brief reason', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildProductionPanel(
          player: fullPlayer,
          starredProduceRecommendationsByRecipeId: {
            'lumber_from_timber':
                productionIndustryCounselProduceRecommendation(
                  'lumber_from_timber',
                ),
          },
          onOpenCounsel: ({String? highlightRecommendationId}) {},
        ),
      );
      await pumpSettleCapped(tester);

      final semantics = tester.getSemantics(
        find.byKey(productionIndustryCounselLumberStarKey),
      );
      expect(
        semantics.label,
        contains('Your stocks of this output are low'),
      );
    });

    testWidgets('star tooltip shows localized brief reason', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildProductionPanel(
          player: fullPlayer,
          starredProduceRecommendationsByRecipeId: {
            'lumber_from_timber':
                productionIndustryCounselProduceRecommendation(
                  'lumber_from_timber',
                ),
          },
          onOpenCounsel: ({String? highlightRecommendationId}) {},
        ),
      );
      await pumpSettleCapped(tester);

      final tooltip = tester.widget<Tooltip>(
        find.descendant(
          of: find.byType(ProductionIndustryCounselStar),
          matching: find.byType(Tooltip),
        ),
      );
      expect(tooltip.message, startsWith('Your stocks of this output are low'));
    });

    testWidgets('star remains when player allocation already matches AI plan', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        buildProductionPanel(
          player: fullPlayer,
          desiredOutputByRecipe: const {'lumber_from_timber': 2},
          starredProduceRecommendationsByRecipeId: {
            'lumber_from_timber':
                productionIndustryCounselProduceRecommendation(
                  'lumber_from_timber',
                  suggestedDesiredOutput: 2,
                ),
          },
          onOpenCounsel: ({String? highlightRecommendationId}) {},
        ),
      );
      await pumpSettleCapped(tester);

      expect(find.byType(ProductionIndustryCounselStar), findsOneWidget);
    });

    testWidgets('read-only allocation keeps stars and counsel navigation', (
      WidgetTester tester,
    ) async {
      String? openedHighlightId;
      await tester.pumpWidget(
        buildProductionPanel(
          player: fullPlayer,
          canEditLabour: false,
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

      expect(find.byType(ProductionIndustryCounselStar), findsOneWidget);

      final star = find.byKey(productionIndustryCounselLumberStarKey);
      await tester.ensureVisible(star);
      await tester.tap(star);
      await pumpSettleCapped(tester);
      expect(openedHighlightId, 'produce:lumber_from_timber');

      final counselButton = find.widgetWithText(CtActionTextButton, 'Counsel');
      await tester.ensureVisible(counselButton);
      await tester.tap(counselButton);
      await pumpSettleCapped(tester);
      expect(openedHighlightId, isNull);
    });
  });
}
