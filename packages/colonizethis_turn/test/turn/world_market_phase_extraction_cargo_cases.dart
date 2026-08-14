// Shared fixtures for world_market_phase_extraction_cargo_test (Refs #4342 Slice C).
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';

import '../support/world_market_test_support.dart';

const extractionCargoBuyerId = 'gpBuyer';
const extractionCargoSellerId = 'gpSeller';

Game runExtractionCargoTimberPhase({
  required int shippedTonnage,
  required int offerQuantity,
  required int bidQuantity,
  required int sellerTimber,
  required int buyerTreasury,
}) {
  final game = gameWithTwoGps(
    sellerStockpile: Stockpile.empty.applyDelta('timber', sellerTimber),
    sellerTreasury: 0,
    buyerTreasury: buyerTreasury,
    marketPrices: const {'timber': 30},
  );
  return runWorldMarketPhaseFrom(
    pipeline: TurnPipelineState(
      game: game,
      overseasExtractionShippedTonnageByPlayerId: <String, int>{
        extractionCargoBuyerId: shippedTonnage,
      },
    ),
    orders: gpGpTimberTradeOrders(
      offerQuantity: offerQuantity,
      bidQuantity: bidQuantity,
    ),
  );
}

Game runExtractionCargoTimberPhaseNoTonnageMap({
  required int offerQuantity,
  required int bidQuantity,
  required int sellerTimber,
  required int buyerTreasury,
}) {
  final game = gameWithTwoGps(
    sellerStockpile: Stockpile.empty.applyDelta('timber', sellerTimber),
    sellerTreasury: 0,
    buyerTreasury: buyerTreasury,
    marketPrices: const {'timber': 30},
  );
  return runWorldMarketPhaseFrom(
    pipeline: TurnPipelineState(game: game),
    orders: gpGpTimberTradeOrders(
      offerQuantity: offerQuantity,
      bidQuantity: bidQuantity,
    ),
  );
}
