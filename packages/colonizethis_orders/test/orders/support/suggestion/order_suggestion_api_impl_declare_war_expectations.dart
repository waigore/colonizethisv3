// API declare-war suggestion assertions (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_api_impl_declare_war_fixtures.dart';

/// Pins for [orderSuggestionApiImplDeclareWarScenarios] rows.
enum OrderSuggestionApiImplDeclareWarTarget {
  declareWarWhenOvertureWouldWinInDiplomaticPass,
}

const _api = DefaultOrderSuggestionAPI();
const _emptyOrders = Orders();

void runOrderSuggestionApiImplDeclareWarExpectation(
  OrderSuggestionApiImplDeclareWarTarget target,
) {
  switch (target) {
    case OrderSuggestionApiImplDeclareWarTarget
        .declareWarWhenOvertureWouldWinInDiplomaticPass:
      final game = apiImplDeclareWarMinorScenarioGame();
      final view = apiImplDeclareWarViewFor(game);
      final general = _api.suggestDiplomaticOrders(
        view,
        game,
        apiImplDeclareWarEmptyTopology,
        _emptyOrders,
      );
      final declareOnly = _api.suggestDeclareWarOrders(
        view,
        game,
        apiImplDeclareWarEmptyTopology,
        _emptyOrders,
      );
      expect(
        general.any(
          (o) =>
              o.targetFactionId == 'minor1' &&
              o.type == DiplomaticOrderType.establishOverture,
        ),
        isTrue,
      );
      expect(
        general.any(
          (o) =>
              o.targetFactionId == 'minor1' &&
              o.type == DiplomaticOrderType.declareWar,
        ),
        isFalse,
      );
      expect(
        declareOnly.any(
          (o) =>
              o.targetFactionId == 'minor1' &&
              o.type == DiplomaticOrderType.declareWar,
        ),
        isTrue,
      );
      expect(
        declareOnly.every((o) => o.type == DiplomaticOrderType.declareWar),
        isTrue,
      );
  }
}
