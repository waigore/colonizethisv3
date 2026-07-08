// Table-driven TradeOrderValidator treasury scenarios (Refs #3836).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'trade_order_validator_scenarios.dart';
import 'trade_order_validator_test_support.dart';
import 'validator_context_expectations.dart';
import 'validator_expectations.dart';

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
    context: validatorCtx(
      treasuryBudgetForBids: 60,
      worldMarketState: WorldMarketState(
        prices: {
          CommodityCatalog.timber.id: 30,
          CommodityCatalog.iron.id: 30,
        },
      ),
    ),
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
    context: validatorCtx(
      treasuryBudgetForBids: 60,
      worldMarketState: WorldMarketState(
        prices: {CommodityCatalog.timber.id: 30},
      ),
    ),
    proposedOrders: [validatorBid(CommodityCatalog.timber.id, 2)],
    expect: const ValidatorExpectation(singleAccepted: true),
    refs: '#3093',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'treasury cap takes precedence over bidExceedsCargoCapacity (rule 5 '
        'before rule 6)',
    context: validatorCtx(
      tradeCargoCapacity: 100,
      treasuryBudgetForBids: 10,
      worldMarketState: WorldMarketState(
        prices: {CommodityCatalog.timber.id: 30},
      ),
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
    context: validatorCtx(
      treasuryBudgetForBids: 100,
      worldMarketState: WorldMarketState(
        prices: {
          CommodityCatalog.timber.id: 30,
          CommodityCatalog.iron.id: 10,
        },
      ),
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
    context: validatorCtx(
      treasuryBudgetForBids: 100,
      tradeCargoCapacity: 100,
      worldMarketState: WorldMarketState(
        prices: {
          CommodityCatalog.timber.id: 30,
          CommodityCatalog.iron.id: 10,
        },
      ),
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
    context: validatorCtx(
      treasuryBudgetForBids: 0,
      worldMarketState: WorldMarketState(
        prices: {CommodityCatalog.timber.id: 30},
      ),
    ),
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
