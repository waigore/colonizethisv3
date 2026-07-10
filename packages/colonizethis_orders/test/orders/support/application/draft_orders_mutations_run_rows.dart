// Scenario run tear-offs for draft-orders-mutations (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/draft_orders_mutations.dart';
import 'package:colonizethis_test/test.dart';

import 'draft_orders_mutations_fixtures.dart';

void domRunRemovePendingWorkOrderAtRemovesAtIndex() {
  final orders = Orders(
    workOrdersByPlayerId: {
      'gp1': [draftOrdersWorkOrderW0, draftOrdersWorkOrderW1],
    },
  );
  final out = removePendingWorkOrderAt(orders, 'gp1', 0);
  expect(out.workOrdersByPlayerId['gp1'], [draftOrdersWorkOrderW1]);
}

void domRunRemovePendingWorkOrderAtInvalidIndexNoOp() {
  const orders = Orders();
  expect(removePendingWorkOrderAt(orders, 'gp1', 0), same(orders));
}

void domRunTradeOrderForPlayerCommodityEmpty() {
  const orders = Orders();
  expect(tradeOrderForPlayerCommodity(orders, 'gp1', 'timber'), isNull);
}

void domRunTradeOrderForPlayerCommodityMatching() {
  final orders = Orders(
    tradeOrdersByPlayerId: <String, List<TradeOrder>>{
      'gp1': <TradeOrder>[draftOrdersTimberBid, draftOrdersFabricBid],
    },
  );
  expect(
    tradeOrderForPlayerCommodity(orders, 'gp1', 'timber'),
    draftOrdersTimberBid,
  );
  expect(
    tradeOrderForPlayerCommodity(orders, 'gp1', 'fabric'),
    draftOrdersFabricBid,
  );
  expect(tradeOrderForPlayerCommodity(orders, 'gp1', 'iron'), isNull);
}

void domRunApplyTradeOrderForPlayerAdds() {
  const orders = Orders();
  final out = applyTradeOrderForPlayer(
    orders: orders,
    playerId: 'gp1',
    order: draftOrdersTimberBid,
  );
  expect(out.tradeOrdersByPlayerId['gp1'], <TradeOrder>[draftOrdersTimberBid]);
}

void domRunApplyTradeOrderForPlayerReplacesMutualExclusion() {
  final orders = Orders(
    tradeOrdersByPlayerId: <String, List<TradeOrder>>{
      'gp1': <TradeOrder>[draftOrdersTimberBid, draftOrdersFabricBid],
    },
  );
  final out = applyTradeOrderForPlayer(
    orders: orders,
    playerId: 'gp1',
    order: draftOrdersTimberOffer,
  );
  expect(
    out.tradeOrdersByPlayerId['gp1'],
    <TradeOrder>[draftOrdersFabricBid, draftOrdersTimberOffer],
    reason:
        'Replaces the prior timber bid with the timber offer; '
        'fabric is untouched. Mutual exclusion holds.',
  );
}

void domRunApplyTradeOrderForPlayerScopesPerPlayer() {
  final orders = Orders(
    tradeOrdersByPlayerId: <String, List<TradeOrder>>{
      'gp1': <TradeOrder>[draftOrdersTimberBid],
      'gp2': <TradeOrder>[draftOrdersFabricBid],
    },
  );
  final out = applyTradeOrderForPlayer(
    orders: orders,
    playerId: 'gp1',
    order: draftOrdersTimberOffer,
  );
  expect(out.tradeOrdersByPlayerId['gp1'], <TradeOrder>[
    draftOrdersTimberOffer,
  ]);
  expect(
    out.tradeOrdersByPlayerId['gp2'],
    <TradeOrder>[draftOrdersFabricBid],
    reason:
        'gp2\'s staged orders must not change when gp1 applies '
        'a trade order.',
  );
}

void domRunRemoveTradeOrderForPlayerDeletes() {
  final orders = Orders(
    tradeOrdersByPlayerId: <String, List<TradeOrder>>{
      'gp1': <TradeOrder>[draftOrdersTimberBid, draftOrdersFabricBid],
    },
  );
  final out = removeTradeOrderForPlayer(
    orders: orders,
    playerId: 'gp1',
    commodityId: 'timber',
  );
  expect(out.tradeOrdersByPlayerId['gp1'], <TradeOrder>[draftOrdersFabricBid]);
}

void domRunRemoveTradeOrderForPlayerNoOpEmpty() {
  const orders = Orders();
  expect(
    identical(
      removeTradeOrderForPlayer(
        orders: orders,
        playerId: 'gp1',
        commodityId: 'timber',
      ),
      orders,
    ),
    isTrue,
  );
}

void domRunRemoveTradeOrderForPlayerNoOpMissingCommodity() {
  final orders = Orders(
    tradeOrdersByPlayerId: <String, List<TradeOrder>>{
      'gp1': <TradeOrder>[draftOrdersTimberBid],
    },
  );
  expect(
    identical(
      removeTradeOrderForPlayer(
        orders: orders,
        playerId: 'gp1',
        commodityId: 'iron',
      ),
      orders,
    ),
    isTrue,
  );
}
