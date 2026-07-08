// Table-driven TradeOrderValidator cap scenarios (Refs #3836).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

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
    expect: const ValidatorExpectation(
      firstOrderReason: TradeOrderRejectionReasons.mutualExclusion,
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
    expect: const ValidatorExpectation(
      singleRejectedWithReason: TradeOrderRejectionReasons.invalidQuantity,
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
      expect: const ValidatorExpectation(
        singleRejectedWithReason:
            TradeOrderRejectionReasons.richesNotTradeable,
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
int _catalogTimberBudgetForQty2() {
  final int? catalogTimber = ResourceRules.defaultRules
      .defaultMarketPriceForCommodityId(CommodityCatalog.timber.id);
  return catalogTimber! * 2;
}

int _catalogLumberBudgetForQty1() {
  final int? catalogLumber = ResourceRules.defaultRules
      .defaultMarketPriceForCommodityId(CommodityCatalog.lumber.id);
  return catalogLumber!;
}

/// Rule 5 treasury-cap scenarios from
/// `world_market_trade_order_validator_treasury_test.dart`.
List<TradeOrderValidatorScenario> tradeOrderValidatorTreasuryScenarios() => [
  ...tradeOrderValidatorTreasuryCapScenarios(),
  ...tradeOrderValidatorTreasuryCatalogScenarios(),
];

List<TradeOrderValidatorScenario> tradeOrderValidatorTreasuryCapScenarios() => [
  TradeOrderValidatorScenario.expect(
    label: 'rejects bid when cumulative spend exceeds treasuryBudgetForBids',
    context: validatorCtxTimberIron(treasuryBudgetForBids: 60),
    proposedOrders: [
      validatorBid(CommodityCatalog.timber.id, 1),
      validatorBid(CommodityCatalog.iron.id, 2),
    ],
    expect: ValidatorExpectation(
      outcomes: [
        (accepted: true, reason: null),
        (
          accepted: false,
          reason: TradeOrderRejectionReasons.bidExceedsTreasuryBudget,
        ),
      ],
    ),
    refs: '#3093',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'accepts bids whose cumulative spend equals treasuryBudgetForBids',
    context: validatorCtxTimber(treasuryBudgetForBids: 60),
    proposedOrders: [validatorBid(CommodityCatalog.timber.id, 2)],
    expect: const ValidatorExpectation(singleAccepted: true),
    refs: '#3093',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'treasury cap takes precedence over bidExceedsCargoCapacity (rule 5 '
        'before rule 6)',
    context: validatorCtxTimber(
      tradeCargoCapacity: 100,
      treasuryBudgetForBids: 10,
    ),
    proposedOrders: [validatorBid(CommodityCatalog.timber.id, 5)],
    expect: ValidatorExpectation(
      singleRejectedWithReason:
          TradeOrderRejectionReasons.bidExceedsTreasuryBudget,
    ),
    refs: '#3093',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'bids with no effective market price contribute zero treasury spend '
        '(defensive guard against unknown / future commodity ids)',
    context: validatorCtx(
      treasuryBudgetForBids: 0,
      worldMarketState: const WorldMarketState(),
    ),
    proposedOrders: [validatorBid('not_a_real_commodity', 10)],
    expect: const ValidatorExpectation(singleAccepted: true),
    refs: '#3093',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'manufactured commodity bids now consume the catalog base price '
        '(Refs #3093 manufactured-default-prices slice)',
    context: validatorCtx(
      treasuryBudgetForBids: 100,
      worldMarketState: const WorldMarketState(),
    ),
    proposedOrders: [validatorBid(CommodityCatalog.lumber.id, 10)],
    expect: ValidatorExpectation(
      singleRejectedWithReason:
          TradeOrderRejectionReasons.bidExceedsTreasuryBudget,
    ),
    refs: '#3093',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'accepts cumulative spend equal to treasuryBudgetForBids across '
        'distinct commodities in submission order (Refs #3123)',
    context: validatorCtxTimberIron(
      treasuryBudgetForBids: 100,
      timberPrice: 30,
      ironPrice: 10,
    ),
    proposedOrders: [
      validatorBid(CommodityCatalog.timber.id, 2),
      validatorBid(CommodityCatalog.iron.id, 4),
    ],
    expect: const ValidatorExpectation(allAccepted: true),
    refs: '#3123',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'rejected bid does not consume the running spend budget — greedy '
        'continuation admits a later smaller bid that fits (Refs #3123)',
    context: validatorCtxTimberIron(
      treasuryBudgetForBids: 100,
      timberPrice: 30,
      ironPrice: 10,
    ),
    proposedOrders: [
      validatorBid(CommodityCatalog.timber.id, 4),
      validatorBid(CommodityCatalog.iron.id, 1),
    ],
    expect: ValidatorExpectation(
      outcomes: [
        (
          accepted: false,
          reason: TradeOrderRejectionReasons.bidExceedsTreasuryBudget,
        ),
        (accepted: true, reason: null),
      ],
      orderAcceptedPin: (
        index: 1,
        accepted: true,
        reason:
            'greedy continuation: rejected bid must not consume '
            'the running spend budget so a later bid that fits the '
            'remaining budget is admitted',
      ),
    ),
    refs: '#3123',
  ),
];

List<TradeOrderValidatorScenario> tradeOrderValidatorTreasuryCatalogScenarios() =>
    [
  TradeOrderValidatorScenario.expect(
    label: 'treasuryBudgetForBids == 0 rejects every priced bid (Refs #3123)',
    context: validatorCtxTimber(treasuryBudgetForBids: 0),
    proposedOrders: [
      validatorBid(CommodityCatalog.timber.id, 1),
      validatorBid(CommodityCatalog.timber.id, 5),
    ],
    expect: const ValidatorExpectation(
      allRejectedWithReason:
          TradeOrderRejectionReasons.bidExceedsTreasuryBudget,
    ),
    refs: '#3123',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'admits a bid priced solely from the catalog default when budget '
        'allows (Refs #3123 AC: rule 5 must not reject for unknown price '
        'when an initial/default price exists)',
    context: validatorCtx(
      treasuryBudgetForBids: _catalogTimberBudgetForQty2(),
      worldMarketState: const WorldMarketState(),
    ),
    proposedOrders: [validatorBid(CommodityCatalog.timber.id, 2)],
    expect: ValidatorExpectation(
      catalogDefaultCommodityId: CommodityCatalog.timber.id,
      catalogDefaultNotNullReason:
          'timber must have a catalog default for this AC pin',
      singleAccepted: true,
    ),
    refs: '#3123',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'admits a manufactured-commodity bid priced from the catalog '
        'default when budget allows (Refs #3123 AC, manufactured branch)',
    context: validatorCtx(
      treasuryBudgetForBids: _catalogLumberBudgetForQty1(),
      worldMarketState: const WorldMarketState(),
    ),
    proposedOrders: [validatorBid(CommodityCatalog.lumber.id, 1)],
    expect: ValidatorExpectation(
      catalogDefaultCommodityId: CommodityCatalog.lumber.id,
      catalogDefaultNotNullReason:
          'lumber must have a manufactured catalog default',
      singleAccepted: true,
    ),
    refs: '#3123',
  ),
];

/// One row for `tradeOrderValidationContextFromGame` treasury scenarios.
class TradeOrderValidatorContextScenario {
  const TradeOrderValidatorContextScenario({
    required this.label,
    required this.run,
    this.refs,
  });

  TradeOrderValidatorContextScenario.expect({
    required String label,
    required ValidatorContextExpectation expect,
    String? refs,
  }) : this(
          label: label,
          run: () => assertValidatorContextExpectation(expect),
          refs: refs,
        );

  final String label;
  final void Function() run;
  final String? refs;
}

void runTradeOrderValidatorContextScenario(
  TradeOrderValidatorContextScenario scenario,
) {
  scenario.run();
}

/// Context-from-game treasury scenarios from
/// `world_market_trade_order_validator_context_treasury_test.dart`.
List<TradeOrderValidatorContextScenario>
tradeOrderValidatorContextTreasuryScenarios() => [
  TradeOrderValidatorContextScenario.expect(
    label: 'positive treasury surfaces as TradeOrderValidationContext.'
        'treasuryBudgetForBids',
    expect: const ValidatorContextExpectation(
      target: ValidatorContextScenarioTarget.treasuryBudget,
      treasury: 175,
      treasuryBudgetForBids: 175,
    ),
    refs: '#3123',
  ),
  TradeOrderValidatorContextScenario.expect(
    label: 'treasury at or below zero yields a zero bid budget that rejects any '
        'priced bid end-to-end (negative clamps; zero passes through) '
        '(SPEC/game/world-market.md — cross-commodity bid treasury cap)',
    expect: const ValidatorContextExpectation(
      target: ValidatorContextScenarioTarget.treasuryClampsRejectPricedBid,
    ),
    refs: '#3123',
  ),
  TradeOrderValidatorContextScenario.expect(
    label: 'ghost player id returns a zero-budget context (ghost guard)',
    expect: const ValidatorContextExpectation(
      target: ValidatorContextScenarioTarget.ghostPlayerZeroBudget,
      treasury: 200,
    ),
    refs: '#3123',
  ),
  TradeOrderValidatorContextScenario.expect(
    label: 'caller-supplied projectedTreasuryDelta reduces the budget by the '
        'projected non-bid deficit (Refs #3290 economy->orders inversion)',
    expect: const ValidatorContextExpectation(
      target: ValidatorContextScenarioTarget.projectedDeltaReducesBudget,
      treasury: 175,
      treasuryBudgetForBids: 125,
      projectedTreasuryDelta: -50,
    ),
    refs: '#3290',
  ),
  TradeOrderValidatorContextScenario.expect(
    label: 'caller-supplied non-negative projectedTreasuryDelta leaves the raw '
        'treasury budget unchanged (income does not raise the budget)',
    expect: const ValidatorContextExpectation(
      target: ValidatorContextScenarioTarget.nonNegativeProjectedDeltaUnchanged,
      treasury: 175,
      treasuryBudgetForBids: 175,
      projectedTreasuryDelta: 40,
    ),
    refs: '#3290',
  ),
  TradeOrderValidatorContextScenario.expect(
    label: 'omitting projectedTreasuryDelta keeps the raw-treasury budget even '
        'when staged orders are supplied',
    expect: const ValidatorContextExpectation(
      target: ValidatorContextScenarioTarget.omitProjectedDeltaUnchanged,
      treasury: 175,
      treasuryBudgetForBids: 175,
    ),
    refs: '#3123',
  ),
];
