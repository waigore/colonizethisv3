// Table-driven TradeOrderValidator treasury scenarios (Refs #3836).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'trade_order_validator_scenarios.dart';
import 'trade_order_validator_test_support.dart';
import 'treasury_bid_budget_test_support.dart';

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
  TradeOrderValidatorScenario(
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
    verify: (results) {
      expect(results[0].isAccepted, isTrue);
      expect(
        results[1].reason,
        TradeOrderRejectionReasons.bidExceedsTreasuryBudget,
      );
    },
    refs: '#3093',
  ),
  TradeOrderValidatorScenario(
    label: 'accepts bids whose cumulative spend equals treasuryBudgetForBids',
    context: validatorCtx(
      treasuryBudgetForBids: 60,
      worldMarketState: WorldMarketState(
        prices: {CommodityCatalog.timber.id: 30},
      ),
    ),
    proposedOrders: [validatorBid(CommodityCatalog.timber.id, 2)],
    verify: (results) {
      expect(results.single.isAccepted, isTrue);
    },
    refs: '#3093',
  ),
  TradeOrderValidatorScenario(
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
    verify: (results) {
      expect(
        results.single.reason,
        TradeOrderRejectionReasons.bidExceedsTreasuryBudget,
      );
    },
    refs: '#3093',
  ),
  TradeOrderValidatorScenario(
    label: 'bids with no effective market price contribute zero treasury spend '
        '(defensive guard against unknown / future commodity ids)',
    context: validatorCtx(
      treasuryBudgetForBids: 0,
      worldMarketState: const WorldMarketState(),
    ),
    proposedOrders: [validatorBid('not_a_real_commodity', 10)],
    verify: (results) {
      expect(results.single.isAccepted, isTrue);
    },
    refs: '#3093',
  ),
  TradeOrderValidatorScenario(
    label: 'manufactured commodity bids now consume the catalog base price '
        '(Refs #3093 manufactured-default-prices slice)',
    context: validatorCtx(
      treasuryBudgetForBids: 100,
      worldMarketState: const WorldMarketState(),
    ),
    proposedOrders: [validatorBid(CommodityCatalog.lumber.id, 10)],
    verify: (results) {
      expect(
        results.single.reason,
        TradeOrderRejectionReasons.bidExceedsTreasuryBudget,
      );
    },
    refs: '#3093',
  ),
  TradeOrderValidatorScenario(
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
    verify: (results) {
      expect(results, hasLength(2));
      expect(results[0].isAccepted, isTrue);
      expect(
        results[1].isAccepted,
        isTrue,
        reason: 'cumulative 100 == budget must be admitted',
      );
    },
    refs: '#3123',
  ),
  TradeOrderValidatorScenario(
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
    verify: (results) {
      expect(results, hasLength(2));
      expect(
        results[0].reason,
        TradeOrderRejectionReasons.bidExceedsTreasuryBudget,
      );
      expect(
        results[1].isAccepted,
        isTrue,
        reason:
            'greedy continuation: rejected bid must not consume '
            'the running spend budget so a later bid that fits the '
            'remaining budget is admitted',
      );
    },
    refs: '#3123',
  ),
];

