// Shared fixtures for world_market_phase_extraction_cargo_test (Refs #4342 Slice C).
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_turn/colonizethis_turn_testing.dart';

import '../support/world_market_test_support.dart';

const extractionCargoBuyerId = 'gpBuyer';

TurnPipelineState extractionCargoTimberPipeline({
  required int shippedTonnage,
  required int sellerTimber,
  required int buyerTreasury,
}) {
  return TurnPipelineState(
    game: gameWithTwoGps(
      sellerStockpile: Stockpile.empty.applyDelta('timber', sellerTimber),
      sellerTreasury: 0,
      buyerTreasury: buyerTreasury,
      marketPrices: const {'timber': 30},
    ),
    overseasExtractionShippedTonnageByPlayerId: <String, int>{
      extractionCargoBuyerId: shippedTonnage,
    },
  );
}

TurnPipelineState extractionCargoTimberPipelineNoTonnageMap({
  required int sellerTimber,
  required int buyerTreasury,
}) {
  return TurnPipelineState(
    game: gameWithTwoGps(
      sellerStockpile: Stockpile.empty.applyDelta('timber', sellerTimber),
      sellerTreasury: 0,
      buyerTreasury: buyerTreasury,
      marketPrices: const {'timber': 30},
    ),
  );
}
