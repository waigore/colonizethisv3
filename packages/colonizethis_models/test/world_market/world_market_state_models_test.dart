import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('WorldMarketState', () {
    test(
      'withDefaultPrices populates prices as int and leaves activity empty',
      () {
        final state = WorldMarketState.withDefaultPrices({
          'timber': 30,
          'iron': 80,
        });
        // Post-#3093: `WorldMarketState.prices` is now `Map<CommodityId, int>`
        // (floored at persistence boundary per
        // SPEC/game/world-market.md § Price discovery).
        expect(state.prices, <CommodityId, int>{'timber': 30, 'iron': 80});
        expect(state.prices['timber'], isA<int>());
        expect(state.lastTurnActivity, isEmpty);
      },
    );

    test('round-trips through JSON', () {
      final state =
          WorldMarketState.withDefaultPrices({
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
      expect(restored.prices['timber'], isA<int>());
      expect(restored.prices['timber'], 30);
    });

    test(
      'round-trips completedTradePairKeys through JSON (Refs #3753 R10)',
      () {
        final state = WorldMarketState.withDefaultPrices({
          'timber': 30,
        }).copyWith(completedTradePairKeys: const {'gp1|gp2', 'm1|gp1'});
        final restored = WorldMarketState.fromJson(state.toJson());
        expect(restored.completedTradePairKeys, const {'gp1|gp2', 'm1|gp1'});
        expect(restored, equals(state));
      },
    );

    test('fromJson treats missing completedTradePairKeys as empty', () {
      final restored = WorldMarketState.fromJson(<String, dynamic>{
        'prices': <String, dynamic>{'timber': 30},
        'lastTurnActivity': <String, dynamic>{},
      });
      expect(restored.completedTradePairKeys, isEmpty);
    });

    test('fromJson floors legacy double prices to int (backward compat)', () {
      // Pre-#3093 saves wrote `prices` as `Map<CommodityId, double>`.
      // The new `fromJson` floors any non-integer numeric value so the
      // in-memory map is always int-valued without forcing a save migration.
      final restored = WorldMarketState.fromJson(<String, dynamic>{
        'prices': <String, dynamic>{'timber': 29.99, 'iron': 80.5, 'coal': 100},
        'lastTurnActivity': <String, dynamic>{},
      });
      expect(restored.prices, <CommodityId, int>{
        'timber': 29,
        'iron': 80,
        'coal': 100,
      });
      expect(restored.prices['timber'], isA<int>());
    });

    test('fromJson clamps negative numeric prices to 0 (defensive)', () {
      // SPEC/game/world-market.md § Price discovery clamps the floor at
      // 30% of base price (always non-negative). A hand-edited save with a
      // negative price would have been a logic bug pre-#3093; the new
      // floor migration treats it as zero rather than crashing.
      final restored = WorldMarketState.fromJson(<String, dynamic>{
        'prices': <String, dynamic>{'timber': -5.0},
      });
      expect(restored.prices['timber'], 0);
    });

    test('empty constants are equal', () {
      expect(WorldMarketState.empty, equals(const WorldMarketState()));
    });

    test(
      'carry-forward maps default to empty and omit from JSON when empty',
      () {
        const state = WorldMarketState();
        expect(state.carryForwardOffersByFactionId, isEmpty);
        expect(state.carryForwardBidsByFactionId, isEmpty);
        final json = state.toJson();
        expect(json.containsKey('carryForwardOffersByFactionId'), isFalse);
        expect(json.containsKey('carryForwardBidsByFactionId'), isFalse);
      },
    );

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
      expect(restored.carryForwardOffersByFactionId['gp1']!.single.quantity, 5);
      expect(restored.carryForwardBidsByFactionId['gp2']!.single.isFtp, isTrue);
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

    test('isFirstRightOfRefusalMatch defaults to false', () {
      const deal = FilledDeal(
        sellerFactionId: 'f1',
        buyerFactionId: 'f2',
        commodityId: 'timber',
        quantity: 1,
        pricePerUnit: 1.0,
      );
      expect(deal.isFirstRightOfRefusalMatch, isFalse);
      expect(deal.toJson().containsKey('isFirstRightOfRefusalMatch'), isFalse);
    });

    test(
      'isFirstRightOfRefusalMatch round-trips through JSON when true (#2992 D2)',
      () {
        const deal = FilledDeal(
          sellerFactionId: 'M1',
          buyerFactionId: 'gpA',
          commodityId: 'timber',
          quantity: 4,
          pricePerUnit: 30.0,
          isFirstRightOfRefusalMatch: true,
        );
        final restored = FilledDeal.fromJson(deal.toJson());
        expect(restored, equals(deal));
        expect(restored.isFirstRightOfRefusalMatch, isTrue);
        expect(deal.toJson()['isFirstRightOfRefusalMatch'], true);
      },
    );

    test('equality differs when only isFirstRightOfRefusalMatch differs', () {
      const ftpDeal = FilledDeal(
        sellerFactionId: 'a',
        buyerFactionId: 'b',
        commodityId: 'timber',
        quantity: 1,
        pricePerUnit: 1.0,
        isFtpMatch: true,
      );
      const frrDeal = FilledDeal(
        sellerFactionId: 'a',
        buyerFactionId: 'b',
        commodityId: 'timber',
        quantity: 1,
        pricePerUnit: 1.0,
        isFirstRightOfRefusalMatch: true,
      );
      expect(ftpDeal, isNot(equals(frrDeal)));
      expect(ftpDeal.hashCode, isNot(equals(frrDeal.hashCode)));
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