List<TradeOrderValidatorScenario> tradeOrderValidatorTreasuryCatalogScenarios() =>
    [
  TradeOrderValidatorScenario(
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
    verify: (results) {
      expect(results, hasLength(2));
      expect(
        results[0].reason,
        TradeOrderRejectionReasons.bidExceedsTreasuryBudget,
      );
      expect(
        results[1].reason,
        TradeOrderRejectionReasons.bidExceedsTreasuryBudget,
      );
    },
    refs: '#3123',
  ),
  TradeOrderValidatorScenario(
    label: 'admits a bid priced solely from the catalog default when budget '
        'allows (Refs #3123 AC: rule 5 must not reject for unknown price '
        'when an initial/default price exists)',
    context: validatorCtx(
      treasuryBudgetForBids: _catalogTimberBudgetForQty2(),
      worldMarketState: const WorldMarketState(),
    ),
    proposedOrders: [validatorBid(CommodityCatalog.timber.id, 2)],
    verify: (results) {
      final int? catalogTimber = ResourceRules.defaultRules
          .defaultMarketPriceForCommodityId(CommodityCatalog.timber.id);
      expect(
        catalogTimber,
        isNotNull,
        reason: 'timber must have a catalog default for this AC pin',
      );
      expect(
        results.single.isAccepted,
        isTrue,
        reason:
            'rule 5 must use the catalog default and admit when '
            'cumulative spend fits the budget',
      );
    },
    refs: '#3123',
  ),
  TradeOrderValidatorScenario(
    label: 'admits a manufactured-commodity bid priced from the catalog '
        'default when budget allows (Refs #3123 AC, manufactured branch)',
    context: validatorCtx(
      treasuryBudgetForBids: _catalogLumberBudgetForQty1(),
      worldMarketState: const WorldMarketState(),
    ),
    proposedOrders: [validatorBid(CommodityCatalog.lumber.id, 1)],
    verify: (results) {
      final int? catalogLumber = ResourceRules.defaultRules
          .defaultMarketPriceForCommodityId(CommodityCatalog.lumber.id);
      expect(
        catalogLumber,
        isNotNull,
        reason: 'lumber must have a manufactured catalog default',
      );
      expect(results.single.isAccepted, isTrue);
    },
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

  final String label;
  final void Function() run;
  final String? refs;
}

/// Context-from-game treasury scenarios from
/// `world_market_trade_order_validator_context_treasury_test.dart`.
List<TradeOrderValidatorContextScenario>
tradeOrderValidatorContextTreasuryScenarios() => [
  TradeOrderValidatorContextScenario(
    label: 'positive treasury surfaces as TradeOrderValidationContext.'
        'treasuryBudgetForBids',
    run: () {
      final game = buildTreasuryBidBudgetGame(treasury: 175);
      final ctx = tradeOrderValidationContextFromGame(game, humanPlayerId);
      expect(ctx.treasuryBudgetForBids, 175);
    },
    refs: '#3123',
  ),
  TradeOrderValidatorContextScenario(
    label: 'treasury at or below zero yields a zero bid budget that rejects any '
        'priced bid end-to-end (negative clamps; zero passes through) '
        '(SPEC/game/world-market.md — cross-commodity bid treasury cap)',
    run: () {
      for (final treasury in const <int>[-25, 0]) {
        final game = buildTreasuryBidBudgetGame(
          treasury: treasury,
          prices: const {'timber': 30},
        );
        final ctx = tradeOrderValidationContextFromGame(game, humanPlayerId);
        expect(
          ctx.treasuryBudgetForBids,
          0,
          reason: 'treasury $treasury must yield a zero bid budget',
        );
        final results = TradeOrderValidator.validate(
          context: ctx,
          proposedOrders: [
            TradeOrder(
              commodityId: 'timber',
              type: TradeOrderType.bid,
              quantity: 1,
              priority: 1,
            ),
          ],
        );
        expect(
          results.single.reason,
          TradeOrderRejectionReasons.bidExceedsTreasuryBudget,
          reason: 'a priced bid must be rejected when treasury is $treasury',
        );
      }
    },
    refs: '#3123',
  ),
  TradeOrderValidatorContextScenario(
    label: 'ghost player id returns a zero-budget context (ghost guard)',
    run: () {
      final game = buildTreasuryBidBudgetGame(treasury: 200);
      final ctx = tradeOrderValidationContextFromGame(game, 'gp_ghost');
      expect(ctx.treasuryBudgetForBids, 0);
    },
    refs: '#3123',
  ),
  TradeOrderValidatorContextScenario(
    label: 'caller-supplied projectedTreasuryDelta reduces the budget by the '
        'projected non-bid deficit (Refs #3290 economy->orders inversion)',
    run: () {
      final game = buildTreasuryBidBudgetGame(treasury: 175);
      final ctx = tradeOrderValidationContextFromGame(
        game,
        humanPlayerId,
        stagedOrders: humanOrdersWith(const <TradeOrder>[]),
        projectedTreasuryDelta: -50,
      );
      expect(ctx.treasuryBudgetForBids, 125);
    },
    refs: '#3290',
  ),
  TradeOrderValidatorContextScenario(
    label: 'caller-supplied non-negative projectedTreasuryDelta leaves the raw '
        'treasury budget unchanged (income does not raise the budget)',
    run: () {
      final game = buildTreasuryBidBudgetGame(treasury: 175);
      final ctx = tradeOrderValidationContextFromGame(
        game,
        humanPlayerId,
        stagedOrders: humanOrdersWith(const <TradeOrder>[]),
        projectedTreasuryDelta: 40,
      );
      expect(ctx.treasuryBudgetForBids, 175);
    },
    refs: '#3290',
  ),
  TradeOrderValidatorContextScenario(
    label: 'omitting projectedTreasuryDelta keeps the raw-treasury budget even '
        'when staged orders are supplied',
    run: () {
      final game = buildTreasuryBidBudgetGame(treasury: 175);
      final ctx = tradeOrderValidationContextFromGame(
        game,
        humanPlayerId,
        stagedOrders: humanOrdersWith(const <TradeOrder>[]),
      );
      expect(ctx.treasuryBudgetForBids, 175);
    },
    refs: '#3123',
  ),
];
