// Rules 1–3 and empty/accept validator scenarios (Refs #3856, #3939 phase 3 slice 30).

import 'package:colonizethis_economy/colonizethis_economy.dart';

import 'trade_order_validator_test_support.dart';
import 'validator_expectations.dart';
import 'validator_scenario.dart';

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
  validatorRow(
    label: 'empty proposed orders returns empty result list',
    expect: const ValidatorExpectation(resultsEmpty: true),
  ),
  validatorRow(
    label: 'single valid offer is accepted (stockpile covers, not riches, not '
        'mutually excluded)',
    context: validatorCtxWithStockpile({'timber': 50}),
    proposedOrders: [validatorOffer('timber', 10)],
    expect: const ValidatorExpectation(singleAccepted: true),
  ),
  validatorRow(
    label: 'single valid bid is accepted (within cargo, distinct-bid cap, not '
        'riches, not mutually excluded)',
    proposedOrders: [validatorBid('timber', 10)],
    expect: const ValidatorExpectation(singleAccepted: true),
  ),
  validatorRow(
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
  ),
  validatorRow(
    label: 'parallel result list is index-aligned to proposed orders',
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
  ),
  validatorRejectRow(
    label: 'quantity == 0 is rejected with invalidQuantity',
    order: validatorBid('timber', 0),
    reason: TradeOrderRejectionReasons.invalidQuantity,
  ),
  validatorRejectRow(
    label: 'invalidQuantity takes precedence over richesNotTradeable for a '
        'zero-quantity riches order',
    order: validatorOffer('spices', 0),
    reason: TradeOrderRejectionReasons.invalidQuantity,
  ),
  ...[
    'spices',
    'silver',
    'gold',
    'gems',
    'diamonds',
  ].map(
    (id) => validatorRejectRow(
      label: 'riches offer $id is rejected with richesNotTradeable (offer side)',
      context: validatorCtx(availableStockpileByCommodityId: {id: 999}),
      order: validatorOffer(id, 5),
      reason: TradeOrderRejectionReasons.richesNotTradeable,
    ),
  ),
  validatorRejectRow(
    label: 'riches bid is also rejected with richesNotTradeable',
    order: validatorBid('gold', 5),
    reason: TradeOrderRejectionReasons.richesNotTradeable,
  ),
  validatorRow(
    label: 'commodity appearing as both bid and offer rejects both sides with '
        'mutualExclusion',
    context: validatorCtxWithStockpile({'timber': 50}),
    proposedOrders: [
      validatorBid('timber', 5),
      validatorOffer('timber', 5),
    ],
    expect: const ValidatorExpectation(
      allSameReason: TradeOrderRejectionReasons.mutualExclusion,
    ),
  ),
  validatorRow(
    label: 'bid-on-A + offer-on-B is allowed (mutual exclusion is per-commodity, '
        'not per-player)',
    context: validatorCtxWithStockpile({'iron': 50}),
    proposedOrders: [validatorBid('timber', 5), validatorOffer('iron', 5)],
    expect: const ValidatorExpectation(allAccepted: true),
  ),
  validatorRow(
    label: 'mutually excluded commodity does not consume a bid-type cap slot',
    context: validatorCtxWithStockpile(
      {'timber': 50},
      bidTypeCap: 3,
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
  ),
];
