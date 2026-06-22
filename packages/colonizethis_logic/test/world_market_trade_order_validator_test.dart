import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_test/test.dart';

import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';

/// Tests for `TradeOrderValidator` rules 1–3 (invalid quantity, riches not
/// tradeable, mutual exclusion) plus empty / accept paths per
/// `SPEC/program/world-market-resolution.md` § Trade order validation.
/// Cap-related rules (4–6) and precedence cases live in
/// `world_market_trade_order_validator_caps_test.dart`.
/// Refs #2989 A5.
void main() {
  group('TradeOrderValidator.validate — empty / accept paths', () {
    test('empty proposed orders returns empty result list', () {
      final results = TradeOrderValidator.validate(
        context: validatorCtx(),
        proposedOrders: const [],
      );
      expect(results, isEmpty);
    });

    test(
      'single valid offer is accepted (stockpile covers, not riches, not '
      'mutually excluded)',
      () {
        final results = TradeOrderValidator.validate(
          context: validatorCtx(
            availableStockpileByCommodityId: {'timber': 50},
          ),
          proposedOrders: [validatorOffer('timber', 10)],
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
          context: validatorCtx(),
          proposedOrders: [validatorBid('timber', 10)],
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
          context: validatorCtx(bidTypeCap: 3),
          proposedOrders: [
            validatorBid('timber', 5, priority: 1),
            validatorBid('iron', 5, priority: 1),
            validatorBid('coal', 5, priority: 1),
            validatorBid('timber', 5, priority: 2), // already-admitted commodity
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
          context: validatorCtx(),
          proposedOrders: [
            validatorBid('timber', 5),
            validatorBid('timber', 0), // invalid quantity
            validatorBid('timber', 5),
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
        context: validatorCtx(),
        proposedOrders: [validatorBid('timber', 0)],
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
          context: validatorCtx(),
          proposedOrders: [validatorOffer('spices', 0)],
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
            context: validatorCtx(
              availableStockpileByCommodityId: {id: 999},
            ),
            proposedOrders: [validatorOffer(id, 5)],
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
        context: validatorCtx(),
        proposedOrders: [validatorBid('gold', 5)],
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
          context: validatorCtx(
            availableStockpileByCommodityId: {'timber': 50},
          ),
          proposedOrders: [
            validatorBid('timber', 5),
            validatorOffer('timber', 5),
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
          context: validatorCtx(
            availableStockpileByCommodityId: {'iron': 50},
          ),
          proposedOrders: [
            validatorBid('timber', 5),
            validatorOffer('iron', 5),
          ],
        );
        expect(results[0].isAccepted, isTrue);
        expect(results[1].isAccepted, isTrue);
      },
    );

    test(
      'mutually excluded commodity does not consume a bid-type cap slot',
      () {
        final results = TradeOrderValidator.validate(
          context: validatorCtx(
            bidTypeCap: 3,
            availableStockpileByCommodityId: {'timber': 50},
          ),
          proposedOrders: [
            validatorBid('timber', 5), // mutually excluded with offer below
            validatorOffer('timber', 5),
            validatorBid('iron', 5),
            validatorBid('coal', 5),
            validatorBid('wool', 5),
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
}
