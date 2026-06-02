// Shared helpers for world-market treasury bid budget unit tests
// (Refs #3093 — treasury bid cap slice). Extracted to keep each
// `*_test.dart` file under the `repo.logic_test_file_size` 400-line cap.

import 'package:colonizethis_models/colonizethis_models.dart';

/// Canonical human-player id used across the treasury-bid-budget test
/// suites so per-player helpers can be shared between files.
const String humanPlayerId = 'gp_h';

/// Builds a minimal `Game` shaped for the treasury-bid-budget tests:
/// a single human player with the requested treasury/stockpile and a
/// `WorldMarketState` populated with the provided prices map.
Game buildTreasuryBidBudgetGame({
  int treasury = 100,
  Map<CommodityId, int>? prices,
  Map<CommodityId, int>? stockpile,
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
    worldMarketState: WorldMarketState(
      prices: prices ?? const <CommodityId, int>{},
    ),
  );
}

/// Wraps a flat list of `TradeOrder` values into the per-player map shape
/// expected by `Orders.tradeOrdersByPlayerId` for the canonical human
/// player.
Orders humanOrdersWith(List<TradeOrder> orders) {
  return Orders(
    tradeOrdersByPlayerId: {
      humanPlayerId: orders,
    },
  );
}

/// Bid trade order at priority 1.
TradeOrder bidOrder(String commodityId, int qty) => TradeOrder(
      commodityId: commodityId,
      type: TradeOrderType.bid,
      quantity: qty,
      priority: 1,
    );

/// Offer trade order at priority 1.
TradeOrder offerOrder(String commodityId, int qty) => TradeOrder(
      commodityId: commodityId,
      type: TradeOrderType.offer,
      quantity: qty,
      priority: 1,
    );
