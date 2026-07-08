// Shared treasury bid-budget fixtures and game builders (Refs #3093, #3661, #3939).

import 'package:colonizethis_models/colonizethis_models.dart';

import '../trade_order_factory.dart';

/// Canonical human-player id used across treasury-bid-budget test suites.
const String humanPlayerId = 'gp_h';

/// Builds a minimal `Game` shaped for treasury-bid-budget tests.
Game buildTreasuryBidBudgetGame({
  int treasury = 100,
  Map<CommodityId, int>? prices,
  Map<CommodityId, int>? stockpile,
  WorldMarketState? worldMarketState,
}) {
  return Game(
    id: 'test_treasury_bid_budget',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      Player(
        id: humanPlayerId,
        displayName: 'England',
        isHuman: true,
        treasury: treasury,
        stockpile: Stockpile(
          quantities: stockpile ?? const <CommodityId, int>{},
        ),
      ),
    ],
    diplomacyRelations: const [],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
    worldMarketState:
        worldMarketState ??
        WorldMarketState(prices: prices ?? const <CommodityId, int>{}),
  );
}

/// Stockpile-player game builder for sellable-quantity suites (Refs #3831).
Game buildStockpilePlayerGame({Map<CommodityId, int>? stockpile}) =>
    buildTreasuryBidBudgetGame(
      treasury: 500,
      stockpile: stockpile,
      worldMarketState: const WorldMarketState(),
    );

/// Wraps trade orders into the per-player map for [humanPlayerId].
Orders humanOrdersWith(List<TradeOrder> orders) {
  return Orders(tradeOrdersByPlayerId: {humanPlayerId: orders});
}

TradeOrder bidOrder(String commodityId, int qty) => testBid(commodityId, qty);

TradeOrder offerOrder(String commodityId, int qty) =>
    testOffer(commodityId, qty);

/// Minimal single-player [Game] with carry-forward bids on the world market.
Game carryForwardBidGame(
  List<TradeOrder> bids, {
  String playerId = 'gp1',
  Map<CommodityId, int> prices = const <CommodityId, int>{},
  int treasury = 10000,
  String gameId = 'g_bid_spend',
  String playerDisplayName = 'GP1',
}) => Game(
  id: gameId,
  worldState: WorldState(
    turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
  ),
  players: [
    Player(
      id: playerId,
      displayName: playerDisplayName,
      isHuman: false,
      treasury: treasury,
    ),
  ],
  worldMarketState: WorldMarketState(
    prices: prices,
    carryForwardBidsByFactionId: {playerId: bids},
  ),
);
