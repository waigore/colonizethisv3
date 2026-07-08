// Table-driven TradeOrderValidator cap scenarios (Refs #3836).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'trade_order_validator_test_support.dart';
import 'validator_expectations.dart';

/// One row for validator cap / precedence scenarios.
class TradeOrderValidatorScenario {
  const TradeOrderValidatorScenario({
    required this.label,
    required this.context,
    required this.proposedOrders,
    required this.verify,
    this.refs,
  });

  TradeOrderValidatorScenario.expect({
    required String label,
    required TradeOrderValidationContext context,
    required List<TradeOrder> proposedOrders,
    required ValidatorExpectation expect,
    String? refs,
  }) : this(
          label: label,
          context: context,
          proposedOrders: proposedOrders,
          verify: (results) => assertValidatorExpectation(results, expect),
          refs: refs,
        );

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
  TradeOrderValidatorScenario.expect(
    label: 'bidTypeCap = 0 rejects every bid with bidTypeCapExceeded',
    context: validatorCtx(bidTypeCap: 0),
    proposedOrders: [validatorBid('timber', 5), validatorBid('iron', 5)],
    expect: const ValidatorExpectation(
      allRejectedWithReason: TradeOrderRejectionReasons.bidTypeCapExceeded,
    ),
    refs: '#2989',
  ),
  TradeOrderValidatorScenario.expect(
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
    expect: const ValidatorExpectation(allAccepted: true),
    refs: '#2989',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'bidTypeCap = 3 accepts first 3 distinct bid commodities, rejects 4th',
    context: validatorCtx(bidTypeCap: 3),
    proposedOrders: [
      validatorBid('timber', 5),
      validatorBid('iron', 5),
      validatorBid('coal', 5),
      validatorBid('wool', 5),
    ],
    expect: ValidatorExpectation(
      outcomes: [
        (accepted: true, reason: null),
        (accepted: true, reason: null),
        (accepted: true, reason: null),
        (
          accepted: false,
          reason: TradeOrderRejectionReasons.bidTypeCapExceeded,
        ),
      ],
    ),
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

/// Rules 1–3 and empty/accept paths from
/// `world_market_trade_order_validator_test.dart` (Refs #3856 slice 8).
List<TradeOrderValidatorScenario> tradeOrderValidatorEmptyAcceptScenarios() =>
    tradeOrderValidatorRulesScenarios().take(5).toList();

List<TradeOrderValidatorScenario> tradeOrderValidatorRule1Scenarios() =>
    tradeOrderValidatorRulesScenarios().skip(5).take(2).toList();

List<TradeOrderValidatorScenario> tradeOrderValidatorRule2Scenarios() =>
    tradeOrderValidatorRulesScenarios().skip(7).take(6).toList();

List<TradeOrderValidatorScenario> tradeOrderValidatorRule3Scenarios() =>
    tradeOrderValidatorRulesScenarios().skip(13).toList();

List<TradeOrderValidatorScenario> tradeOrderValidatorRulesScenarios() => [
  TradeOrderValidatorScenario(
    label: 'empty proposed orders returns empty result list',
    context: validatorCtx(),
    proposedOrders: const [],
    verify: (results) => expect(results, isEmpty),
    refs: '#2989',
  ),
  TradeOrderValidatorScenario(
    label: 'single valid offer is accepted (stockpile covers, not riches, not '
        'mutually excluded)',
    context: validatorCtx(availableStockpileByCommodityId: {'timber': 50}),
    proposedOrders: [validatorOffer('timber', 10)],
    verify: (results) {
      expect(results, hasLength(1));
      expect(results.single.isAccepted, isTrue);
    },
    refs: '#2989',
  ),
  TradeOrderValidatorScenario(
    label: 'single valid bid is accepted (within cargo, distinct-bid cap, not '
        'riches, not mutually excluded)',
    context: validatorCtx(),
    proposedOrders: [validatorBid('timber', 10)],
    verify: (results) {
      expect(results, hasLength(1));
      expect(results.single.isAccepted, isTrue);
    },
    refs: '#2989',
  ),
  TradeOrderValidatorScenario(
    label: 'second bid on same commodity does not consume a new cap slot '
        '(rule 4 counts distinct commodities)',
    context: validatorCtx(bidTypeCap: 3),
    proposedOrders: [
      validatorBid('timber', 5, priority: 1),
      validatorBid('iron', 5, priority: 1),
      validatorBid('coal', 5, priority: 1),
      validatorBid('timber', 5, priority: 2),
    ],
    verify: (results) {
      for (final r in results) {
        expect(r.isAccepted, isTrue, reason: r.reason);
      }
    },
    refs: '#2989',
  ),
  TradeOrderValidatorScenario(
    label: 'parallel result list is index-aligned to proposed orders',
    context: validatorCtx(),
    proposedOrders: [
      validatorBid('timber', 5),
      validatorBid('timber', 0),
      validatorBid('timber', 5),
    ],
    verify: (results) {
      expect(results, hasLength(3));
      expect(results[0].isAccepted, isTrue);
      expect(results[1].isAccepted, isFalse);
      expect(results[1].reason, TradeOrderRejectionReasons.invalidQuantity);
      expect(results[2].isAccepted, isTrue);
    },
    refs: '#2989',
  ),
  TradeOrderValidatorScenario(
    label: 'quantity == 0 is rejected with invalidQuantity',
    context: validatorCtx(),
    proposedOrders: [validatorBid('timber', 0)],
    verify: (results) {
      expect(results.single.isAccepted, isFalse);
      expect(results.single.reason, TradeOrderRejectionReasons.invalidQuantity);
    },
    refs: '#2989',
  ),
  TradeOrderValidatorScenario(
    label: 'invalidQuantity takes precedence over richesNotTradeable for a '
        'zero-quantity riches order',
    context: validatorCtx(),
    proposedOrders: [validatorOffer('spices', 0)],
    verify: (results) {
      expect(
        results.single.reason,
        TradeOrderRejectionReasons.invalidQuantity,
        reason: 'Rule 1 evaluates before rule 2 per SPEC.',
      );
    },
    refs: '#2989',
  ),
  ...[
    'spices',
    'silver',
    'gold',
    'gems',
    'diamonds',
  ].map(
    (id) => TradeOrderValidatorScenario(
      label: 'riches offer $id is rejected with richesNotTradeable (offer side)',
      context: validatorCtx(availableStockpileByCommodityId: {id: 999}),
      proposedOrders: [validatorOffer(id, 5)],
      verify: (results) {
        expect(
          results.single.reason,
          TradeOrderRejectionReasons.richesNotTradeable,
          reason: 'Riches commodity $id must not be tradeable',
        );
      },
      refs: '#2989',
    ),
  ),
  TradeOrderValidatorScenario(
    label: 'riches bid is also rejected with richesNotTradeable',
    context: validatorCtx(),
    proposedOrders: [validatorBid('gold', 5)],
    verify: (results) {
      expect(
        results.single.reason,
        TradeOrderRejectionReasons.richesNotTradeable,
      );
    },
    refs: '#2989',
  ),
  TradeOrderValidatorScenario(
    label: 'commodity appearing as both bid and offer rejects both sides with '
        'mutualExclusion',
    context: validatorCtx(availableStockpileByCommodityId: {'timber': 50}),
    proposedOrders: [
      validatorBid('timber', 5),
      validatorOffer('timber', 5),
    ],
    verify: (results) {
      for (final r in results) {
        expect(r.isAccepted, isFalse);
        expect(r.reason, TradeOrderRejectionReasons.mutualExclusion);
      }
    },
    refs: '#2989',
  ),
  TradeOrderValidatorScenario(
    label: 'bid-on-A + offer-on-B is allowed (mutual exclusion is per-commodity, '
        'not per-player)',
    context: validatorCtx(availableStockpileByCommodityId: {'iron': 50}),
    proposedOrders: [validatorBid('timber', 5), validatorOffer('iron', 5)],
    verify: (results) {
      expect(results[0].isAccepted, isTrue);
      expect(results[1].isAccepted, isTrue);
    },
    refs: '#2989',
  ),
  TradeOrderValidatorScenario(
    label: 'mutually excluded commodity does not consume a bid-type cap slot',
    context: validatorCtx(
      bidTypeCap: 3,
      availableStockpileByCommodityId: {'timber': 50},
    ),
    proposedOrders: [
      validatorBid('timber', 5),
      validatorOffer('timber', 5),
      validatorBid('iron', 5),
      validatorBid('coal', 5),
      validatorBid('wool', 5),
    ],
    verify: (results) {
      expect(results[0].reason, TradeOrderRejectionReasons.mutualExclusion);
      expect(results[1].reason, TradeOrderRejectionReasons.mutualExclusion);
      expect(results[2].isAccepted, isTrue);
      expect(results[3].isAccepted, isTrue);
      expect(results[4].isAccepted, isTrue);
    },
    refs: '#2989',
  ),
];
