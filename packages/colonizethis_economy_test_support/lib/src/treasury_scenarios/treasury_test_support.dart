// dart format off
// Shared treasury bid-budget fixtures and game builders (Refs #3093, #3661, #3939).
import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_models/colonizethis_models.dart';
import '../trade_order_factory.dart';
import 'treasury_expectations.dart';
/// Canonical human-player id used across treasury-bid-budget test suites.
const String humanPlayerId = 'gp_h';
/// Builds a minimal `Game` shaped for treasury-bid-budget tests.
Game buildTreasuryBidBudgetGame({int treasury = 100, Map<CommodityId, int>? prices, Map<CommodityId, int>? stockpile, WorldMarketState? worldMarketState, String playerId = humanPlayerId, String gameId = 'test_treasury_bid_budget', String playerDisplayName = 'England', bool isHuman = true, List<TradeOrder>? carryForwardBids}) {
  final resolvedPrices = prices ?? const <CommodityId, int>{};
  return Game(
    id: gameId,
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      Player(
        id: playerId,
        displayName: playerDisplayName,
        isHuman: isHuman,
        treasury: treasury,
        stockpile: Stockpile(quantities: stockpile ?? const <CommodityId, int>{}),
      ),
    ],
    diplomacyRelations: const [],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
    worldMarketState: worldMarketState ?? WorldMarketState(prices: resolvedPrices, carryForwardBidsByFactionId: carryForwardBids == null ? const {} : {playerId: carryForwardBids}),
  );
}
/// Stockpile-player game builder for sellable-quantity suites (Refs #3831).
Game buildStockpilePlayerGame({Map<CommodityId, int>? stockpile}) => buildTreasuryBidBudgetGame(treasury: 500, stockpile: stockpile, worldMarketState: const WorldMarketState());
/// Wraps trade orders into the per-player map for [humanPlayerId].
Orders humanOrdersWith(List<TradeOrder> orders) {
  return Orders(tradeOrdersByPlayerId: {humanPlayerId: orders});
}
TradeOrder bidOrder(String commodityId, int qty) => testBid(commodityId, qty);
TradeOrder offerOrder(String commodityId, int qty) => testOffer(commodityId, qty);
/// Minimal single-player [Game] with carry-forward bids on the world market.
Game carryForwardBidGame(List<TradeOrder> bids, {String playerId = 'gp1', Map<CommodityId, int> prices = const <CommodityId, int>{}, int treasury = 10000, String gameId = 'g_bid_spend', String playerDisplayName = 'GP1'}) => buildTreasuryBidBudgetGame(treasury: treasury, prices: prices, playerId: playerId, gameId: gameId, playerDisplayName: playerDisplayName, isHuman: false, carryForwardBids: bids);
/// Compact row builder for [stagedBidSpendScenarios] (Refs #3939 phase 3 slice 39).
({String label, Map<CommodityId, int>? prices, List<TradeOrder> orders, int? expectedSpend, int Function(data.ResourceRules rules)? expectedSpendFn, String playerId, String? refs}) stagedBidSpendRow({required String label, required List<TradeOrder> orders, Map<CommodityId, int>? prices, int? expectedSpend, int Function(data.ResourceRules rules)? expectedSpendFn, String playerId = humanPlayerId, String? refs = '#3093'}) => (label: label, orders: orders, prices: prices, expectedSpend: expectedSpend, expectedSpendFn: expectedSpendFn, playerId: playerId, refs: refs);
/// Compact row builder for [treasuryAvailableForBidsScenarios] (Refs #3939 slice 39).
({String label, int treasury, String playerId, int projectedNonBidTreasuryDelta, int expected, String? refs, TreasuryAvailableExpectation? extra}) treasuryAvailableRow({required String label, required int treasury, required int expected, int projectedNonBidTreasuryDelta = 0, String playerId = humanPlayerId, String? refs, TreasuryAvailableExpectation? extra}) => (label: label, treasury: treasury, playerId: playerId, projectedNonBidTreasuryDelta: projectedNonBidTreasuryDelta, expected: expected, refs: refs, extra: extra);
/// Compact row builder for [capBidQuantityForBudgetsScenarios] (Refs #3939 slice 40).
({String label, int bidQuantity, int remainingCargoBudget, int remainingTreasuryBudget, int? unitPrice, int expected, String? refs}) capBidQtyRow({required String label, required int expected, int bidQuantity = 10, int remainingCargoBudget = 100, int remainingTreasuryBudget = 100, int? unitPrice = 30, String? refs}) => (label: label, bidQuantity: bidQuantity, remainingCargoBudget: remainingCargoBudget, remainingTreasuryBudget: remainingTreasuryBudget, unitPrice: unitPrice, expected: expected, refs: refs);
/// Compact row builder for [maxAffordableBidQuantityScenarios] (Refs #3939 slice 40).
({String label, int bidRemaining, double pricePerUnit, int remainingTreasuryBudget, int expected, String? refs}) maxAffordableBidQtyRow({required String label, required int expected, int bidRemaining = 10, double pricePerUnit = 30.0, int remainingTreasuryBudget = 90, String? refs}) => (label: label, bidRemaining: bidRemaining, pricePerUnit: pricePerUnit, remainingTreasuryBudget: remainingTreasuryBudget, expected: expected, refs: refs);
/// Compact row builder for [decrementTreasuryForFillScenarios] (Refs #3939 slice 40).
({String label, String buyerFactionId, int matchQty, double pricePerUnit, int initialTreasury, int expectedTreasury, String? refs}) decrementTreasuryFillRow({required String label, required int matchQty, required double pricePerUnit, required int expectedTreasury, String buyerFactionId = 'gp1', int initialTreasury = 100, String? refs}) => (label: label, buyerFactionId: buyerFactionId, matchQty: matchQty, pricePerUnit: pricePerUnit, initialTreasury: initialTreasury, expectedTreasury: expectedTreasury, refs: refs);
/// Compact row builder for [effectiveMarketPriceScenarios] (Refs #3939 slice 42).
({String label, String commodityId, Map<CommodityId, int> prices, int? expected, bool useCatalogDefault, bool expectNull, String? refs}) effectiveMarketPriceRow({required String label, required String commodityId, Map<CommodityId, int> prices = const {}, int? expected, bool useCatalogDefault = false, bool expectNull = false, String? refs}) => (label: label, commodityId: commodityId, prices: prices, expected: expected, useCatalogDefault: useCatalogDefault, expectNull: expectNull, refs: refs);
/// Riches commodity row with stored prices but null effective price (Refs #3939 slice 42).
({String label, String commodityId, Map<CommodityId, int> prices, int? expected, bool useCatalogDefault, bool expectNull, String? refs}) effectiveMarketPriceRichesRow({required String label, required String commodityId, required Map<CommodityId, int> prices, String? refs}) => effectiveMarketPriceRow(label: label, commodityId: commodityId, prices: prices, expectNull: true, refs: refs);
// dart format on
