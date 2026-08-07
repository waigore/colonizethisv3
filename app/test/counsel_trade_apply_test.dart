// Trade Counsel Agree/Apply widget tests. Refs #4282.
// dart format off
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_app/features/game/screens/counsel/counsel_trade_apply.dart';

void main() {
  group('tradeCounselOrdersAfterApplyBook', () {
    test('replaces entire staged trade book for player', () {
      final prior = Orders(
        tradeOrdersByPlayerId: {
          'gp1': [
            TradeOrder(
              type: TradeOrderType.bid,
              commodityId: 'timber',
              quantity: 2,
              priority: 3,
            ),
          ],
        },
      );
      final book = [
        TradeOrder(
          type: TradeOrderType.offer,
          commodityId: 'iron',
          quantity: 5,
          priority: 5,
        ),
      ];
      final next = tradeCounselOrdersAfterApplyBook(
        currentOrders: prior,
        playerId: 'gp1',
        book: book,
      );
      expect(next.tradeOrdersByPlayerId['gp1'], book);
    });
  });

  group('tradeCounselOrdersAfterAgree', () {
    test('stages one line via applyTradeOrderForPlayer', () {
      const prior = Orders();
      final order = TradeOrder(
        type: TradeOrderType.bid,
        commodityId: 'timber',
        quantity: 3,
        priority: 3,
      );
      final next = tradeCounselOrdersAfterAgree(
        currentOrders: prior,
        playerId: 'gp1',
        order: order,
      );
      expect(next?.tradeOrdersByPlayerId['gp1']?.single, order);
    });
  });
}
