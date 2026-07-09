// Compact pending-riches build suggestion assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_build_pending_riches_fixtures.dart';

/// Pins for [suggestBuildOrdersPendingRichesTreasuryScenarios] rows.
enum OrderSuggestionBuildPendingRichesTarget {
  acceptsPeasantLeviesWithRichesStockpile,
  incrementalProbeMatchesFullPass,
}

void runOrderSuggestionBuildPendingRichesExpectation(
  OrderSuggestionBuildPendingRichesTarget target,
) {
  switch (target) {
    case OrderSuggestionBuildPendingRichesTarget.acceptsPeasantLeviesWithRichesStockpile:
      final game = orderSuggestionBuildPendingRichesGame();
      final view = buildPlayerView(
        game,
        orderSuggestionBuildPendingRichesTopology,
        orderSuggestionBuildPendingRichesPlayerId,
      );

      final suggestions = suggestBuildOrders(
        view,
        game,
        orderSuggestionBuildPendingRichesTopology,
        const Orders(),
      );

      expect(
        suggestions.map((o) => o.unitType),
        contains('peasant_levies'),
      );

    case OrderSuggestionBuildPendingRichesTarget.incrementalProbeMatchesFullPass:
      final game = orderSuggestionBuildPendingRichesGame();
      const basePrefix = Orders();
      const candidate = BuildUnitOrder(
        unitType: 'peasant_levies',
        isMilitary: true,
        spawnProvinceId: orderSuggestionBuildPendingRichesProvinceId,
      );

      final incremental = IncrementalCandidateValidator.forPlayer(
        game: game,
        topology: orderSuggestionBuildPendingRichesTopology,
        playerId: orderSuggestionBuildPendingRichesPlayerId,
        basePrefix: basePrefix,
      );
      final engine = OrderEngine(initialOrders: basePrefix);
      final fullPass = engine
          .addBuildOrderWithContext(
            game,
            orderSuggestionBuildPendingRichesTopology,
            orderSuggestionBuildPendingRichesPlayerId,
            candidate,
          )
          .isAccepted;

      expect(incremental.isBuildAccepted(candidate), fullPass);
      expect(incremental.isBuildAccepted(candidate), isTrue);
  }
}
