import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('removePendingWorkOrderAt', () {
    test('removes order at index', () {
      const w0 = WorkOrder(
        unitId: 'u0',
        target: kWorkTargetExplore,
        targetTileKey: 'oldWorld|p1|0|0',
      );
      const w1 = WorkOrder(
        unitId: 'u1',
        target: kWorkTargetExplore,
        targetTileKey: 'oldWorld|p2|0|0',
      );
      final orders = Orders(
        workOrdersByPlayerId: {
          'gp1': [w0, w1],
        },
      );
      final out = removePendingWorkOrderAt(orders, 'gp1', 0);
      expect(out.workOrdersByPlayerId['gp1'], [w1]);
    });

    test('returns orders unchanged when index invalid', () {
      const orders = Orders();
      expect(
        removePendingWorkOrderAt(orders, 'gp1', 0),
        same(orders),
      );
    });
  });

  group(
    'tradeOrderForPlayerCommodity / applyTradeOrderForPlayer / '
    'removeTradeOrderForPlayer (Refs #2993 E5b)',
    () {
      final timberBid = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.bid,
        quantity: 5,
        priority: 1,
      );
      final timberOffer = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: 3,
        priority: 1,
      );
      final fabricBid = TradeOrder(
        commodityId: 'fabric',
        type: TradeOrderType.bid,
        quantity: 2,
        priority: 1,
      );

      test('tradeOrderForPlayerCommodity returns null on empty orders', () {
        const orders = Orders();
        expect(
          tradeOrderForPlayerCommodity(orders, 'gp1', 'timber'),
          isNull,
        );
      });

      test(
        'tradeOrderForPlayerCommodity returns the matching staged order',
        () {
          final orders = Orders(
            tradeOrdersByPlayerId: <String, List<TradeOrder>>{
              'gp1': <TradeOrder>[timberBid, fabricBid],
            },
          );
          expect(
            tradeOrderForPlayerCommodity(orders, 'gp1', 'timber'),
            timberBid,
          );
          expect(
            tradeOrderForPlayerCommodity(orders, 'gp1', 'fabric'),
            fabricBid,
          );
          expect(
            tradeOrderForPlayerCommodity(orders, 'gp1', 'iron'),
            isNull,
          );
        },
      );

      test('applyTradeOrderForPlayer adds when no prior order exists', () {
        const orders = Orders();
        final out = applyTradeOrderForPlayer(
          orders: orders,
          playerId: 'gp1',
          order: timberBid,
        );
        expect(out.tradeOrdersByPlayerId['gp1'], <TradeOrder>[timberBid]);
      });

      test(
        'applyTradeOrderForPlayer replaces a prior order for the same '
        'commodity (mutual exclusion: bid -> offer cannot coexist)',
        () {
          final orders = Orders(
            tradeOrdersByPlayerId: <String, List<TradeOrder>>{
              'gp1': <TradeOrder>[timberBid, fabricBid],
            },
          );
          final out = applyTradeOrderForPlayer(
            orders: orders,
            playerId: 'gp1',
            order: timberOffer,
          );
          expect(
            out.tradeOrdersByPlayerId['gp1'],
            <TradeOrder>[fabricBid, timberOffer],
            reason:
                'Replaces the prior timber bid with the timber offer; '
                'fabric is untouched. Mutual exclusion holds.',
          );
        },
      );

      test(
        'applyTradeOrderForPlayer scopes per-player (other players\' '
        'orders are not affected)',
        () {
          final orders = Orders(
            tradeOrdersByPlayerId: <String, List<TradeOrder>>{
              'gp1': <TradeOrder>[timberBid],
              'gp2': <TradeOrder>[fabricBid],
            },
          );
          final out = applyTradeOrderForPlayer(
            orders: orders,
            playerId: 'gp1',
            order: timberOffer,
          );
          expect(
            out.tradeOrdersByPlayerId['gp1'],
            <TradeOrder>[timberOffer],
          );
          expect(
            out.tradeOrdersByPlayerId['gp2'],
            <TradeOrder>[fabricBid],
            reason:
                'gp2\'s staged orders must not change when gp1 applies '
                'a trade order.',
          );
        },
      );

      test('removeTradeOrderForPlayer deletes the matching staged order', () {
        final orders = Orders(
          tradeOrdersByPlayerId: <String, List<TradeOrder>>{
            'gp1': <TradeOrder>[timberBid, fabricBid],
          },
        );
        final out = removeTradeOrderForPlayer(
          orders: orders,
          playerId: 'gp1',
          commodityId: 'timber',
        );
        expect(out.tradeOrdersByPlayerId['gp1'], <TradeOrder>[fabricBid]);
      });

      test(
        'removeTradeOrderForPlayer is a no-op (returns same instance) when '
        'the player has no staged orders',
        () {
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
        },
      );

      test(
        'removeTradeOrderForPlayer is a no-op (returns same instance) when '
        'the commodity is not present in the staged list',
        () {
          final orders = Orders(
            tradeOrdersByPlayerId: <String, List<TradeOrder>>{
              'gp1': <TradeOrder>[timberBid],
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
        },
      );
    },
  );
}
