import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

import 'world_market_trade_order_validator_test_support.dart';

/// Tests for `TradeOrderValidator` rules 4–6 (bid type cap, bid cargo cap,
/// offer stockpile) and cross-rule precedence per
/// `SPEC/program/world-market-resolution.md` § Trade order validation.
/// Empty / accept paths and rules 1–3 live in
/// `world_market_trade_order_validator_test.dart`.
/// Refs #2989 A5.
void main() {
  group('TradeOrderValidator.validate — rule 4: bid type cap', () {
    test('bidTypeCap = 0 rejects every bid with bidTypeCapExceeded', () {
      final results = TradeOrderValidator.validate(
        context: validatorCtx(bidTypeCap: 0),
        proposedOrders: [validatorBid('timber', 5), validatorBid('iron', 5)],
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
          context: validatorCtx(
            bidTypeCap: 0,
            availableStockpileByCommodityId: {
              'timber': 50,
              'iron': 50,
              'coal': 50,
            },
          ),
          proposedOrders: [
            validatorOffer('timber', 5),
            validatorOffer('iron', 5),
            validatorOffer('coal', 5),
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
          context: validatorCtx(bidTypeCap: 3),
          proposedOrders: [
            validatorBid('timber', 5),
            validatorBid('iron', 5),
            validatorBid('coal', 5),
            validatorBid('wool', 5),
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
          context: validatorCtx(bidTypeCap: 6),
          proposedOrders: [
            validatorBid('timber', 5),
            validatorBid('iron', 5),
            validatorBid('coal', 5),
            validatorBid('wool', 5),
            validatorBid('hides', 5),
            validatorBid('cattle', 5),
            validatorBid('grain', 5),
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
          context: validatorCtx(bidTypeCap: 2),
          proposedOrders: [
            validatorBid('a', 5, priority: 1),
            validatorBid('b', 5, priority: 1),
            validatorBid('c', 5, priority: 1),
            validatorBid('a', 5, priority: 2),
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
        context: validatorCtx(tradeCargoCapacity: 10),
        proposedOrders: [validatorBid('timber', 12)],
      );
      expect(
        results.single.reason,
        TradeOrderRejectionReasons.bidExceedsCargoCapacity,
      );
    });

    test('bid quantity == tradeCargoCapacity is accepted (inclusive)', () {
      final results = TradeOrderValidator.validate(
        context: validatorCtx(tradeCargoCapacity: 10),
        proposedOrders: [validatorBid('timber', 10)],
      );
      expect(results.single.isAccepted, isTrue);
    });

    test(
      'per-commodity cap is independent: two distinct bids each at capacity '
      'are both accepted (cross-commodity is the matcher\'s job)',
      () {
        final results = TradeOrderValidator.validate(
          context: validatorCtx(bidTypeCap: 2, tradeCargoCapacity: 10),
          proposedOrders: [
            validatorBid('timber', 10),
            validatorBid('iron', 10),
          ],
        );
        expect(results[0].isAccepted, isTrue);
        expect(results[1].isAccepted, isTrue);
      },
    );
  });

  group('TradeOrderValidator.validate — rule 6: offer stockpile', () {
    test('offer quantity > availableStockpile is rejected', () {
      final results = TradeOrderValidator.validate(
        context: validatorCtx(availableStockpileByCommodityId: {'timber': 5}),
        proposedOrders: [validatorOffer('timber', 10)],
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
          context: validatorCtx(availableStockpileByCommodityId: const {}),
          proposedOrders: [validatorOffer('timber', 1)],
        );
        expect(
          results.single.reason,
          TradeOrderRejectionReasons.offerExceedsStockpile,
        );
      },
    );

    test('offer quantity == availableStockpile is accepted (inclusive)', () {
      final results = TradeOrderValidator.validate(
        context: validatorCtx(availableStockpileByCommodityId: {'timber': 10}),
        proposedOrders: [validatorOffer('timber', 10)],
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
          context: validatorCtx(
            bidTypeCap: 0, // every bid would otherwise hit rule 4
            availableStockpileByCommodityId: {'timber': 50},
          ),
          proposedOrders: [
            validatorBid('timber', 5),
            validatorOffer('timber', 5),
          ],
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
          context: validatorCtx(availableStockpileByCommodityId: {'gold': 50}),
          proposedOrders: [
            validatorBid('gold', 5),
            validatorOffer('gold', 5),
          ],
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
