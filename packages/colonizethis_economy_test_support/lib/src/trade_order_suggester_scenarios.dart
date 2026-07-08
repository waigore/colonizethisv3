// Table-driven TradeOrderSuggester scenarios (Refs #3856, #3939 phase 3 slice 14).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'trade_order_suggester_expectations.dart';
import 'trade_order_suggester_test_support.dart';

/// One row in a TradeOrderSuggester scenario table.
class TradeOrderSuggesterScenario {
  const TradeOrderSuggesterScenario({
    required this.label,
    required this.buildContext,
    required this.verify,
    this.refs,
  });

  TradeOrderSuggesterScenario.expect({
    required String label,
    required TradeSuggestionContext Function() buildContext,
    required SuggesterExpectation expect,
    String? refs,
  }) : this(
          label: label,
          buildContext: buildContext,
          verify: (context, result) =>
              assertSuggesterExpectation(context, result, expect),
          refs: refs,
        );

  final String label;
  final TradeSuggestionContext Function() buildContext;
  final void Function(
    TradeSuggestionContext context,
    TradeSuggestionResult result,
  )
  verify;
  final String? refs;
}

/// Runs [scenario] through [TradeOrderSuggester.suggest].
void runTradeOrderSuggesterScenario(TradeOrderSuggesterScenario scenario) {
  final context = scenario.buildContext();
  scenario.verify(context, TradeOrderSuggester.suggest(context));
}

/// Empty / defensive-path scenarios from `world_market_trade_order_suggester_test.dart`.
List<TradeOrderSuggesterScenario> tradeOrderSuggesterEmptyDefensiveScenarios() =>
    [
      TradeOrderSuggesterScenario.expect(
        label: 'empty context returns empty result',
        buildContext: suggesterCtx,
        expect: const SuggesterExpectation(
          isEmpty: true,
          offersEmpty: true,
          bidsEmpty: true,
        ),
      ),
      TradeOrderSuggesterScenario.expect(
        label: 'negative tradeCargoCapacity returns empty result',
        buildContext: () => suggesterCtx(
          tradeCargoCapacity: -1,
          availableStockpileByCommodityId: {'timber': 10},
          commodityNeedByCommodityId: {'iron': 10},
        ),
        expect: const SuggesterExpectation(isEmpty: true),
      ),
      TradeOrderSuggesterScenario.expect(
        label:
            'negative entries in available/need maps are silently dropped (no throw)',
        buildContext: () => suggesterCtx(
          availableStockpileByCommodityId: {'timber': -5, 'iron': 10},
          commodityNeedByCommodityId: {'coal': -3, 'wool': 4},
        ),
        expect: const SuggesterExpectation(
          offersLength: 1,
          bidsLength: 1,
          offerCommodityIds: ['iron'],
          bidCommodityIds: ['wool'],
        ),
      ),
    ];

/// Surplus-offer detection scenarios.
List<TradeOrderSuggesterScenario> tradeOrderSuggesterSurplusOfferScenarios() =>
    [
      TradeOrderSuggesterScenario.expect(
        label:
            'positive available stockpile produces an offer with that quantity',
        buildContext: () =>
            suggesterCtx(availableStockpileByCommodityId: {'timber': 12}),
        expect: const SuggesterExpectation(
          offersLength: 1,
          bidsEmpty: true,
          singleOffer: (
            commodityId: 'timber',
            quantity: 12,
            type: TradeOrderType.offer,
            priority: TradeSuggestionContext.defaultOfferPriority,
            isFtp: false,
          ),
        ),
        refs: '#2989',
      ),
      TradeOrderSuggesterScenario.expect(
        label: 'zero / missing available is not offered',
        buildContext: () => suggesterCtx(
          availableStockpileByCommodityId: {'timber': 0, 'iron': 5},
        ),
        expect: const SuggesterExpectation(
          offersLength: 1,
          singleOffer: (
            commodityId: 'iron',
            quantity: 5,
            type: null,
            priority: null,
            isFtp: null,
          ),
        ),
      ),
      TradeOrderSuggesterScenario.expect(
        label: 'riches commodities are excluded from offers',
        buildContext: () => suggesterCtx(
          availableStockpileByCommodityId: {
            'spices': 100,
            'gold': 50,
            'timber': 10,
          },
        ),
        expect: const SuggesterExpectation(
          offersLength: 1,
          offerCommodityIds: ['timber'],
        ),
      ),
      TradeOrderSuggesterScenario.expect(
        label: 'offers iterate in alphabetical commodity id order (determinism)',
        buildContext: () => suggesterCtx(
          availableStockpileByCommodityId: {
            'wool': 4,
            'coal': 2,
            'iron': 3,
            'timber': 1,
          },
        ),
        expect: const SuggesterExpectation(
          offerCommodityIds: ['coal', 'iron', 'timber', 'wool'],
        ),
      ),
    ];

