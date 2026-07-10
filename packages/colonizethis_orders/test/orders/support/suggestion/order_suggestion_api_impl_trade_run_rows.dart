// Scenario run tear-offs for order_suggestion_api_impl_trade (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_api_impl_trade_fixtures.dart';

const _api = DefaultOrderSuggestionAPI();

void osaitRunNoEmbassyBidTypeCapZeroOffersFromStockpileNoBids() {
  final stockpile = const Stockpile()
      .applyDelta('timber', 12)
      .applyDelta('iron', 4)
      .applyDelta('gold', 99);
  final game = tradeApiImplGameWithStockpile(stockpile);
  final view = tradeApiImplViewFor(game);
  final result = _api.suggestTradeOrders(view, game);
  expect(result.bids, isEmpty);
  final offerIds = result.offers.map((o) => o.commodityId).toSet();
  expect(offerIds, containsAll(<String>{'iron', 'timber'}));
  expect(
    offerIds.intersection(richesCommodityIds.toSet()),
    isEmpty,
    reason: 'Riches must not appear in trade offers (rule 2).',
  );
}

void osaitRunContextOverridePassesThroughToPureSuggester() {
  final game = tradeApiImplGameWithoutStockpile();
  final view = tradeApiImplViewFor(game);
  final result = _api.suggestTradeOrders(
    view,
    game,
    contextOverride: const TradeSuggestionContext(
      playerId: tradeApiImplPlayerId,
      bidTypeCap: 3,
      tradeCargoCapacity: 100,
      commodityNeedByCommodityId: {'timber': 5},
    ),
  );
  expect(result.offers, isEmpty);
  expect(result.bids, hasLength(1));
  expect(result.bids.single.commodityId, 'timber');
  expect(result.bids.single.quantity, 5);
}

void osaitRunDefaultImplReturnsValidatorCleanOutputForWiredContext() {
  final stockpile = const Stockpile()
      .applyDelta('timber', 8)
      .applyDelta('iron', 3);
  final game = tradeApiImplGameWithStockpile(stockpile);
  final view = tradeApiImplViewFor(game);
  final result = _api.suggestTradeOrders(view, game);
  final all = <TradeOrder>[...result.offers, ...result.bids];
  final validatorResults = TradeOrderValidator.validate(
    context: tradeOrderValidationContextFromGame(game, tradeApiImplPlayerId),
    proposedOrders: all,
  );
  for (final r in validatorResults) {
    expect(r.isAccepted, isTrue, reason: r.reason);
  }
}
