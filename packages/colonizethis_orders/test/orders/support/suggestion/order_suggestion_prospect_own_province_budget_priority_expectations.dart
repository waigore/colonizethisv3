// Compact own-province prospect budget priority assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_prospect_own_province_budget_priority_fixtures.dart';

/// Pins for [suggestWorkOrdersOwnProvinceProspectBudgetScenarios] rows.
enum OrderSuggestionProspectOwnProvinceBudgetPriorityTarget {
  coLocatedFeedstockReceivesProspectAfterBudgetDrain,
  noFeedstockProspectWhenAlreadyProspected,
  ownProvinceBudgetExemptionDeterministic,
}

void runOrderSuggestionProspectOwnProvinceBudgetPriorityExpectation(
  OrderSuggestionProspectOwnProvinceBudgetPriorityTarget target,
) {
  switch (target) {
    case OrderSuggestionProspectOwnProvinceBudgetPriorityTarget
        .coLocatedFeedstockReceivesProspectAfterBudgetDrain:
      final game = orderSuggestionProspectOwnProvinceBudgetPriorityGame();
      final topology =
          orderSuggestionProspectOwnProvinceBudgetPriorityTopology(game);
      final view = buildPlayerView(
        game,
        topology,
        orderSuggestionProspectOwnProvinceBudgetPriorityPlayerId,
      );
      final suggestions = suggestWorkOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      final prospects =
          orderSuggestionProspectOwnProvinceBudgetPriorityFeedstockProspects(
        suggestions,
      );
      expect(prospects, isNotEmpty);
      expect(
        prospects.map((o) => o.targetTileKey),
        contains(
          orderSuggestionProspectOwnProvinceBudgetPriorityFeedstockTileKey,
        ),
      );

    case OrderSuggestionProspectOwnProvinceBudgetPriorityTarget
        .noFeedstockProspectWhenAlreadyProspected:
      final game = orderSuggestionProspectOwnProvinceBudgetPriorityGame(
        feedstockAlreadyProspected: true,
      );
      final topology =
          orderSuggestionProspectOwnProvinceBudgetPriorityTopology(game);
      final view = buildPlayerView(
        game,
        topology,
        orderSuggestionProspectOwnProvinceBudgetPriorityPlayerId,
      );
      final suggestions = suggestWorkOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(
        orderSuggestionProspectOwnProvinceBudgetPriorityFeedstockProspects(
          suggestions,
        ),
        isEmpty,
      );

    case OrderSuggestionProspectOwnProvinceBudgetPriorityTarget
        .ownProvinceBudgetExemptionDeterministic:
      final game = orderSuggestionProspectOwnProvinceBudgetPriorityGame();
      final topology =
          orderSuggestionProspectOwnProvinceBudgetPriorityTopology(game);
      final view = buildPlayerView(
        game,
        topology,
        orderSuggestionProspectOwnProvinceBudgetPriorityPlayerId,
      );
      final first = suggestWorkOrders(view, game, topology, const Orders());
      final second = suggestWorkOrders(view, game, topology, const Orders());
      List<String> keyOf(List<WorkOrder> os) =>
          (os.map((o) => '${o.unitId}|${o.target}|${o.targetTileKey}').toList()
            ..sort());
      expect(keyOf(first), equals(keyOf(second)));
      expect(
        orderSuggestionProspectOwnProvinceBudgetPriorityFeedstockProspects(
          first,
        ),
        isNotEmpty,
      );
  }
}