/// Deficit-bid detection scenarios.
List<TradeOrderSuggesterScenario> tradeOrderSuggesterDeficitBidScenarios() => [
  TradeOrderSuggesterScenario.expect(
    label: 'positive need with zero stockpile produces a bid with that quantity',
    buildContext: () =>
        suggesterCtx(commodityNeedByCommodityId: {'timber': 8}),
    expect: const SuggesterExpectation(
      bidsLength: 1,
      offersEmpty: true,
      singleBid: (
        commodityId: 'timber',
        quantity: 8,
        type: TradeOrderType.bid,
        priority: TradeSuggestionContext.defaultBidPriority,
        isFtp: false,
      ),
    ),
    refs: '#2989',
  ),
  TradeOrderSuggesterScenario.expect(
    label:
        'mutual-exclusion at suggestion time: same commodity with stockpile=5 '
        'and need=9 produces a deficit bid of 4 only (no offer)',
    buildContext: () => suggesterCtx(
      availableStockpileByCommodityId: {'timber': 5},
      commodityNeedByCommodityId: {'timber': 9},
    ),
    expect: const SuggesterExpectation(
      offersEmpty: true,
      bidsLength: 1,
      singleBid: (
        commodityId: 'timber',
        quantity: 4,
        type: null,
        priority: null,
        isFtp: null,
      ),
    ),
  ),
  TradeOrderSuggesterScenario.expect(
    label: 'riches commodities are excluded from bids even when needed',
    buildContext: () => suggesterCtx(
      commodityNeedByCommodityId: {'gems': 5, 'gold': 5, 'timber': 4},
    ),
    expect: const SuggesterExpectation(
      bidsLength: 1,
      singleBid: (
        commodityId: 'timber',
        quantity: 4,
        type: null,
        priority: null,
        isFtp: null,
      ),
    ),
  ),
];

/// Bid type cap (rule 4) scenarios.
List<TradeOrderSuggesterScenario> tradeOrderSuggesterBidTypeCapScenarios() => [
  TradeOrderSuggesterScenario.expect(
    label: 'bidTypeCap=0 suppresses every bid',
    buildContext: () => suggesterCtx(
      bidTypeCap: 0,
      commodityNeedByCommodityId: {'timber': 4, 'iron': 3},
    ),
    expect: const SuggesterExpectation(
      bidsEmpty: true,
      offersEmpty: true,
    ),
    refs: '#2989',
  ),
  TradeOrderSuggesterScenario.expect(
    label: 'bidTypeCap=3 admits the first three alphabetical commodities only',
    buildContext: () => suggesterCtx(
      commodityNeedByCommodityId: {
        'wool': 5,
        'coal': 5,
        'timber': 5,
        'iron': 5,
      },
    ),
    expect: const SuggesterExpectation(
      bidCommodityIds: ['coal', 'iron', 'timber'],
    ),
    refs: '#2989',
  ),
  TradeOrderSuggesterScenario.expect(
    label: 'bidTypeCap=6 admits up to six distinct commodities',
    buildContext: () => suggesterCtx(
      bidTypeCap: 6,
      commodityNeedByCommodityId: {
        'cattle': 1,
        'coal': 1,
        'cotton': 1,
        'grain': 1,
        'hides': 1,
        'iron': 1,
        'timber': 1,
      },
    ),
    expect: const SuggesterExpectation(
      bidsLength: 6,
      bidCommodityIds: [
        'cattle',
        'coal',
        'cotton',
        'grain',
        'hides',
        'iron',
      ],
    ),
    refs: '#2989',
  ),
];

