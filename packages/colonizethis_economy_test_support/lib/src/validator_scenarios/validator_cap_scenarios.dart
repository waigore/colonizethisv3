// Rule 4–7 and precedence validator scenarios (Refs #3836, #3939 phase 3 slice 30).

import 'package:colonizethis_economy/colonizethis_economy.dart';

import 'trade_order_validator_test_support.dart';
import 'validator_expectations.dart';
import 'validator_scenario.dart';

/// Rule 4–7 and precedence scenarios from
/// `world_market_trade_order_validator_caps_test.dart`.
List<TradeOrderValidatorScenario> tradeOrderValidatorCapScenarios() => [
  validatorRow(
    label: 'bidTypeCap = 0 rejects every bid with bidTypeCapExceeded',
    context: validatorCtx(bidTypeCap: 0),
    proposedOrders: [validatorBid('timber', 5), validatorBid('iron', 5)],
    expect: const ValidatorExpectation(
      allRejectedWithReason: TradeOrderRejectionReasons.bidTypeCapExceeded,
    ),
  ),
  validatorRow(
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
  ),
  validatorRow(
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
  ),
  validatorRow(
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
  ),
  validatorRow(
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
  ),
  validatorRejectRow(
    label: 'bid quantity > tradeCargoCapacity is rejected',
    context: validatorCtx(tradeCargoCapacity: 10),
    order: validatorBid('timber', 12),
    reason: TradeOrderRejectionReasons.bidExceedsCargoCapacity,
  ),
  validatorRow(
    label: 'bid quantity == tradeCargoCapacity is accepted (inclusive)',
    context: validatorCtx(tradeCargoCapacity: 10),
    proposedOrders: [validatorBid('timber', 10)],
    expect: const ValidatorExpectation(singleAccepted: true),
  ),
  validatorRow(
    label: 'per-commodity cap is independent: two distinct bids each at capacity '
        'are both accepted (cross-commodity is the matcher\'s job)',
    context: validatorCtx(bidTypeCap: 2, tradeCargoCapacity: 10),
    proposedOrders: [validatorBid('timber', 10), validatorBid('iron', 10)],
    expect: const ValidatorExpectation(allAccepted: true),
  ),
  validatorRejectRow(
    label: 'offer quantity > availableStockpile is rejected',
    context: validatorCtxWithStockpile({'timber': 5}),
    order: validatorOffer('timber', 10),
    reason: TradeOrderRejectionReasons.offerExceedsStockpile,
  ),
  validatorRejectRow(
    label: 'offer with no entry in availableStockpileByCommodityId is treated as '
        'available = 0 and rejected for any positive quantity',
    context: validatorCtxWithStockpile(const {}),
    order: validatorOffer('timber', 1),
    reason: TradeOrderRejectionReasons.offerExceedsStockpile,
  ),
  validatorRow(
    label: 'offer quantity == availableStockpile is accepted (inclusive)',
    context: validatorCtxWithStockpile({'timber': 10}),
    proposedOrders: [validatorOffer('timber', 10)],
    expect: const ValidatorExpectation(singleAccepted: true),
  ),
  validatorRow(
    label: 'mutualExclusion takes precedence over bidTypeCapExceeded (rule 3 '
        'before rule 4)',
    context: validatorCtxWithStockpile(
      {'timber': 50},
      bidTypeCap: 0,
    ),
    proposedOrders: [
      validatorBid('timber', 5),
      validatorOffer('timber', 5),
    ],
    expect: const ValidatorExpectation(
      firstOrderReason: TradeOrderRejectionReasons.mutualExclusion,
    ),
  ),
  validatorRow(
    label: 'richesNotTradeable takes precedence over mutualExclusion (rule 2 '
        'before rule 3)',
    context: validatorCtxWithStockpile({'gold': 50}),
    proposedOrders: [validatorBid('gold', 5), validatorOffer('gold', 5)],
    expect: const ValidatorExpectation(
      allSameReason: TradeOrderRejectionReasons.richesNotTradeable,
    ),
  ),
];
