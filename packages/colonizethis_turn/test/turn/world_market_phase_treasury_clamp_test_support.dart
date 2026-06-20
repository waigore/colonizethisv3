import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_turn/src/turn/phases/world_market_phase.dart';
import 'package:colonizethis_turn/src/turn/turn_pipeline_state.dart';
import 'package:colonizethis_turn/src/turn/turn_resolver_config.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared two-GP world-market fixture for treasury-clamp phase tests (Refs #3115).
Game gameWithTwoGps({
  required Stockpile sellerStockpile,
  required int sellerTreasury,
  required int buyerTreasury,
  required Map<CommodityId, int> marketPrices,
}) {
  return Game(
    id: 'g1',
    players: [
      Player(
        id: 'gpSeller',
        displayName: 'Seller',
        isHuman: false,
        stockpile: sellerStockpile,
        treasury: sellerTreasury,
      ),
      Player(
        id: 'gpBuyer',
        displayName: 'Buyer',
        isHuman: false,
        stockpile: Stockpile.empty,
        treasury: buyerTreasury,
      ),
    ],
    worldState: const WorldState(
      turnState: TurnState(
        phase: TurnPhase.worldMarket,
        turnNumber: 3,
      ),
      oldWorld: RegionData(),
      newWorld: RegionData(),
    ),
    worldMarketState: WorldMarketState.empty.copyWith(prices: marketPrices),
  );
}

/// Runs phase 13 on a two-GP fixture with the given [orders].
Game runTreasuryClampPhase({
  required Stockpile sellerStockpile,
  required int sellerTreasury,
  required int buyerTreasury,
  required Map<CommodityId, int> marketPrices,
  required Orders orders,
}) {
  final acc = TurnPipelineState(
    game: gameWithTwoGps(
      sellerStockpile: sellerStockpile,
      sellerTreasury: sellerTreasury,
      buyerTreasury: buyerTreasury,
      marketPrices: marketPrices,
    ),
  );
  final config = TurnResolverConfig(
    topology: const MapTopology(nodes: [], edges: []),
    orders: orders,
  );
  return (worldMarketTurnPhaseHandler(acc, config, 3) as TurnPhaseStepContinue)
      .pipeline
      .game;
}
