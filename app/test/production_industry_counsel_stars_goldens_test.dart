// Visual goldens for Production Allocation industry counsel stars (#4190).
// SPEC/ui/production-panel.md § Industry counsel stars.

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/production/production_industry_counsel_star.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_panel.dart';

import 'golden_capture_harness.dart';
import 'panel_fixtures/production.dart';
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

  testWidgets('golden: allocation stars on two recommended recipes (#4190)', (
    WidgetTester tester,
  ) async {
    final player = productionPanelTestFullPlayer();
    final game = productionPanelTestGameFor(player);
    const boundaryKey = ValueKey('production_industry_counsel_stars_golden');

    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(900, 780),
      includeLocalizations: true,
      child: ProductionPanel(
        game: game,
        player: player,
        desiredOutputByRecipe: const {},
        netDeltasByCommodity: const {},
        labourReadiness: labourReadinessForPlayer(player),
        onDesiredOutputChanged: (_) {},
        starredProduceRecommendationsByRecipeId: {
          'lumber_from_timber': _produceRecommendation('lumber_from_timber'),
          'paper_from_timber': _produceRecommendation('paper_from_timber'),
        },
        onOpenCounsel: ({String? highlightRecommendationId}) {},
      ),
    );
    await pumpSettleCapped(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(ProductionIndustryCounselStar), findsNWidgets(2));

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/production_industry_counsel_stars_two.png'),
    );
  });

  testWidgets('golden: allocation shows zero stars when ranking empty (#4190)', (
    WidgetTester tester,
  ) async {
    final player = productionPanelTestFullPlayer();
    final game = productionPanelTestGameFor(player);
    const boundaryKey =
        ValueKey('production_industry_counsel_stars_empty_golden');

    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(900, 780),
      includeLocalizations: true,
      child: ProductionPanel(
        game: game,
        player: player,
        desiredOutputByRecipe: const {},
        netDeltasByCommodity: const {},
        labourReadiness: labourReadinessForPlayer(player),
        onDesiredOutputChanged: (_) {},
        onOpenCounsel: ({String? highlightRecommendationId}) {},
      ),
    );
    await pumpSettleCapped(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(ProductionIndustryCounselStar), findsNothing);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/production_industry_counsel_stars_empty.png'),
    );
  });
}
