import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Tests for `TradeOrderValidator` per
/// `SPEC/program/world-market-resolution.md` § Trade order validation.
/// Refs #2989 A5.
void main() {
  group('TradeOrderValidator.validate — empty / accept paths', () {
    test('empty proposed orders returns empty result list', () {
      final results = TradeOrderValidator.validate(
        context: _ctx(),
        proposedOrders: const [],
      );
      expect(results, isEmpty);
    });

    test(
      'single valid offer is accepted (stockpile covers, not riches, not '
      'mutually excluded)',
      () {
        final results = TradeOrderValidator.validate(
          context: _ctx(availableStockpileByCommodityId: {'timber': 50}),
          proposedOrders: [_offer('timber', 10)],
        );
        expect(results, hasLength(1));
        expect(results.single.isAccepted, isTrue);
      },
    );

    test(
      'single valid bid is accepted (within cargo, distinct-bid cap, not '
      'riches, not mutually excluded)',
      () {
        final results = TradeOrderValidator.validate(
          context: _ctx(),
          proposedOrders: [_bid('timber', 10)],
        );
        expect(results, hasLength(1));
        expect(results.single.isAccepted, isTrue);
      },
    );

    test(
      'second bid on same commodity does not consume a new cap slot '
      '(rule 4 counts distinct commodities)',
      () {
        final results = TradeOrderValidator.validate(
          context: _ctx(bidTypeCap: 3),
          proposedOrders: [
            _bid('timber', 5, priority: 1),
            _bid('iron', 5, priority: 1),
            _bid('coal', 5, priority: 1),
            _bid('timber', 5, priority: 2), // already-admitted commodity
          ],
        );
        for (final r in results) {
          expect(r.isAccepted, isTrue, reason: r.reason);
        }
      },
    );

    test(
      'parallel result list is index-aligned to proposed orders',
      () {
        final results = TradeOrderValidator.validate(
          context: _ctx(),
          proposedOrders: [
            _bid('timber', 5),
            _bid('timber', 0), // invalid quantity
            _bid('timber', 5),
          ],
        );
        expect(results, hasLength(3));
        expect(results[0].isAccepted, isTrue);
        expect(results[1].isAccepted, isFalse);
        expect(
          results[1].reason,
          TradeOrderRejectionReasons.invalidQuantity,
        );
        expect(results[2].isAccepted, isTrue);
      },
    );
  });

  group('TradeOrderValidator.validate — rule 1: invalid quantity', () {
    test('quantity == 0 is rejected with invalidQuantity', () {
      final results = TradeOrderValidator.validate(
        context: _ctx(),
        proposedOrders: [_bid('timber', 0)],
      );
      expect(results.single.isAccepted, isFalse);
      expect(
        results.single.reason,
        TradeOrderRejectionReasons.invalidQuantity,
      );
    });

    test(
      'invalidQuantity takes precedence over richesNotTradeable for a '
      'zero-quantity riches order',
      () {
        final results = TradeOrderValidator.validate(
          context: _ctx(),
          proposedOrders: [_offer('spices', 0)],
        );
        expect(
          results.single.reason,
          TradeOrderRejectionReasons.invalidQuantity,
          reason: 'Rule 1 evaluates before rule 2 per SPEC.',
        );
      },
    );
  });

  group('TradeOrderValidator.validate — rule 2: riches not tradeable', () {
    test(
      'every riches commodity id is rejected with richesNotTradeable '
      '(offer side)',
      () {
        for (final id in const ['spices', 'silver', 'gold', 'gems', 'diamonds']) {
          final results = TradeOrderValidator.validate(
            context: _ctx(availableStockpileByCommodityId: {id: 999}),
            proposedOrders: [_offer(id, 5)],
          );
          expect(
            results.single.reason,
            TradeOrderRejectionReasons.richesNotTradeable,
            reason: 'Riches commodity $id must not be tradeable',
          );
        }
      },
    );

    test('riches bid is also rejected with richesNotTradeable', () {
      final results = TradeOrderValidator.validate(
        context: _ctx(),
        proposedOrders: [_bid('gold', 5)],
      );
      expect(
        results.single.reason,
        TradeOrderRejectionReasons.richesNotTradeable,
      );
    });
  });

  group('TradeOrderValidator.validate — rule 3: mutual exclusion', () {
    test(
      'commodity appearing as both bid and offer rejects both sides with '
      'mutualExclusion',
      () {
        final results = TradeOrderValidator.validate(
          context: _ctx(availableStockpileByCommodityId: {'timber': 50}),
          proposedOrders: [
            _bid('timber', 5),
            _offer('timber', 5),
          ],
        );
        for (final r in results) {
          expect(r.isAccepted, isFalse);
          expect(
            r.reason,
            TradeOrderRejectionReasons.mutualExclusion,
          );
        }
      },
    );

    test(
      'bid-on-A + offer-on-B is allowed (mutual exclusion is per-commodity, '
      'not per-player)',
      () {
        final results = TradeOrderValidator.validate(
          context: _ctx(availableStockpileByCommodityId: {'iron': 50}),
          proposedOrders: [_bid('timber', 5), _offer('iron', 5)],
        );
        expect(results[0].isAccepted, isTrue);
        expect(results[1].isAccepted, isTrue);
      },
    );

    test(
      'mutually excluded commodity does not consume a bid-type cap slot',
      () {
        final results = TradeOrderValidator.validate(
          context: _ctx(
            bidTypeCap: 3,
            availableStockpileByCommodityId: {'timber': 50},
          ),
          proposedOrders: [
            _bid('timber', 5), // mutually excluded with offer below
            _offer('timber', 5),
            _bid('iron', 5),
            _bid('coal', 5),
            _bid('wool', 5),
          ],
        );
        // timber bid + timber offer both rejected with mutualExclusion;
        // iron / coal / wool occupy the 3 cap slots and accept.
        expect(
          results[0].reason,
          TradeOrderRejectionReasons.mutualExclusion,
        );
        expect(
          results[1].reason,
          TradeOrderRejectionReasons.mutualExclusion,
        );
        expect(results[2].isAccepted, isTrue);
        expect(results[3].isAccepted, isTrue);
        expect(results[4].isAccepted, isTrue);
      },
    );
  });

  group('TradeOrderValidator.validate — rule 4: bid type cap', () {
    test('bidTypeCap = 0 rejects every bid with bidTypeCapExceeded', () {
      final results = TradeOrderValidator.validate(
        context: _ctx(bidTypeCap: 0),
        proposedOrders: [_bid('timber', 5), _bid('iron', 5)],
      );
      for (final r in results) {
        expect(
          r.reason,
          TradeOrderRejectionReasons.bidTypeCapExceeded,
        );
      }
    });

    test(
      'bidTypeCap = 0 does NOT affect offers (offers are not capped by '
      'rule 4)',
      () {
        final results = TradeOrderValidator.validate(
          context: _ctx(
            bidTypeCap: 0,
            availableStockpileByCommodityId: {
              'timber': 50,
              'iron': 50,
              'coal': 50,
            },
          ),
          proposedOrders: [
            _offer('timber', 5),
            _offer('iron', 5),
            _offer('coal', 5),
          ],
        );
        for (final r in results) {
          expect(r.isAccepted, isTrue, reason: r.reason);
        }
      },
    );

    test(
      'bidTypeCap = 3 accepts first 3 distinct bid commodities, rejects 4th',
      () {
        final results = TradeOrderValidator.validate(
          context: _ctx(bidTypeCap: 3),
          proposedOrders: [
            _bid('timber', 5),
            _bid('iron', 5),
            _bid('coal', 5),
            _bid('wool', 5),
          ],
        );
        expect(results[0].isAccepted, isTrue);
        expect(results[1].isAccepted, isTrue);
        expect(results[2].isAccepted, isTrue);
        expect(
          results[3].reason,
          TradeOrderRejectionReasons.bidTypeCapExceeded,
        );
      },
    );

    test(
      'bidTypeCap = 6 accepts first 6 distinct bid commodities, rejects 7th',
      () {
        final results = TradeOrderValidator.validate(
          context: _ctx(bidTypeCap: 6),
          proposedOrders: [
            _bid('timber', 5),
            _bid('iron', 5),
            _bid('coal', 5),
            _bid('wool', 5),
            _bid('hides', 5),
            _bid('cattle', 5),
            _bid('grain', 5),
          ],
        );
        for (var i = 0; i < 6; i++) {
          expect(results[i].isAccepted, isTrue, reason: results[i].reason);
        }
        expect(
          results[6].reason,
          TradeOrderRejectionReasons.bidTypeCapExceeded,
        );
      },
    );

    test(
      'bidTypeCap submission order determines which commodities are admitted',
      () {
        // bidTypeCap=2 with submission [a, b, c, a]:
        // admitted = {a, b}; c rejected, second a accepted.
        final results = TradeOrderValidator.validate(
          context: _ctx(bidTypeCap: 2),
          proposedOrders: [
            _bid('a', 5, priority: 1),
            _bid('b', 5, priority: 1),
            _bid('c', 5, priority: 1),
            _bid('a', 5, priority: 2),
          ],
        );
        expect(results[0].isAccepted, isTrue);
        expect(results[1].isAccepted, isTrue);
        expect(
          results[2].reason,
          TradeOrderRejectionReasons.bidTypeCapExceeded,
        );
        expect(results[3].isAccepted, isTrue);
      },
    );
  });

  group('TradeOrderValidator.validate — rule 5: bid cargo cap', () {
    test('bid quantity > tradeCargoCapacity is rejected', () {
      final results = TradeOrderValidator.validate(
        context: _ctx(tradeCargoCapacity: 10),
        proposedOrders: [_bid('timber', 12)],
      );
      expect(
        results.single.reason,
        TradeOrderRejectionReasons.bidExceedsCargoCapacity,
      );
    });

    test('bid quantity == tradeCargoCapacity is accepted (inclusive)', () {
      final results = TradeOrderValidator.validate(
        context: _ctx(tradeCargoCapacity: 10),
        proposedOrders: [_bid('timber', 10)],
      );
      expect(results.single.isAccepted, isTrue);
    });

    test(
      'per-commodity cap is independent: two distinct bids each at capacity '
      'are both accepted (cross-commodity is the matcher\'s job)',
      () {
        final results = TradeOrderValidator.validate(
          context: _ctx(bidTypeCap: 2, tradeCargoCapacity: 10),
          proposedOrders: [_bid('timber', 10), _bid('iron', 10)],
        );
        expect(results[0].isAccepted, isTrue);
        expect(results[1].isAccepted, isTrue);
      },
    );
  });

  group('TradeOrderValidator.validate — rule 6: offer stockpile', () {
    test('offer quantity > availableStockpile is rejected', () {
      final results = TradeOrderValidator.validate(
        context: _ctx(availableStockpileByCommodityId: {'timber': 5}),
        proposedOrders: [_offer('timber', 10)],
      );
      expect(
        results.single.reason,
        TradeOrderRejectionReasons.offerExceedsStockpile,
      );
    });

    test(
      'offer with no entry in availableStockpileByCommodityId is treated as '
      'available = 0 and rejected for any positive quantity',
      () {
        final results = TradeOrderValidator.validate(
          context: _ctx(availableStockpileByCommodityId: const {}),
          proposedOrders: [_offer('timber', 1)],
        );
        expect(
          results.single.reason,
          TradeOrderRejectionReasons.offerExceedsStockpile,
        );
      },
    );

    test('offer quantity == availableStockpile is accepted (inclusive)', () {
      final results = TradeOrderValidator.validate(
        context: _ctx(availableStockpileByCommodityId: {'timber': 10}),
        proposedOrders: [_offer('timber', 10)],
      );
      expect(results.single.isAccepted, isTrue);
    });
  });

  group('TradeOrderValidator.validate — rule precedence', () {
    test(
      'mutualExclusion takes precedence over bidTypeCapExceeded (rule 3 '
      'before rule 4)',
      () {
        final results = TradeOrderValidator.validate(
          context: _ctx(
            bidTypeCap: 0, // every bid would otherwise hit rule 4
            availableStockpileByCommodityId: {'timber': 50},
          ),
          proposedOrders: [_bid('timber', 5), _offer('timber', 5)],
        );
        expect(
          results[0].reason,
          TradeOrderRejectionReasons.mutualExclusion,
          reason: 'Rule 3 fires before rule 4.',
        );
      },
    );

    test(
      'richesNotTradeable takes precedence over mutualExclusion (rule 2 '
      'before rule 3)',
      () {
        final results = TradeOrderValidator.validate(
          context: _ctx(availableStockpileByCommodityId: {'gold': 50}),
          proposedOrders: [_bid('gold', 5), _offer('gold', 5)],
        );
        for (final r in results) {
          expect(
            r.reason,
            TradeOrderRejectionReasons.richesNotTradeable,
          );
        }
      },
    );
  });
}

TradeOrder _bid(String commodityId, int quantity, {int priority = 1}) =>
    TradeOrder(
      commodityId: commodityId,
      type: TradeOrderType.bid,
      quantity: quantity,
      priority: priority,
    );

TradeOrder _offer(String commodityId, int quantity, {int priority = 1}) =>
    TradeOrder(
      commodityId: commodityId,
      type: TradeOrderType.offer,
      quantity: quantity,
      priority: priority,
    );

TradeOrderValidationContext _ctx({
  String playerId = 'gp1',
  int bidTypeCap = 6,
  int tradeCargoCapacity = 100,
  Map<CommodityId, int> availableStockpileByCommodityId =
      const <CommodityId, int>{},
}) =>
    TradeOrderValidationContext(
      playerId: playerId,
      bidTypeCap: bidTypeCap,
      tradeCargoCapacity: tradeCargoCapacity,
      availableStockpileByCommodityId: availableStockpileByCommodityId,
    );
