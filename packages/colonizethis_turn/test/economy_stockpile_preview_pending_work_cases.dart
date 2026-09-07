// Pending-work and combined preview cases (Refs #4740 Slice C).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

import 'economy_stockpile_preview_cases.dart';
import 'support/economy_stockpile_preview_pending_work_aggregation_scenarios.dart';
import 'support/economy_stockpile_preview_pending_work_scenarios.dart';
import 'support/economy_stockpile_preview_test_support.dart';

void registerEconomyStockpilePreviewPendingWorkCases() {
  group('pending material-backed work targets', () {
    test(
      'deducts each supported target in pending build costs phase',
      runPendingWorkTargetDeductionScenarios,
    );

    test(
      'mixed target list aggregates and keeps sequential affordability',
      runMixedWorkTargetAggregationScenario,
    );

    test(
      'later order does not deduct when earlier orders consume affordability',
      runSequentialAffordabilityScenario,
    );

    test(
      'skips target when unit missing busy disallowed invalid tile or unaffordable',
      runPendingWorkTargetSkipScenarios,
    );
  });

  test('combined: extraction + riches + consumption + production', () {
    final game = economyPreviewCombinedScenarioGame();
    final delta = previewStockpileNetDeltaByCommodityForPlayer(
      game: game,
      topology: const MapTopology(),
      playerId: 'p1',
      inputs: economyPreviewInputs(
        extractedByPlayerId: {
          'p1': {CommodityCatalog.grain.id: 5},
        },
        defaultAssignmentsByPlayerId: {
          'p1': const [
            AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 4),
          ],
        },
      ),
    );
    expect(delta[CommodityCatalog.gems.id], -1);
    expect(delta[CommodityCatalog.timber.id], -2);
    expect(delta[CommodityCatalog.lumber.id], 1);
    expect(delta[CommodityCatalog.grain.id], 2);
    expectPhaseDeltasSumToNet(
      game: game,
      playerId: 'p1',
      extractedByPlayerId: {
        'p1': {CommodityCatalog.grain.id: 5},
      },
      defaultAssignmentsByPlayerId: {
        'p1': const [
          AssignedRecipe(recipeId: 'lumber_from_timber', assignedLabour: 4),
        ],
      },
    );
  });
}
