import 'package:colonizethis_models/colonizethis_models.dart';

/// Shared two-GP world-market fixture used by the B3 GP↔GP and carry-forward
/// re-validation integration tests.
///
/// Builds a [Game] with a `gpSeller` and `gpBuyer`, an empty old/new world,
/// and a [WorldMarketState] seeded with the provided [marketPrices]. The
/// resulting game is suitable for direct dispatch through
/// `worldMarketTurnPhaseHandler` without any prior pipeline phases running.
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
