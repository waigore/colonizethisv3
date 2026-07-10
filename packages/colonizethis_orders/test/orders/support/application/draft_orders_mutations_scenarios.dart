// Table-driven draft-order mutation scenarios (Refs #3949 wave 3).

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/draft_orders_mutations.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'draft_orders_mutations_fixtures.dart';
// dart format off

void domRunRemovePendingWorkOrderAtRemovesAtIndex() {final orders = Orders(workOrdersByPlayerId: {'gp1': [draftOrdersWorkOrderW0,draftOrdersWorkOrderW1],},); final out = removePendingWorkOrderAt(orders,'gp1',0); expect(out.workOrdersByPlayerId['gp1'],[draftOrdersWorkOrderW1]);}

void domRunRemovePendingWorkOrderAtInvalidIndexNoOp() {const orders = Orders(); expect(removePendingWorkOrderAt(orders,'gp1',0),same(orders));}

void domRunTradeOrderForPlayerCommodityEmpty() {const orders = Orders(); expect(tradeOrderForPlayerCommodity(orders,'gp1','timber'),isNull);}

void domRunTradeOrderForPlayerCommodityMatching() {final orders = Orders(tradeOrdersByPlayerId: <String,List<TradeOrder>>{'gp1': <TradeOrder>[draftOrdersTimberBid,draftOrdersFabricBid],},); expect(tradeOrderForPlayerCommodity(orders,'gp1','timber'),draftOrdersTimberBid,); expect(tradeOrderForPlayerCommodity(orders,'gp1','fabric'),draftOrdersFabricBid,); expect(tradeOrderForPlayerCommodity(orders,'gp1','iron'),isNull);}

void domRunApplyTradeOrderForPlayerAdds() {const orders = Orders(); final out = applyTradeOrderForPlayer(orders: orders,playerId: 'gp1',order: draftOrdersTimberBid,); expect(out.tradeOrdersByPlayerId['gp1'],<TradeOrder>[draftOrdersTimberBid]);}

void domRunApplyTradeOrderForPlayerReplacesMutualExclusion() {final orders = Orders(tradeOrdersByPlayerId: <String,List<TradeOrder>>{'gp1': <TradeOrder>[draftOrdersTimberBid,draftOrdersFabricBid],},); final out = applyTradeOrderForPlayer(orders: orders,playerId: 'gp1',order: draftOrdersTimberOffer,); expect(out.tradeOrdersByPlayerId['gp1'],<TradeOrder>[draftOrdersFabricBid,draftOrdersTimberOffer],reason: 'Replaces the prior timber bid with the timber offer; ' 'fabric is untouched. Mutual exclusion holds.',);}

void domRunApplyTradeOrderForPlayerScopesPerPlayer() {final orders = Orders(tradeOrdersByPlayerId: <String,List<TradeOrder>>{'gp1': <TradeOrder>[draftOrdersTimberBid],'gp2': <TradeOrder>[draftOrdersFabricBid],},); final out = applyTradeOrderForPlayer(orders: orders,playerId: 'gp1',order: draftOrdersTimberOffer,); expect(out.tradeOrdersByPlayerId['gp1'],<TradeOrder>[draftOrdersTimberOffer,]); expect(out.tradeOrdersByPlayerId['gp2'],<TradeOrder>[draftOrdersFabricBid],reason: 'gp2\'s staged orders must not change when gp1 applies ' 'a trade order.',);}

void domRunRemoveTradeOrderForPlayerDeletes() {final orders = Orders(tradeOrdersByPlayerId: <String,List<TradeOrder>>{'gp1': <TradeOrder>[draftOrdersTimberBid,draftOrdersFabricBid],},); final out = removeTradeOrderForPlayer(orders: orders,playerId: 'gp1',commodityId: 'timber',); expect(out.tradeOrdersByPlayerId['gp1'],<TradeOrder>[draftOrdersFabricBid]);}

void domRunRemoveTradeOrderForPlayerNoOpEmpty() {const orders = Orders(); expect(identical(removeTradeOrderForPlayer(orders: orders,playerId: 'gp1',commodityId: 'timber',),orders,),isTrue,);}

void domRunRemoveTradeOrderForPlayerNoOpMissingCommodity() {final orders = Orders(tradeOrdersByPlayerId: <String,List<TradeOrder>>{'gp1': <TradeOrder>[draftOrdersTimberBid],},); expect(identical(removeTradeOrderForPlayer(orders: orders,playerId: 'gp1',commodityId: 'iron',),orders,),isTrue,);}

/// One row in draft-order mutation scenario tables.

/// Scenarios for removePendingWorkOrderAt.
List<RunnableScenario> removePendingWorkOrderAtScenarios() => [
  rs('removes order at index', domRunRemovePendingWorkOrderAtRemovesAtIndex),
  rs('returns orders unchanged when index invalid', domRunRemovePendingWorkOrderAtInvalidIndexNoOp),
];

/// Scenarios for trade-order draft helpers (Refs #2993 E5b).
List<RunnableScenario> draftOrdersTradeMutationScenarios() => [
  rs('tradeOrderForPlayerCommodity returns null on empty orders', domRunTradeOrderForPlayerCommodityEmpty, '#2993 E5b'),
  rs('tradeOrderForPlayerCommodity returns the matching staged order', domRunTradeOrderForPlayerCommodityMatching, '#2993 E5b'),
  rs('applyTradeOrderForPlayer adds when no prior order exists', domRunApplyTradeOrderForPlayerAdds, '#2993 E5b'),
  rs('applyTradeOrderForPlayer replaces a prior order for the same ' 'commodity (mutual exclusion: bid -> offer cannot coexist)',domRunApplyTradeOrderForPlayerReplacesMutualExclusion,'#2993 E5b'),
  rs('applyTradeOrderForPlayer scopes per-player (other players\' ' 'orders are not affected)',domRunApplyTradeOrderForPlayerScopesPerPlayer,'#2993 E5b'),
  rs('removeTradeOrderForPlayer deletes the matching staged order', domRunRemoveTradeOrderForPlayerDeletes, '#2993 E5b'),
  rs('removeTradeOrderForPlayer is a no-op (returns same instance) when ' 'the player has no staged orders',domRunRemoveTradeOrderForPlayerNoOpEmpty,'#2993 E5b'),
  rs('removeTradeOrderForPlayer is a no-op (returns same instance) when ' 'the commodity is not present in the staged list',domRunRemoveTradeOrderForPlayerNoOpMissingCommodity,'#2993 E5b'),
];
