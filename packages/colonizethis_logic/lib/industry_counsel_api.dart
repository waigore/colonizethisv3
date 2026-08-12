/// Narrow export for Industry, Trade, Military, and Development Counsel ranking.
library;

export 'package:colonizethis_economy/colonizethis_economy.dart'
    show
        TradeCounselBookResult,
        TradeCounselReasonKey,
        TradeCounselRecommendation;
export 'package:colonizethis_orders/src/orders/development_counsel_ranking.dart'
    show rankDevelopmentCounselRecommendations;
export 'package:colonizethis_orders/src/orders/development_counsel_types.dart'
    show
        DevelopmentCounselReasonKey,
        DevelopmentCounselRecommendation,
        DevelopmentCounselRecommendationKind;
export 'package:colonizethis_orders/src/orders/industry_counsel_core_snapshot.dart'
    show
        industryCounselCoreDesiredOutputByRecipe,
        mergeIndustryCounselCoreDesiredOutput;
export 'package:colonizethis_orders/src/orders/industry_counsel_ranking.dart'
    show rankIndustryCounselRecommendations;
export 'package:colonizethis_orders/src/orders/military_counsel_affordance.dart'
    show militaryCounselGreedyAffordableBuildCount;
export 'package:colonizethis_orders/src/orders/military_counsel_ranking.dart'
    show rankMilitaryCounselRecommendations;
export 'package:colonizethis_orders/src/orders/military_counsel_types.dart'
    show
        MilitaryCounselBuildCostSnapshot,
        MilitaryCounselInvasionIntelLevel,
        MilitaryCounselInvasionIntelSummary,
        MilitaryCounselReasonKey,
        MilitaryCounselRecommendation,
        MilitaryCounselRecommendationKind;
export 'package:colonizethis_orders/src/orders/trade_counsel_emission.dart'
    show emitTradeCounselBook, TradeCounselEmissionInput;
export 'package:colonizethis_orders/src/orders/trade_counsel_ranking.dart'
    show
        rankTradeCounselRecommendations,
        tradeCounselHighlightsByCommodityId,
        tradeCounselStableIdForOrder;
export 'package:colonizethis_turn/colonizethis_turn.dart'
    show pendingTreasuryCostsForTurn;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart'
    show ExtractionTotals, TradeCounselBookResult;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/src/orders/trade_counsel_ranking.dart'
    as trade_counsel_ranking;

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
  return trade_counsel_ranking.rankTradeCounselRecommendations(
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
