import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Tests for `TradeOrderSuggester.suggest` per
/// `SPEC/program/world-market-resolution.md` § Trade order suggestion API.
/// Refs #2989 A6.
void main() {
  group('TradeOrderSuggester.suggest — empty / defensive paths', () {
    test('empty context returns empty result', () {
      final result = TradeOrderSuggester.suggest(
        const TradeSuggestionContext(
          playerId: 'gp1',
          bidTypeCap: 3,
          tradeCargoCapacity: 100,
        ),
      );
      expect(result.isEmpty, isTrue);
      expect(result.offers, isEmpty);
      expect(result.bids, isEmpty);
    });

    test('negative tradeCargoCapacity returns empty result', () {
      final result = TradeOrderSuggester.suggest(
        const TradeSuggestionContext(
          playerId: 'gp1',
          bidTypeCap: 3,
          tradeCargoCapacity: -1,
          availableStockpileByCommodityId: {'timber': 10},
          commodityNeedByCommodityId: {'iron': 10},
        ),
      );
      expect(result.isEmpty, isTrue);
    });

    test(
      'negative entries in available/need maps are silently dropped (no throw)',
      () {
        final result = TradeOrderSuggester.suggest(
          const TradeSuggestionContext(
            playerId: 'gp1',
            bidTypeCap: 3,
            tradeCargoCapacity: 100,
            availableStockpileByCommodityId: {'timber': -5, 'iron': 10},
            commodityNeedByCommodityId: {'coal': -3, 'wool': 4},
          ),
        );
        expect(result.offers, hasLength(1));
        expect(result.offers.single.commodityId, 'iron');
        expect(result.bids, hasLength(1));
        expect(result.bids.single.commodityId, 'wool');
      },
    );
  });

  group('TradeOrderSuggester.suggest — surplus offer detection', () {
    test('positive available stockpile produces an offer with that quantity',
        () {
      final result = TradeOrderSuggester.suggest(
        const TradeSuggestionContext(
          playerId: 'gp1',
          bidTypeCap: 3,
          tradeCargoCapacity: 100,
          availableStockpileByCommodityId: {'timber': 12},
        ),
      );
      expect(result.offers, hasLength(1));
      final offer = result.offers.single;
      expect(offer.commodityId, 'timber');
      expect(offer.type, TradeOrderType.offer);
      expect(offer.quantity, 12);
      expect(offer.priority, TradeSuggestionContext.defaultOfferPriority);
      expect(offer.isFtp, isFalse);
      expect(result.bids, isEmpty);
    });

    test('zero / missing available is not offered', () {
      final result = TradeOrderSuggester.suggest(
        const TradeSuggestionContext(
          playerId: 'gp1',
          bidTypeCap: 3,
          tradeCargoCapacity: 100,
          availableStockpileByCommodityId: {'timber': 0, 'iron': 5},
        ),
      );
      expect(result.offers, hasLength(1));
      expect(result.offers.single.commodityId, 'iron');
      expect(result.offers.single.quantity, 5);
    });

    test('riches commodities are excluded from offers', () {
      final result = TradeOrderSuggester.suggest(
        const TradeSuggestionContext(
          playerId: 'gp1',
          bidTypeCap: 3,
          tradeCargoCapacity: 100,
          availableStockpileByCommodityId: {
            'spices': 100,
            'gold': 50,
            'timber': 10,
          },
        ),
      );
      expect(result.offers, hasLength(1));
      expect(result.offers.single.commodityId, 'timber');
    });

    test('offers iterate in alphabetical commodity id order (determinism)',
        () {
      final result = TradeOrderSuggester.suggest(
        const TradeSuggestionContext(
          playerId: 'gp1',
          bidTypeCap: 3,
          tradeCargoCapacity: 100,
          availableStockpileByCommodityId: {
            'wool': 4,
            'coal': 2,
            'iron': 3,
            'timber': 1,
          },
        ),
      );
      expect(
        result.offers.map((o) => o.commodityId).toList(),
        ['coal', 'iron', 'timber', 'wool'],
      );
    });
  });

  group('TradeOrderSuggester.suggest — deficit bid detection', () {
    test('positive need with zero stockpile produces a bid with that quantity',
        () {
      final result = TradeOrderSuggester.suggest(
        const TradeSuggestionContext(
          playerId: 'gp1',
          bidTypeCap: 3,
          tradeCargoCapacity: 100,
          commodityNeedByCommodityId: {'timber': 8},
        ),
      );
      expect(result.bids, hasLength(1));
      final bid = result.bids.single;
      expect(bid.commodityId, 'timber');
      expect(bid.type, TradeOrderType.bid);
      expect(bid.quantity, 8);
      expect(bid.priority, TradeSuggestionContext.defaultBidPriority);
      expect(bid.isFtp, isFalse);
      expect(result.offers, isEmpty);
    });

    test(
      'mutual-exclusion at suggestion time: same commodity with stockpile=5 '
      'and need=9 produces a deficit bid of 4 only (no offer)',
      () {
        final result = TradeOrderSuggester.suggest(
          const TradeSuggestionContext(
            playerId: 'gp1',
            bidTypeCap: 3,
            tradeCargoCapacity: 100,
            availableStockpileByCommodityId: {'timber': 5},
            commodityNeedByCommodityId: {'timber': 9},
          ),
        );
        expect(result.offers, isEmpty);
        expect(result.bids, hasLength(1));
        expect(result.bids.single.commodityId, 'timber');
        expect(result.bids.single.quantity, 4);
      },
    );

    test('riches commodities are excluded from bids even when needed', () {
      final result = TradeOrderSuggester.suggest(
        const TradeSuggestionContext(
          playerId: 'gp1',
          bidTypeCap: 3,
          tradeCargoCapacity: 100,
          commodityNeedByCommodityId: {
            'gems': 5,
            'gold': 5,
            'timber': 4,
          },
        ),
      );
      expect(result.bids, hasLength(1));
      expect(result.bids.single.commodityId, 'timber');
      expect(result.bids.single.quantity, 4);
    });
  });

  group('TradeOrderSuggester.suggest — bid type cap (rule 4)', () {
    test('bidTypeCap=0 suppresses every bid', () {
      final result = TradeOrderSuggester.suggest(
        const TradeSuggestionContext(
          playerId: 'gp1',
          bidTypeCap: 0,
          tradeCargoCapacity: 100,
          commodityNeedByCommodityId: {'timber': 4, 'iron': 3},
        ),
      );
      expect(result.bids, isEmpty);
      expect(result.offers, isEmpty);
    });

    test(
      'bidTypeCap=3 admits the first three alphabetical commodities only',
      () {
        final result = TradeOrderSuggester.suggest(
          const TradeSuggestionContext(
            playerId: 'gp1',
            bidTypeCap: 3,
            tradeCargoCapacity: 100,
            commodityNeedByCommodityId: {
              'wool': 5,
              'coal': 5,
              'timber': 5,
              'iron': 5,
            },
          ),
        );
        expect(
          result.bids.map((b) => b.commodityId).toList(),
          ['coal', 'iron', 'timber'],
          reason:
              'Alphabetical iteration + cap-of-3 keeps coal/iron/timber and '
              'drops wool deterministically.',
        );
      },
    );

    test('bidTypeCap=6 admits up to six distinct commodities', () {
      final result = TradeOrderSuggester.suggest(
        const TradeSuggestionContext(
          playerId: 'gp1',
          bidTypeCap: 6,
          tradeCargoCapacity: 100,
          commodityNeedByCommodityId: {
            'cattle': 1,
            'coal': 1,
            'cotton': 1,
            'grain': 1,
            'hides': 1,
            'iron': 1,
            'timber': 1,
          },
        ),
      );
      expect(result.bids, hasLength(6));
      expect(
        result.bids.map((b) => b.commodityId).toList(),
        ['cattle', 'coal', 'cotton', 'grain', 'hides', 'iron'],
      );
    });
  });

  group('TradeOrderSuggester.suggest — cumulative cargo cap (rule 5)', () {
    test('cargo budget is consumed across distinct bids (per-buyer total)',
        () {
      final result = TradeOrderSuggester.suggest(
        const TradeSuggestionContext(
          playerId: 'gp1',
          bidTypeCap: 3,
          tradeCargoCapacity: 6,
          commodityNeedByCommodityId: {'coal': 4, 'iron': 5},
        ),
      );
      expect(result.bids, hasLength(2));
      expect(result.bids[0].commodityId, 'coal');
      expect(result.bids[0].quantity, 4);
      expect(result.bids[1].commodityId, 'iron');
      expect(result.bids[1].quantity, 2,
          reason: 'iron is partial-capped by remaining cargo (6 - 4 = 2).');
    });

    test('per-commodity bid never exceeds tradeCargoCapacity', () {
      final result = TradeOrderSuggester.suggest(
        const TradeSuggestionContext(
          playerId: 'gp1',
          bidTypeCap: 3,
          tradeCargoCapacity: 10,
          commodityNeedByCommodityId: {'timber': 999},
        ),
      );
      expect(result.bids, hasLength(1));
      expect(result.bids.single.quantity, 10);
    });

    test('zero cargo budget suppresses bids entirely', () {
      final result = TradeOrderSuggester.suggest(
        const TradeSuggestionContext(
          playerId: 'gp1',
          bidTypeCap: 3,
          tradeCargoCapacity: 0,
          commodityNeedByCommodityId: {'timber': 5},
        ),
      );
      expect(result.bids, isEmpty);
    });
  });

  group('TradeOrderSuggester — validator-clean by construction', () {
    test('every suggested order is accepted by TradeOrderValidator.validate',
        () {
      const context = TradeSuggestionContext(
        playerId: 'gp1',
        bidTypeCap: 3,
        tradeCargoCapacity: 12,
        availableStockpileByCommodityId: {
          'timber': 10,
          'wool': 0,
        },
        commodityNeedByCommodityId: {
          'coal': 5,
          'iron': 7,
          'wool': 4,
        },
      );
      final result = TradeOrderSuggester.suggest(context);
      expect(result.offers, isNotEmpty);
      expect(result.bids, isNotEmpty);
      final all = <TradeOrder>[...result.offers, ...result.bids];
      final validatorResults = TradeOrderValidator.validate(
        context: TradeOrderValidationContext(
          playerId: context.playerId,
          bidTypeCap: context.bidTypeCap,
          tradeCargoCapacity: context.tradeCargoCapacity,
          availableStockpileByCommodityId:
              context.availableStockpileByCommodityId,
        ),
        proposedOrders: all,
      );
      for (final r in validatorResults) {
        expect(r.isAccepted, isTrue, reason: r.reason);
      }
    });

    test(
      'mixed surplus/deficit submission produces no commodity in both lists',
      () {
        final result = TradeOrderSuggester.suggest(
          const TradeSuggestionContext(
            playerId: 'gp1',
            bidTypeCap: 6,
            tradeCargoCapacity: 100,
            availableStockpileByCommodityId: {
              'timber': 50,
              'wool': 5,
            },
            commodityNeedByCommodityId: {
              'wool': 8, // net = -3 → bid only
              'iron': 4, // bid only (no stockpile entry)
            },
          ),
        );
        final offerIds = result.offers.map((o) => o.commodityId).toSet();
        final bidIds = result.bids.map((b) => b.commodityId).toSet();
        expect(offerIds.intersection(bidIds), isEmpty);
        expect(offerIds, contains('timber'));
        expect(bidIds, containsAll(<String>{'wool', 'iron'}));
      },
    );
  });
}
