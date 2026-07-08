// Rule 5 treasury-cap validator scenarios (Refs #3093, #3123, #3939 phase 3 slice 30).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'trade_order_validator_test_support.dart';
import 'validator_expectations.dart';
import 'validator_scenario.dart';

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
    context: validatorCtxCatalogDefaults(treasuryBudgetForBids: 0),
    proposedOrders: [validatorBid('not_a_real_commodity', 10)],
    expect: const ValidatorExpectation(singleAccepted: true),
    refs: '#3093',
  ),
  TradeOrderValidatorScenario.expect(
    label: 'manufactured commodity bids now consume the catalog base price '
        '(Refs #3093 manufactured-default-prices slice)',
    context: validatorCtxCatalogDefaults(treasuryBudgetForBids: 100),
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
    context: validatorCtxCatalogDefaults(
      treasuryBudgetForBids: _catalogTimberBudgetForQty2(),
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
    context: validatorCtxLumberBudget(
      treasuryBudgetForBids: _catalogLumberBudgetForQty1(),
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
