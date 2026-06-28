// Canonical shared `Game` factory for carry-forward / staged bid-spend tests.
//
// Refs #3661 — `world_market_carry_forward_bid_notional_test.dart` and
// `world_market_bid_spend_shared_helper_test.dart` each declared a near-identical
// private `Game` builder (single player, orders-phase world state, carry-forward
// bids on the world market) differing only in id / player id / treasury. This
// single builder removes that duplication so both call sites construct the same
// fixture shape.

import 'package:colonizethis_models/colonizethis_models.dart';

/// Builds a minimal single-player [Game] whose world-market state carries the
/// supplied [bids] as the player's carry-forward bids.
///
/// Callers override [playerId], [prices], [treasury], [gameId], or
/// [playerDisplayName] only where a test needs a specific value; the defaults
/// match the shapes previously hard-coded in the bid-spend test files.
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
