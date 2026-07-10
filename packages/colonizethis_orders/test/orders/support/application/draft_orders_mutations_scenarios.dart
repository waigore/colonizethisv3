// Table-driven draft-order mutation scenarios (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/draft_orders_mutations.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

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

/// One row in draft-order mutation scenario tables.

/// Scenarios for removePendingWorkOrderAt.
List<RunnableScenario> removePendingWorkOrderAtScenarios() => const [
  RunnableScenario(
    label: 'removes order at index',
    run: domRunRemovePendingWorkOrderAtRemovesAtIndex,
  ),
  RunnableScenario(
    label: 'returns orders unchanged when index invalid',
    run: domRunRemovePendingWorkOrderAtInvalidIndexNoOp,
  ),
];

/// Scenarios for trade-order draft helpers (Refs #2993 E5b).
List<RunnableScenario> draftOrdersTradeMutationScenarios() => const [
  RunnableScenario(
    label: 'tradeOrderForPlayerCommodity returns null on empty orders',
    run: domRunTradeOrderForPlayerCommodityEmpty,
    refs: '#2993 E5b',
  ),
  RunnableScenario(
    label: 'tradeOrderForPlayerCommodity returns the matching staged order',
    run: domRunTradeOrderForPlayerCommodityMatching,
    refs: '#2993 E5b',
  ),
  RunnableScenario(
    label: 'applyTradeOrderForPlayer adds when no prior order exists',
    run: domRunApplyTradeOrderForPlayerAdds,
    refs: '#2993 E5b',
  ),
  RunnableScenario(
    label:
        'applyTradeOrderForPlayer replaces a prior order for the same '
        'commodity (mutual exclusion: bid -> offer cannot coexist)',
    run: domRunApplyTradeOrderForPlayerReplacesMutualExclusion,
    refs: '#2993 E5b',
  ),
  RunnableScenario(
    label:
        'applyTradeOrderForPlayer scopes per-player (other players\' '
        'orders are not affected)',
    run: domRunApplyTradeOrderForPlayerScopesPerPlayer,
    refs: '#2993 E5b',
  ),
  RunnableScenario(
    label: 'removeTradeOrderForPlayer deletes the matching staged order',
    run: domRunRemoveTradeOrderForPlayerDeletes,
    refs: '#2993 E5b',
  ),
  RunnableScenario(
    label:
        'removeTradeOrderForPlayer is a no-op (returns same instance) when '
        'the player has no staged orders',
    run: domRunRemoveTradeOrderForPlayerNoOpEmpty,
    refs: '#2993 E5b',
  ),
  RunnableScenario(
    label:
        'removeTradeOrderForPlayer is a no-op (returns same instance) when '
        'the commodity is not present in the staged list',
    run: domRunRemoveTradeOrderForPlayerNoOpMissingCommodity,
    refs: '#2993 E5b',
  ),
];
