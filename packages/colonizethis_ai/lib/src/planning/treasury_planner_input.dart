import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/ai_api.dart'
    show
        ExtractionTotals,
        cargoHoldsForHomeFleet,
        tradeCargoCapacityForGreatPower;
import 'package:colonizethis_models/colonizethis_models.dart';

import '../perception/perception_snapshot.dart';

/// Bundles inputs for [runTreasuryPlanner] (Refs #3972 AC5).
final class TreasuryPlannerInput {
  const TreasuryPlannerInput({
    required this.game,
    required this.playerId,
    required this.stockpile,
    required this.productionAssignments,
    required this.treasury,
    this.snapshot,
    this.tileMapByRegion,
    this.topology,
    this.currentOrders = const Orders(),
    this.resourceRules,
    this.extractionById,
  });

  final Game game;
  final String playerId;
  final Stockpile stockpile;
  final List<AssignedRecipe> productionAssignments;
  final int treasury;
  final AIWorldSnapshot? snapshot;
  final Map<String, TileMapResult>? tileMapByRegion;
  final MapTopology? topology;
  final Orders currentOrders;
  final ResourceRules? resourceRules;
  final Map<String, ExtractionTotals>? extractionById;
}

/// Resolves this GP's per-turn trade cargo capacity.
int resolveTradeCargoCapacity({
  required Game game,
  required String playerId,
  required Map<String, TileMapResult>? tileMapByRegion,
  required MapTopology? topology,
  Map<String, ExtractionTotals>? extractionById,
}) {
  if (tileMapByRegion != null &&
      tileMapByRegion.isNotEmpty &&
      topology != null) {
    return tradeCargoCapacityForGreatPower(
      game: game,
      playerId: playerId,
      tileMapByRegion: tileMapByRegion,
      topology: topology,
      extractionById: extractionById,
    );
  }
  final homeFleetHolds = cargoHoldsForHomeFleet(game, playerId);
  return homeFleetHolds < 0 ? 0 : homeFleetHolds;
}
