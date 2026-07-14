// dart format off
// Rule 5 treasury-cap validator scenarios (Refs #3093, #3123, #3939 phase 3 slice 30).
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'trade_order_validator_test_support.dart';
import 'validator_expectations.dart';
import 'validator_scenario.dart';
int _catalogTimberBudgetForQty2() {
  final int? catalogTimber = ResourceRules.defaultRules.defaultMarketPriceForCommodityId('timber');
  return catalogTimber! * 2;
}
int _catalogLumberBudgetForQty1() {
  final int? catalogLumber = ResourceRules.defaultRules.defaultMarketPriceForCommodityId('lumber');
  return catalogLumber!;
}
/// Rule 5 treasury-cap scenarios from
/// `world_market_trade_order_validator_treasury_test.dart`.
List<TradeOrderValidatorScenario> tradeOrderValidatorTreasuryScenarios() => [...tradeOrderValidatorTreasuryCapScenarios(), ...tradeOrderValidatorTreasuryCatalogScenarios()];
List<TradeOrderValidatorScenario> tradeOrderValidatorTreasuryCapScenarios() => [
  validatorTreasuryTimberIronBids(
    label: 'rejects bid when cumulative spend exceeds treasuryBudgetForBids',
    treasuryBudgetForBids: 60,
    proposedOrders: [validatorBid('timber', 1), validatorBid('iron', 2)],
    expect: ValidatorExpectation(outcomes: [(accepted: true, reason: null), (accepted: false, reason: TradeOrderRejectionReasons.bidExceedsTreasuryBudget)]),
    refs: '#3093',
  ),
  validatorTreasuryTimberBid(label: 'accepts bids whose cumulative spend equals treasuryBudgetForBids', treasuryBudgetForBids: 60, bidQty: 2, expect: const ValidatorExpectation(singleAccepted: true), refs: '#3093'),
  validatorTreasuryTimberBid(
    label: 'treasury cap takes precedence over bidExceedsCargoCapacity (rule 5 before rule 6)',
    treasuryBudgetForBids: 10,
    tradeCargoCapacity: 100,
    bidQty: 5,
    expect: ValidatorExpectation(singleRejectedWithReason: TradeOrderRejectionReasons.bidExceedsTreasuryBudget),
    refs: '#3093',
  ),
  validatorUnknownPriceBidRow(label: 'bids with no effective market price contribute zero treasury spend (defensive guard against unknown / future commodity ids)'),
  validatorManufacturedBudgetRejectRow(label: 'manufactured commodity bids now consume the catalog base price (Refs #3093 manufactured-default-prices slice)'),
  validatorTreasuryTimberIronBids(label: 'accepts cumulative spend equal to treasuryBudgetForBids across distinct commodities in submission order (Refs #3123)', treasuryBudgetForBids: 100, timberPrice: 30, ironPrice: 10, proposedOrders: [validatorBid('timber', 2), validatorBid('iron', 4)], expect: const ValidatorExpectation(allAccepted: true), refs: '#3123'),
  validatorTreasuryTimberIronBids(
    label: 'rejected bid does not consume the running spend budget — greedy continuation admits a later smaller bid that fits (Refs #3123)',
    treasuryBudgetForBids: 100,
    timberPrice: 30,
    ironPrice: 10,
    proposedOrders: [validatorBid('timber', 4), validatorBid('iron', 1)],
    expect: ValidatorExpectation(outcomes: [(accepted: false, reason: TradeOrderRejectionReasons.bidExceedsTreasuryBudget), (accepted: true, reason: null)], orderAcceptedPin: (index: 1, accepted: true, reason: 'greedy continuation: rejected bid must not consume the running spend budget so a later bid that fits the remaining budget is admitted')),
    refs: '#3123',
  ),
];
List<TradeOrderValidatorScenario> tradeOrderValidatorTreasuryCatalogScenarios() => [
  validatorTreasuryTimberBids(
    label: 'treasuryBudgetForBids == 0 rejects every priced bid (Refs #3123)',
    treasuryBudgetForBids: 0,
    proposedOrders: [validatorBid('timber', 1), validatorBid('timber', 5)],
    expect: const ValidatorExpectation(allRejectedWithReason: TradeOrderRejectionReasons.bidExceedsTreasuryBudget),
    refs: '#3123',
  ),
  validatorCatalogAdmitRow(label: 'admits a bid priced solely from the catalog default when budget allows (Refs #3123 AC: rule 5 must not reject for unknown price when an initial/default price exists)', commodityId: 'timber', bidQty: 2, treasuryBudgetForBids: _catalogTimberBudgetForQty2(), catalogDefaultNotNullReason: 'timber must have a catalog default for this AC pin'),
  validatorCatalogAdmitRow(label: 'admits a manufactured-commodity bid priced from the catalog default when budget allows (Refs #3123 AC, manufactured branch)', commodityId: 'lumber', bidQty: 1, treasuryBudgetForBids: _catalogLumberBudgetForQty1(), catalogDefaultNotNullReason: 'lumber must have a manufactured catalog default'),
];
// dart format on
