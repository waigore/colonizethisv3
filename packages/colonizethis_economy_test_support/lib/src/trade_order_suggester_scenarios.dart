// dart format off
// Table-driven TradeOrderSuggester scenarios (Refs #3856, #3939 slices 14 / 46).
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'trade_order_suggester_expectations.dart';
import 'trade_order_suggester_test_support.dart';
/// One row in a TradeOrderSuggester scenario table.
typedef TradeOrderSuggesterScenario = ({String label, TradeSuggestionContext Function() buildContext, void Function(TradeSuggestionContext context, TradeSuggestionResult result) verify, String? refs});
/// Runs [scenario] through [TradeOrderSuggester.suggest].
void runTradeOrderSuggesterScenario(TradeOrderSuggesterScenario scenario) {
  final context = scenario.buildContext();
  scenario.verify(context, TradeOrderSuggester.suggest(context));
}
/// Compact TradeOrderSuggester row builder (Refs #3939 slice 46 / 57).
TradeOrderSuggesterScenario suggesterRow({required String label, required SuggesterExpectation expect, TradeSuggestionContext Function()? buildContext, int bidTypeCap = 3, int tradeCargoCapacity = 100, int treasuryBudgetForBids = 1 << 30, Map<String, int> availableStockpileByCommodityId = const {}, Map<String, int> commodityNeedByCommodityId = const {}, WorldMarketState worldMarketState = const WorldMarketState(), String? refs}) => (label: label, refs: refs, buildContext: buildContext ?? () => suggesterCtx(bidTypeCap: bidTypeCap, tradeCargoCapacity: tradeCargoCapacity, treasuryBudgetForBids: treasuryBudgetForBids, availableStockpileByCommodityId: availableStockpileByCommodityId, commodityNeedByCommodityId: commodityNeedByCommodityId, worldMarketState: worldMarketState), verify: (context, result) => assertSuggesterExpectation(context, result, expect));
/// Empty / defensive-path scenarios from `world_market_trade_order_suggester_test.dart`.
List<TradeOrderSuggesterScenario> tradeOrderSuggesterEmptyDefensiveScenarios() => [
  suggesterRow(label: 'empty context returns empty result', buildContext: suggesterCtx, expect: const SuggesterExpectation(isEmpty: true)),
  suggesterRow(label: 'negative tradeCargoCapacity returns empty result', tradeCargoCapacity: -1, availableStockpileByCommodityId: const {'timber': 10}, commodityNeedByCommodityId: const {'iron': 10}, expect: const SuggesterExpectation(isEmpty: true)),
  suggesterRow(
    label: 'negative entries in available/need maps are silently dropped (no throw)',
    availableStockpileByCommodityId: const {'timber': -5, 'iron': 10},
    commodityNeedByCommodityId: const {'coal': -3, 'wool': 4},
    expect: const SuggesterExpectation(offersLength: 1, bidsLength: 1, offerCommodityIds: ['iron'], bidCommodityIds: ['wool']),
  ),
];
/// Surplus-offer detection scenarios.
List<TradeOrderSuggesterScenario> tradeOrderSuggesterSurplusOfferScenarios() => [
  suggesterRow(label: 'positive available stockpile produces an offer with that quantity', availableStockpileByCommodityId: const {'timber': 12}, expect: suggesterSingleOfferExpect('timber', 12, pinDefaults: true, bidsEmpty: true), refs: '#2989'),
  suggesterRow(label: 'zero / missing available is not offered', availableStockpileByCommodityId: const {'timber': 0, 'iron': 5}, expect: suggesterSingleOfferExpect('iron', 5)),
  suggesterRow(
    label: 'riches commodities are excluded from offers',
    availableStockpileByCommodityId: const {'spices': 100, 'gold': 50, 'timber': 10},
    expect: const SuggesterExpectation(offersLength: 1, offerCommodityIds: ['timber']),
  ),
  suggesterRow(
    label: 'offers iterate in alphabetical commodity id order (determinism)',
    availableStockpileByCommodityId: const {'wool': 4, 'coal': 2, 'iron': 3, 'timber': 1},
    expect: const SuggesterExpectation(offerCommodityIds: ['coal', 'iron', 'timber', 'wool']),
  ),
];
/// Deficit-bid detection scenarios.
List<TradeOrderSuggesterScenario> tradeOrderSuggesterDeficitBidScenarios() => [
  suggesterRow(label: 'positive need with zero stockpile produces a bid with that quantity', commodityNeedByCommodityId: const {'timber': 8}, expect: suggesterSingleBidExpect('timber', 8, pinDefaults: true, offersEmpty: true), refs: '#2989'),
  suggesterRow(label: 'mutual-exclusion at suggestion time: same commodity with stockpile=5 and need=9 produces a deficit bid of 4 only (no offer)', availableStockpileByCommodityId: const {'timber': 5}, commodityNeedByCommodityId: const {'timber': 9}, expect: suggesterSingleBidExpect('timber', 4, offersEmpty: true)),
  suggesterRow(label: 'riches commodities are excluded from bids even when needed', commodityNeedByCommodityId: const {'gems': 5, 'gold': 5, 'timber': 4}, expect: suggesterSingleBidExpect('timber', 4)),
];
/// Bid type cap (rule 4) scenarios.
List<TradeOrderSuggesterScenario> tradeOrderSuggesterBidTypeCapScenarios() => [
  suggesterRow(label: 'bidTypeCap=0 suppresses every bid', bidTypeCap: 0, commodityNeedByCommodityId: const {'timber': 4, 'iron': 3}, expect: const SuggesterExpectation(bidsEmpty: true, offersEmpty: true), refs: '#2989'),
  suggesterRow(
    label: 'bidTypeCap=3 admits the first three alphabetical commodities only',
    commodityNeedByCommodityId: const {'wool': 5, 'coal': 5, 'timber': 5, 'iron': 5},
    expect: const SuggesterExpectation(bidCommodityIds: ['coal', 'iron', 'timber']),
    refs: '#2989',
  ),
  suggesterRow(
    label: 'bidTypeCap=6 admits up to six distinct commodities',
    bidTypeCap: 6,
    commodityNeedByCommodityId: const {'cattle': 1, 'coal': 1, 'cotton': 1, 'grain': 1, 'hides': 1, 'iron': 1, 'timber': 1},
    expect: const SuggesterExpectation(bidsLength: 6, bidCommodityIds: ['cattle', 'coal', 'cotton', 'grain', 'hides', 'iron']),
    refs: '#2989',
  ),
];
/// Cumulative cargo cap (rule 5) scenarios.
List<TradeOrderSuggesterScenario> tradeOrderSuggesterCargoCapScenarios() => [
  suggesterRow(
    label: 'cargo budget is consumed across distinct bids (per-buyer total)',
    tradeCargoCapacity: 6,
    commodityNeedByCommodityId: const {'coal': 4, 'iron': 5},
    expect: const SuggesterExpectation(bidQuantities: [(commodityId: 'coal', quantity: 4), (commodityId: 'iron', quantity: 2)]),
    refs: '#2989',
  ),
  suggesterRow(label: 'per-commodity bid never exceeds tradeCargoCapacity', tradeCargoCapacity: 10, commodityNeedByCommodityId: const {'timber': 999}, expect: suggesterSingleBidExpect('timber', 10)),
  suggesterRow(label: 'zero cargo budget suppresses bids entirely', tradeCargoCapacity: 0, commodityNeedByCommodityId: const {'timber': 5}, expect: const SuggesterExpectation(bidsEmpty: true)),
];
/// Validator-clean-by-construction scenarios.
List<TradeOrderSuggesterScenario> tradeOrderSuggesterValidatorCleanScenarios() => [
  suggesterRow(label: 'every suggested order is accepted by TradeOrderValidator.validate', tradeCargoCapacity: 12, treasuryBudgetForBids: 500, availableStockpileByCommodityId: const {'timber': 10, 'wool': 0}, commodityNeedByCommodityId: const {'coal': 5, 'iron': 7, 'wool': 4}, expect: const SuggesterExpectation(offersNotEmpty: true, bidsNotEmpty: true, validatorAllAccepted: true)),
  suggesterRow(
    label: 'mixed surplus/deficit submission produces no commodity in both lists',
    bidTypeCap: 6,
    availableStockpileByCommodityId: const {'timber': 50, 'wool': 5},
    commodityNeedByCommodityId: const {'wool': 8, 'iron': 4},
    expect: const SuggesterExpectation(offerBidDisjoint: true, offersContain: {'timber'}, bidsContainAll: {'wool', 'iron'}),
  ),
];
/// Treasury bid cap (rule 5) scenarios from
/// `world_market_trade_order_suggester_treasury_test.dart` (Refs #3123).
List<TradeOrderSuggesterScenario> tradeOrderSuggesterTreasuryCapScenarios() => [
  suggesterRow(
    label: 'treasury budget is consumed across distinct bids in id order',
    bidTypeCap: 6,
    treasuryBudgetForBids: 90,
    worldMarketState: const WorldMarketState(prices: {'iron': 30, 'timber': 30}),
    commodityNeedByCommodityId: const {'iron': 5, 'timber': 5},
    expect: suggesterSingleBidExpect('iron', 3),
    refs: '#3123',
  ),
  suggesterRow(
    label: 'single bid is partial-capped by treasury',
    treasuryBudgetForBids: 90,
    worldMarketState: const WorldMarketState(prices: {'timber': 30}),
    commodityNeedByCommodityId: const {'timber': 5},
    expect: suggesterSingleBidExpect('timber', 3, bidsLength: null),
    refs: '#3123',
  ),
  suggesterRow(
    label: 'zero treasury budget suppresses bids entirely',
    treasuryBudgetForBids: 0,
    worldMarketState: const WorldMarketState(prices: {'timber': 30}),
    commodityNeedByCommodityId: const {'timber': 5},
    expect: const SuggesterExpectation(bidsEmpty: true),
    refs: '#3123',
  ),
];
// dart format on
