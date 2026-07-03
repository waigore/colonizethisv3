// Table-driven TradeOrderValidator cap scenarios (Refs #3836).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'trade_order_validator_test_support.dart';

/// One row for validator cap / precedence scenarios.
class TradeOrderValidatorScenario {
  const TradeOrderValidatorScenario({
    required this.label,
    required this.context,
    required this.proposedOrders,
    required this.verify,
    this.refs,
  });

  final TradeOrderValidationContext context;
  final List<TradeOrder> proposedOrders;
  final String label;
  final void Function(List<OrderValidationResult> results) verify;
  final String? refs;
}

void runTradeOrderValidatorScenario(TradeOrderValidatorScenario scenario) {
  final results = TradeOrderValidator.validate(
    context: scenario.context,
    proposedOrders: scenario.proposedOrders,
  );
  scenario.verify(results);
}

/// Rule 4–7 and precedence scenarios from
/// `world_market_trade_order_validator_caps_test.dart`.
List<TradeOrderValidatorScenario> tradeOrderValidatorCapScenarios() => [
  TradeOrderValidatorScenario(
    label: 'bidTypeCap = 0 rejects every bid with bidTypeCapExceeded',
    context: validatorCtx(bidTypeCap: 0),
    proposedOrders: [validatorBid('timber', 5), validatorBid('iron', 5)],
    verify: (results) {
      for (final r in results) {
        expect(r.reason, TradeOrderRejectionReasons.bidTypeCapExceeded);
      }
    },
    refs: '#2989',
  ),
  TradeOrderValidatorScenario(
    label: 'bidTypeCap = 0 does NOT affect offers (offers are not capped by '
        'rule 4)',
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
    verify: (results) {
      for (final r in results) {
        expect(r.isAccepted, isTrue, reason: r.reason);
      }
    },
    refs: '#2989',
  ),
  TradeOrderValidatorScenario(
    label: 'bidTypeCap = 3 accepts first 3 distinct bid commodities, rejects 4th',
    context: validatorCtx(bidTypeCap: 3),
    proposedOrders: [
      validatorBid('timber', 5),
      validatorBid('iron', 5),
      validatorBid('coal', 5),
      validatorBid('wool', 5),
    ],
    verify: (results) {
      expect(results[0].isAccepted, isTrue);
      expect(results[1].isAccepted, isTrue);
      expect(results[2].isAccepted, isTrue);
      expect(
        results[3].reason,
        TradeOrderRejectionReasons.bidTypeCapExceeded,
      );
    },
    refs: '#2989',
  ),
  TradeOrderValidatorScenario(
    label: 'bidTypeCap = 6 accepts first 6 distinct bid commodities, rejects 7th',
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
    verify: (results) {
      for (var i = 0; i < 6; i++) {
        expect(results[i].isAccepted, isTrue, reason: results[i].reason);
      }
      expect(
        results[6].reason,
        TradeOrderRejectionReasons.bidTypeCapExceeded,
      );
    },
    refs: '#2989',
  ),
  TradeOrderValidatorScenario(
    label: 'bidTypeCap submission order determines which commodities are admitted',
    context: validatorCtx(bidTypeCap: 2),
    proposedOrders: [
      validatorBid('a', 5, priority: 1),
      validatorBid('b', 5, priority: 1),
      validatorBid('c', 5, priority: 1),
      validatorBid('a', 5, priority: 2),
    ],
    verify: (results) {
      expect(results[0].isAccepted, isTrue);
      expect(results[1].isAccepted, isTrue);
      expect(
        results[2].reason,
        TradeOrderRejectionReasons.bidTypeCapExceeded,
      );
      expect(results[3].isAccepted, isTrue);
    },
    refs: '#2989',
  ),
  TradeOrderValidatorScenario(
    label: 'bid quantity > tradeCargoCapacity is rejected',
    context: validatorCtx(tradeCargoCapacity: 10),
    proposedOrders: [validatorBid('timber', 12)],
    verify: (results) {
      expect(
        results.single.reason,
        TradeOrderRejectionReasons.bidExceedsCargoCapacity,
      );
    },
    refs: '#2989',
  ),
  TradeOrderValidatorScenario(
    label: 'bid quantity == tradeCargoCapacity is accepted (inclusive)',
    context: validatorCtx(tradeCargoCapacity: 10),
    proposedOrders: [validatorBid('timber', 10)],
    verify: (results) {
      expect(results.single.isAccepted, isTrue);
    },
    refs: '#2989',
  ),
  TradeOrderValidatorScenario(
    label: 'per-commodity cap is independent: two distinct bids each at capacity '
        'are both accepted (cross-commodity is the matcher\'s job)',
    context: validatorCtx(bidTypeCap: 2, tradeCargoCapacity: 10),
    proposedOrders: [validatorBid('timber', 10), validatorBid('iron', 10)],
    verify: (results) {
      expect(results[0].isAccepted, isTrue);
      expect(results[1].isAccepted, isTrue);
    },
    refs: '#2989',
  ),
  TradeOrderValidatorScenario(
    label: 'offer quantity > availableStockpile is rejected',
    context: validatorCtx(availableStockpileByCommodityId: {'timber': 5}),
    proposedOrders: [validatorOffer('timber', 10)],
    verify: (results) {
      expect(
        results.single.reason,
        TradeOrderRejectionReasons.offerExceedsStockpile,
      );
    },
    refs: '#2989',
  ),
  TradeOrderValidatorScenario(
    label: 'offer with no entry in availableStockpileByCommodityId is treated as '
        'available = 0 and rejected for any positive quantity',
    context: validatorCtx(availableStockpileByCommodityId: const {}),
    proposedOrders: [validatorOffer('timber', 1)],
    verify: (results) {
      expect(
        results.single.reason,
        TradeOrderRejectionReasons.offerExceedsStockpile,
      );
    },
    refs: '#2989',
  ),
  TradeOrderValidatorScenario(
    label: 'offer quantity == availableStockpile is accepted (inclusive)',
    context: validatorCtx(availableStockpileByCommodityId: {'timber': 10}),
    proposedOrders: [validatorOffer('timber', 10)],
    verify: (results) {
      expect(results.single.isAccepted, isTrue);
    },
    refs: '#2989',
  ),
  TradeOrderValidatorScenario(
    label: 'mutualExclusion takes precedence over bidTypeCapExceeded (rule 3 '
        'before rule 4)',
    context: validatorCtx(
      bidTypeCap: 0,
      availableStockpileByCommodityId: {'timber': 50},
    ),
    proposedOrders: [
      validatorBid('timber', 5),
      validatorOffer('timber', 5),
    ],
    verify: (results) {
      expect(
        results[0].reason,
        TradeOrderRejectionReasons.mutualExclusion,
        reason: 'Rule 3 fires before rule 4.',
      );
    },
    refs: '#2989',
  ),
  TradeOrderValidatorScenario(
    label: 'richesNotTradeable takes precedence over mutualExclusion (rule 2 '
        'before rule 3)',
    context: validatorCtx(availableStockpileByCommodityId: {'gold': 50}),
    proposedOrders: [validatorBid('gold', 5), validatorOffer('gold', 5)],
    verify: (results) {
      for (final r in results) {
        expect(r.reason, TradeOrderRejectionReasons.richesNotTradeable);
      }
    },
    refs: '#2989',
  ),
];
