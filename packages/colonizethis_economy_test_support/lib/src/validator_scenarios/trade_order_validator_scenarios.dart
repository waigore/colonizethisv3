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
  TradeOrderValidatorScenario.expect(
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
    expect: ValidatorExpectation(
      firstNAccepted: 6,
      thenRejectedWithReason: TradeOrderRejectionReasons.bidTypeCapExceeded,
    ),
    refs: '#2989',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'bidTypeCap submission order determines which commodities are admitted',
    context: validatorCtx(bidTypeCap: 2),
    proposedOrders: [
      validatorBid('a', 5, priority: 1),
      validatorBid('b', 5, priority: 1),
      validatorBid('c', 5, priority: 1),
      validatorBid('a', 5, priority: 2),
    ],
    expect: ValidatorExpectation(
      outcomes: [
        (accepted: true, reason: null),
        (accepted: true, reason: null),
        (
          accepted: false,
          reason: TradeOrderRejectionReasons.bidTypeCapExceeded,
        ),
        (accepted: true, reason: null),
      ],
    ),
    refs: '#2989',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'bid quantity > tradeCargoCapacity is rejected',
    context: validatorCtx(tradeCargoCapacity: 10),
    proposedOrders: [validatorBid('timber', 12)],
    expect: ValidatorExpectation(
      singleRejectedWithReason:
          TradeOrderRejectionReasons.bidExceedsCargoCapacity,
    ),
    refs: '#2989',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'bid quantity == tradeCargoCapacity is accepted (inclusive)',
    context: validatorCtx(tradeCargoCapacity: 10),
    proposedOrders: [validatorBid('timber', 10)],
    expect: const ValidatorExpectation(singleAccepted: true),
    refs: '#2989',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'per-commodity cap is independent: two distinct bids each at capacity '
        'are both accepted (cross-commodity is the matcher\'s job)',
    context: validatorCtx(bidTypeCap: 2, tradeCargoCapacity: 10),
    proposedOrders: [validatorBid('timber', 10), validatorBid('iron', 10)],
    expect: const ValidatorExpectation(allAccepted: true),
    refs: '#2989',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'offer quantity > availableStockpile is rejected',
    context: validatorCtx(availableStockpileByCommodityId: {'timber': 5}),
    proposedOrders: [validatorOffer('timber', 10)],
    expect: ValidatorExpectation(
      singleRejectedWithReason:
          TradeOrderRejectionReasons.offerExceedsStockpile,
    ),
    refs: '#2989',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'offer with no entry in availableStockpileByCommodityId is treated as '
        'available = 0 and rejected for any positive quantity',
    context: validatorCtx(availableStockpileByCommodityId: const {}),
    proposedOrders: [validatorOffer('timber', 1)],
    expect: ValidatorExpectation(
      singleRejectedWithReason:
          TradeOrderRejectionReasons.offerExceedsStockpile,
    ),
    refs: '#2989',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'offer quantity == availableStockpile is accepted (inclusive)',
    context: validatorCtx(availableStockpileByCommodityId: {'timber': 10}),
    proposedOrders: [validatorOffer('timber', 10)],
    expect: const ValidatorExpectation(singleAccepted: true),
    refs: '#2989',
  ),
  TradeOrderValidatorScenario.expect(
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
    expect: ValidatorExpectation(
      custom: (results) => expect(
        results[0].reason,
        TradeOrderRejectionReasons.mutualExclusion,
        reason: 'Rule 3 fires before rule 4.',
      ),
    ),
    refs: '#2989',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'richesNotTradeable takes precedence over mutualExclusion (rule 2 '
        'before rule 3)',
    context: validatorCtx(availableStockpileByCommodityId: {'gold': 50}),
    proposedOrders: [validatorBid('gold', 5), validatorOffer('gold', 5)],
    expect: const ValidatorExpectation(
      allSameReason: TradeOrderRejectionReasons.richesNotTradeable,
    ),
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
  TradeOrderValidatorScenario.expect(
    label: 'empty proposed orders returns empty result list',
    context: validatorCtx(),
    proposedOrders: const [],
    expect: const ValidatorExpectation(resultsEmpty: true),
    refs: '#2989',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'single valid offer is accepted (stockpile covers, not riches, not '
        'mutually excluded)',
    context: validatorCtx(availableStockpileByCommodityId: {'timber': 50}),
    proposedOrders: [validatorOffer('timber', 10)],
    expect: const ValidatorExpectation(singleAccepted: true),
    refs: '#2989',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'single valid bid is accepted (within cargo, distinct-bid cap, not '
        'riches, not mutually excluded)',
    context: validatorCtx(),
    proposedOrders: [validatorBid('timber', 10)],
    expect: const ValidatorExpectation(singleAccepted: true),
    refs: '#2989',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'second bid on same commodity does not consume a new cap slot '
        '(rule 4 counts distinct commodities)',
    context: validatorCtx(bidTypeCap: 3),
    proposedOrders: [
      validatorBid('timber', 5, priority: 1),
      validatorBid('iron', 5, priority: 1),
      validatorBid('coal', 5, priority: 1),
      validatorBid('timber', 5, priority: 2),
    ],
    expect: const ValidatorExpectation(allAccepted: true),
    refs: '#2989',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'parallel result list is index-aligned to proposed orders',
    context: validatorCtx(),
    proposedOrders: [
      validatorBid('timber', 5),
      validatorBid('timber', 0),
      validatorBid('timber', 5),
    ],
    expect: ValidatorExpectation(
      outcomes: [
        (accepted: true, reason: null),
        (
          accepted: false,
          reason: TradeOrderRejectionReasons.invalidQuantity,
        ),
        (accepted: true, reason: null),
      ],
    ),
    refs: '#2989',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'quantity == 0 is rejected with invalidQuantity',
    context: validatorCtx(),
    proposedOrders: [validatorBid('timber', 0)],
    expect: ValidatorExpectation(
      outcomes: [
        (
          accepted: false,
          reason: TradeOrderRejectionReasons.invalidQuantity,
        ),
      ],
    ),
    refs: '#2989',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'invalidQuantity takes precedence over richesNotTradeable for a '
        'zero-quantity riches order',
    context: validatorCtx(),
    proposedOrders: [validatorOffer('spices', 0)],
    expect: ValidatorExpectation(
      custom: (results) => expect(
        results.single.reason,
        TradeOrderRejectionReasons.invalidQuantity,
        reason: 'Rule 1 evaluates before rule 2 per SPEC.',
      ),
    ),
    refs: '#2989',
  ),
  ...[
    'spices',
    'silver',
    'gold',
    'gems',
    'diamonds',
  ].map(
    (id) => TradeOrderValidatorScenario.expect(
      label: 'riches offer $id is rejected with richesNotTradeable (offer side)',
      context: validatorCtx(availableStockpileByCommodityId: {id: 999}),
      proposedOrders: [validatorOffer(id, 5)],
      expect: ValidatorExpectation(
        custom: (results) => expect(
          results.single.reason,
          TradeOrderRejectionReasons.richesNotTradeable,
          reason: 'Riches commodity $id must not be tradeable',
        ),
      ),
      refs: '#2989',
    ),
  ),
  TradeOrderValidatorScenario.expect(
    label: 'riches bid is also rejected with richesNotTradeable',
    context: validatorCtx(),
    proposedOrders: [validatorBid('gold', 5)],
    expect: ValidatorExpectation(
      singleRejectedWithReason:
          TradeOrderRejectionReasons.richesNotTradeable,
    ),
    refs: '#2989',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'commodity appearing as both bid and offer rejects both sides with '
        'mutualExclusion',
    context: validatorCtx(availableStockpileByCommodityId: {'timber': 50}),
    proposedOrders: [
      validatorBid('timber', 5),
      validatorOffer('timber', 5),
    ],
    expect: const ValidatorExpectation(
      allSameReason: TradeOrderRejectionReasons.mutualExclusion,
    ),
    refs: '#2989',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'bid-on-A + offer-on-B is allowed (mutual exclusion is per-commodity, '
        'not per-player)',
    context: validatorCtx(availableStockpileByCommodityId: {'iron': 50}),
    proposedOrders: [validatorBid('timber', 5), validatorOffer('iron', 5)],
    expect: const ValidatorExpectation(allAccepted: true),
    refs: '#2989',
  ),
  TradeOrderValidatorScenario.expect(
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
    expect: ValidatorExpectation(
      outcomes: [
        (
          accepted: false,
          reason: TradeOrderRejectionReasons.mutualExclusion,
        ),
        (
          accepted: false,
          reason: TradeOrderRejectionReasons.mutualExclusion,
        ),
        (accepted: true, reason: null),
        (accepted: true, reason: null),
        (accepted: true, reason: null),
      ],
    ),
    refs: '#2989',
  ),
];
