// Compact prospect location province priority assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_prospect_location_province_priority_fixtures.dart';

/// Pins for [suggestWorkOrdersProspectLocationProvincePriorityScenarios] rows.
enum OrderSuggestionProspectLocationProvincePriorityTarget {
  coLocatedExplorerReceivesProspectInLateSortedProvince,
  noProspectWithoutFoggedVisibility,
}

void runOrderSuggestionProspectLocationProvincePriorityExpectation(
  OrderSuggestionProspectLocationProvincePriorityTarget target,
) {
  switch (target) {
    case OrderSuggestionProspectLocationProvincePriorityTarget
        .coLocatedExplorerReceivesProspectInLateSortedProvince:
      final game = orderSuggestionProspectLocationProvincePriorityGame();
      final topology =
          orderSuggestionProspectLocationProvincePriorityTopology(game);
      final view = buildPlayerView(
        game,
        topology,
        orderSuggestionProspectLocationProvincePriorityPlayerId,
      );
      final suggestions = suggestWorkOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      final prospects = suggestions
          .where(
            (o) =>
                o.unitId ==
                    orderSuggestionProspectLocationProvincePriorityExplorerUnitId &&
                o.target == kWorkTargetProspect,
          )
          .toList();
      expect(prospects, isNotEmpty);
      expect(
        prospects.map((o) => o.targetTileKey),
        contains(orderSuggestionProspectLocationProvincePriorityIronTileKey),
      );

    case OrderSuggestionProspectLocationProvincePriorityTarget
        .noProspectWithoutFoggedVisibility:
      final game = orderSuggestionProspectLocationProvincePriorityGame(
        includeFoggedVisibility: false,
      );
      final topology =
          orderSuggestionProspectLocationProvincePriorityTopology(game);
      final view = buildPlayerView(
        game,
        topology,
        orderSuggestionProspectLocationProvincePriorityPlayerId,
      );
      final suggestions = suggestWorkOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(
        suggestions.where((o) => o.target == kWorkTargetProspect),
        isEmpty,
      );
  }
}
