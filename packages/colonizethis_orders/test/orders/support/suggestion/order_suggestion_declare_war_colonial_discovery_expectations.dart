// Colonial discovery declare-war assertions (Refs #3620, #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_colonial_acquisition_fixtures.dart';
import 'order_suggestion_declare_war_colonial_discovery_fixtures.dart';

/// Pins for [orderSuggestionDeclareWarColonialDiscoveryScenarios] rows.
enum OrderSuggestionDeclareWarColonialDiscoveryTarget {
  excludesSeaReachableTribeWithoutNwVisibility,
}

const _api = DefaultOrderSuggestionAPI();
const _emptyOrders = Orders();

void runOrderSuggestionDeclareWarColonialDiscoveryExpectation(
  OrderSuggestionDeclareWarColonialDiscoveryTarget target,
) {
  switch (target) {
    case OrderSuggestionDeclareWarColonialDiscoveryTarget
        .excludesSeaReachableTribeWithoutNwVisibility:
      final game = colonialDiscoveryNoNwVisibilityGame();
      final view = colonialDiscoveryViewFor(game);
      expect(
        knownDiplomaticTargetFactionIds(
          view: view,
          game: game,
          topology: colonialAcquisitionTopology,
        ),
        isNot(contains('tribe1')),
      );
      final declareOnly = _api.suggestDeclareWarOrders(
        view,
        game,
        colonialAcquisitionTopology,
        _emptyOrders,
      );
      expect(
        declareOnly.any(
          (o) =>
              o.targetFactionId == 'tribe1' &&
              o.type == DiplomaticOrderType.declareWar,
        ),
        isFalse,
      );
  }
}