/// Cumulative cargo cap (rule 5) scenarios.
List<TradeOrderSuggesterScenario> tradeOrderSuggesterCargoCapScenarios() => [
  TradeOrderSuggesterScenario.expect(
    label: 'cargo budget is consumed across distinct bids (per-buyer total)',
    buildContext: () => suggesterCtx(
      tradeCargoCapacity: 6,
      commodityNeedByCommodityId: {'coal': 4, 'iron': 5},
    ),
    expect: const SuggesterExpectation(
      bidQuantities: [
        (commodityId: 'coal', quantity: 4),
        (commodityId: 'iron', quantity: 2),
      ],
    ),
    refs: '#2989',
  ),
  TradeOrderSuggesterScenario.expect(
    label: 'per-commodity bid never exceeds tradeCargoCapacity',
    buildContext: () => suggesterCtx(
      tradeCargoCapacity: 10,
      commodityNeedByCommodityId: {'timber': 999},
    ),
    expect: const SuggesterExpectation(
      bidsLength: 1,
      singleBid: (
        commodityId: 'timber',
        quantity: 10,
        type: null,
        priority: null,
        isFtp: null,
      ),
    ),
  ),
  TradeOrderSuggesterScenario.expect(
    label: 'zero cargo budget suppresses bids entirely',
    buildContext: () => suggesterCtx(
      tradeCargoCapacity: 0,
      commodityNeedByCommodityId: {'timber': 5},
    ),
    expect: const SuggesterExpectation(bidsEmpty: true),
  ),
];

/// Validator-clean-by-construction scenarios.
List<TradeOrderSuggesterScenario>
tradeOrderSuggesterValidatorCleanScenarios() => [
  TradeOrderSuggesterScenario.expect(
    label:
        'every suggested order is accepted by TradeOrderValidator.validate',
    buildContext: () => suggesterCtx(
      tradeCargoCapacity: 12,
      treasuryBudgetForBids: 500,
      availableStockpileByCommodityId: {'timber': 10, 'wool': 0},
      commodityNeedByCommodityId: {'coal': 5, 'iron': 7, 'wool': 4},
    ),
    expect: const SuggesterExpectation(
      offersNotEmpty: true,
      bidsNotEmpty: true,
      validatorAllAccepted: true,
    ),
  ),
  TradeOrderSuggesterScenario.expect(
    label:
        'mixed surplus/deficit submission produces no commodity in both lists',
    buildContext: () => suggesterCtx(
      bidTypeCap: 6,
      availableStockpileByCommodityId: {'timber': 50, 'wool': 5},
      commodityNeedByCommodityId: {
        'wool': 8,
        'iron': 4,
      },
    ),
    expect: const SuggesterExpectation(
      offerBidDisjoint: true,
      offersContain: {'timber'},
      bidsContainAll: {'wool', 'iron'},
    ),
  ),
];

/// Treasury bid cap (rule 5) scenarios from
/// `world_market_trade_order_suggester_treasury_test.dart` (Refs #3123).
List<TradeOrderSuggesterScenario> tradeOrderSuggesterTreasuryCapScenarios() =>
    [
      TradeOrderSuggesterScenario.expect(
        label: 'treasury budget is consumed across distinct bids in id order',
        buildContext: () => suggesterCtx(
          bidTypeCap: 6,
          treasuryBudgetForBids: 90,
          worldMarketState: WorldMarketState(
            prices: {
              CommodityCatalog.iron.id: 30,
              CommodityCatalog.timber.id: 30,
            },
          ),
          commodityNeedByCommodityId: {
            CommodityCatalog.iron.id: 5,
            CommodityCatalog.timber.id: 5,
          },
        ),
        expect: const SuggesterExpectation(
          bidsLength: 1,
          singleBid: (
            commodityId: 'iron',
            quantity: 3,
            type: null,
            priority: null,
            isFtp: null,
          ),
        ),
        refs: '#3123',
      ),
      TradeOrderSuggesterScenario.expect(
        label: 'single bid is partial-capped by treasury',
        buildContext: () => suggesterCtx(
          treasuryBudgetForBids: 90,
          worldMarketState: WorldMarketState(
            prices: {CommodityCatalog.timber.id: 30},
          ),
          commodityNeedByCommodityId: {CommodityCatalog.timber.id: 5},
        ),
        expect: const SuggesterExpectation(
          singleBid: (
            commodityId: 'timber',
            quantity: 3,
            type: null,
            priority: null,
            isFtp: null,
          ),
        ),
        refs: '#3123',
      ),
      TradeOrderSuggesterScenario.expect(
        label: 'zero treasury budget suppresses bids entirely',
        buildContext: () => suggesterCtx(
          treasuryBudgetForBids: 0,
          worldMarketState: WorldMarketState(
            prices: {CommodityCatalog.timber.id: 30},
          ),
          commodityNeedByCommodityId: {CommodityCatalog.timber.id: 5},
        ),
        expect: const SuggesterExpectation(bidsEmpty: true),
        refs: '#3123',
      ),
    ];
