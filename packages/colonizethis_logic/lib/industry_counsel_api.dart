/// Narrow export for Industry, Trade, Military, and Development Counsel ranking.
library;

export 'package:colonizethis_economy/colonizethis_economy.dart'
    show
        TradeCounselBookResult,
        TradeCounselReasonKey,
        TradeCounselRecommendation;
export 'package:colonizethis_orders/colonizethis_orders.dart'
    show
        DevelopmentCounselReasonKey,
        DevelopmentCounselRecommendation,
        DevelopmentCounselRecommendationKind,
        MilitaryCounselBuildCostSnapshot,
        MilitaryCounselInvasionIntelLevel,
        MilitaryCounselInvasionIntelSummary,
        MilitaryCounselReasonKey,
        MilitaryCounselRecommendation,
        MilitaryCounselRecommendationKind,
        TradeCounselEmissionInput,
        emitTradeCounselBook,
        industryCounselCoreDesiredOutputByRecipe,
        mergeIndustryCounselCoreDesiredOutput,
        militaryCounselGreedyAffordableBuildCount,
        rankDevelopmentCounselRecommendations,
        rankIndustryCounselRecommendations,
        rankMilitaryCounselRecommendations,
        rankTradeCounselRecommendations,
        tradeCounselHighlightsByCommodityId,
        tradeCounselStableIdForOrder;
export 'package:colonizethis_turn/colonizethis_turn.dart'
    show pendingTreasuryCostsForTurn;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart'
    show ExtractionTotals, TradeCounselBookResult;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show rankTradeCounselRecommendations;

import 'package:colonizethis_turn/colonizethis_turn.dart'
    show pendingTreasuryCostsForTurn;

/// Ranks trade counsel with pending non-trade treasury costs applied.
TradeCounselBookResult rankTradeCounselRecommendationsForHuman({
  required Game game,
  required String playerId,
  required List<AssignedRecipe> productionAssignments,
  required Orders currentOrders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  Map<String, ExtractionTotals>? extractionById,
}) {
  final pendingCosts = pendingTreasuryCostsForTurn(
    game,
    playerId,
    currentOrders,
  );
  return rankTradeCounselRecommendations(
    game: game,
    playerId: playerId,
    productionAssignments: productionAssignments,
    currentOrders: currentOrders,
    topology: topology,
    tileMapByRegion: tileMapByRegion,
    extractionById: extractionById,
    pendingTreasuryCosts: pendingCosts,
  );
}
