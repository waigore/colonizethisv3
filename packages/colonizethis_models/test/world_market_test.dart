import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('TradeOrder constructor', () {
    test('constructs valid instance with isFtp default false', () {
      final order = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.bid,
        quantity: 5,
        priority: 2,
      );
      expect(order.commodityId, 'timber');
      expect(order.type, TradeOrderType.bid);
      expect(order.quantity, 5);
      expect(order.priority, 2);
      expect(order.isFtp, false);
    });

    test('rejects empty commodityId', () {
      expect(
        () => TradeOrder(
          commodityId: '',
          type: TradeOrderType.bid,
          quantity: 1,
          priority: 1,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects negative quantity', () {
      expect(
        () => TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.bid,
          quantity: -1,
          priority: 1,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'message',
            contains('quantity'),
          ),
        ),
      );
    });

    test('rejects priority below 1', () {
      expect(
        () => TradeOrder(
          commodityId: 'timber',
          type: TradeOrderType.bid,
          quantity: 1,
          priority: 0,
        ),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.toString(),
            'message',
            contains('priority'),
          ),
        ),
      );
    });

    test('accepts quantity == 0 (caller may carry zero-rest after partial)', () {
      final order = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.offer,
        quantity: 0,
        priority: 1,
      );
      expect(order.quantity, 0);
    });
  });

  group('TradeOrder serialization', () {
    test('toJson produces canonical fields', () {
      final order = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.bid,
        quantity: 5,
        priority: 2,
        isFtp: true,
      );
      expect(order.toJson(), {
        'commodityId': 'timber',
        'type': 'bid',
        'quantity': 5,
        'priority': 2,
        'isFtp': true,
      });
    });

    test('round-trips equal instance with all fields preserved', () {
      final order = TradeOrder(
        commodityId: 'iron',
        type: TradeOrderType.offer,
        quantity: 12,
        priority: 3,
        isFtp: false,
      );
      final restored = TradeOrder.fromJson(order.toJson());
      expect(restored, equals(order));
      expect(restored.hashCode, equals(order.hashCode));
    });

    test('fromJson rejects missing/invalid type field', () {
      expect(
        () => TradeOrder.fromJson({
          'commodityId': 'timber',
          'type': 'invalid_type',
          'quantity': 1,
          'priority': 1,
          'isFtp': false,
        }),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('fromJson rejects non-int quantity field', () {
      expect(
        () => TradeOrder.fromJson({
          'commodityId': 'timber',
          'type': 'bid',
          'quantity': 'not-a-number',
          'priority': 1,
          'isFtp': false,
        }),
        throwsA(isA<ArgumentError>()),
      );
    });
  });

  group('TradeOrder equality and copyWith', () {
    test('equality is field-based', () {
      final a = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.bid,
        quantity: 5,
        priority: 2,
      );
      final b = TradeOrder(
        commodityId: 'timber',
        type: TradeOrderType.bid,
        quantity: 5,
        priority: 2,
      );
      final c = a.copyWith(quantity: 6);
      expect(a, equals(b));
      expect(a, isNot(equals(c)));
    });
  });

  group('MarketActivity', () {
    test('empty has zeroed fields', () {
      const m = MarketActivity.empty;
      expect(m.totalBidQuantity, 0);
      expect(m.totalOfferQuantity, 0);
      expect(m.filledQuantity, 0);
      expect(m.priceChangePercent, 0.0);
    });

    test('round-trips through JSON', () {
      const original = MarketActivity(
        totalBidQuantity: 20,
        totalOfferQuantity: 10,
        filledQuantity: 10,
        priceChangePercent: 0.1667,
      );
      final restored = MarketActivity.fromJson(original.toJson());
      expect(restored, equals(original));
    });
  });

  group('WorldMarketState', () {
    test('withDefaultPrices populates prices and leaves activity empty', () {
      final state = WorldMarketState.withDefaultPrices({
        'timber': 30,
        'iron': 80,
      });
      expect(state.prices, {'timber': 30.0, 'iron': 80.0});
      expect(state.lastTurnActivity, isEmpty);
    });

    test('round-trips through JSON', () {
      final state = WorldMarketState.withDefaultPrices({
        'timber': 30,
        'iron': 80,
      }).copyWith(
        lastTurnActivity: const {
          'timber': MarketActivity(
            totalBidQuantity: 20,
            totalOfferQuantity: 10,
            filledQuantity: 10,
            priceChangePercent: 0.1667,
          ),
        },
      );
      final restored = WorldMarketState.fromJson(state.toJson());
      expect(restored, equals(state));
    });

    test('empty constants are equal', () {
      expect(WorldMarketState.empty, equals(const WorldMarketState()));
    });

    test('carry-forward maps default to empty and omit from JSON when empty', () {
      const state = WorldMarketState();
      expect(state.carryForwardOffersByFactionId, isEmpty);
      expect(state.carryForwardBidsByFactionId, isEmpty);
      final json = state.toJson();
      expect(json.containsKey('carryForwardOffersByFactionId'), isFalse);
      expect(json.containsKey('carryForwardBidsByFactionId'), isFalse);
    });

    test('round-trips carry-forward offers and bids through JSON', () {
      final state = WorldMarketState.empty.copyWith(
        carryForwardOffersByFactionId: {
          'gp1': [
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.offer,
              quantity: 5,
              priority: 2,
            ),
          ],
        },
        carryForwardBidsByFactionId: {
          'gp2': [
            TradeOrder(
              commodityId: 'iron',
              type: TradeOrderType.bid,
              quantity: 3,
              priority: 1,
              isFtp: true,
            ),
          ],
        },
      );
      final restored = WorldMarketState.fromJson(state.toJson());
      expect(restored, equals(state));
      expect(
        restored.carryForwardOffersByFactionId['gp1']!.single.quantity,
        5,
      );
      expect(
        restored.carryForwardBidsByFactionId['gp2']!.single.isFtp,
        isTrue,
      );
    });

    test('equality reflects carry-forward differences', () {
      final base = WorldMarketState.empty.copyWith(
        carryForwardOffersByFactionId: {
          'gp1': [
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.offer,
              quantity: 5,
              priority: 2,
            ),
          ],
        },
      );
      final differentQty = WorldMarketState.empty.copyWith(
        carryForwardOffersByFactionId: {
          'gp1': [
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.offer,
              quantity: 6,
              priority: 2,
            ),
          ],
        },
      );
      expect(base, isNot(equals(differentQty)));
      expect(base, equals(base.copyWith()));
    });
  });

  group('FilledDeal', () {
    test('round-trips through JSON', () {
      const deal = FilledDeal(
        sellerFactionId: 'f1',
        buyerFactionId: 'f2',
        commodityId: 'timber',
        quantity: 7,
        pricePerUnit: 30.5,
        isFtpMatch: true,
      );
      final restored = FilledDeal.fromJson(deal.toJson());
      expect(restored, equals(deal));
    });
  });

  group('DealMatchResult.empty', () {
    test('has empty children and equals const default', () {
      const r = DealMatchResult.empty;
      expect(r.filledDeals, isEmpty);
      expect(r.unfilledOffersByFactionId, isEmpty);
      expect(r.unfilledBidsByFactionId, isEmpty);
      expect(r.activityByCommodityId, isEmpty);
      expect(r, equals(const DealMatchResult()));
    });
  });
}
