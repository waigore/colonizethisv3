/// Human Trade Counsel ranking API. SPEC/program/trade-counsel-ranking.md.
library;

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import 'trade_counsel_emission.dart';

const int _kMaxHighlights = 3;

String tradeCounselStableIdForOrder(TradeOrder order) {
  final prefix = order.type == TradeOrderType.bid ? 'bid' : 'offer';
  return '$prefix:${order.commodityId}';
}

double _rankScoreForOrder({
  required TradeOrder order,
  required WorldMarketState worldMarket,
  required ResourceRules rules,
}) {
  final price = effectiveMarketPriceForCommodityId(
        commodityId: order.commodityId,
        worldMarket: worldMarket,
        resourceRules: rules,
      ) ??
      1;
  if (order.type == TradeOrderType.offer) {
    return order.quantity * price.toDouble();
  }
  final priority = tradeCounselBidPriorityForCommodity(order.commodityId);
  return order.quantity * (10 - priority).toDouble() * price;
}

TradeCounselBookResult rankTradeCounselRecommendations({
  required Game game,
  required String playerId,
  required List<AssignedRecipe> productionAssignments,
  required Orders currentOrders,
  required MapTopology topology,
  required Map<String, TileMapResult> tileMapByRegion,
  Map<String, ExtractionTotals>? extractionById,
  int pendingTreasuryCosts = 0,
}) {
  final book = emitTradeCounselBook(
    TradeCounselEmissionInput(
      game: game,
      playerId: playerId,
      productionAssignments: productionAssignments,
      currentOrders: currentOrders,
      topology: topology,
      tileMapByRegion: tileMapByRegion,
      extractionById: extractionById,
      pendingTreasuryCosts: pendingTreasuryCosts,
    ),
  );
  if (book.isEmpty) return TradeCounselBookResult.empty;

  final rules = ResourceRules.defaultRules;
  final stockpile = game.playerById(playerId)?.stockpile ?? const Stockpile();
  final projected = tradeCounselProjectStockpileAfterProduction(
    stockpile: stockpile,
    productionAssignments: productionAssignments,
  );
  final inputNeeds = tradeCounselInputNeedsFromAssignments(productionAssignments);
  final deficitNeed = <CommodityId, int>{};
  tradeCounselPopulateSurplusAndNeedMaps(
    TradeCounselSurplusNeedMapsInput(
      trackedCommodityIds: tradeCounselTrackedCommodityIds(
        stockpile: stockpile,
        projected: projected,
        inputNeeds: inputNeeds,
        productionAssignments: productionAssignments,
      ),
      inputNeeds: inputNeeds,
      projected: projected,
      carryForwardOffers: const {},
      carryForwardBids: const {},
      marketPrices: game.worldMarketState.prices,
      available: <CommodityId, int>{},
      need: deficitNeed,
    ),
  );
  final speculativeNeed = <CommodityId, int>{...deficitNeed};
  if ((game.playerById(playerId)?.treasury ?? 0) >=
      tradeCounselTreasuryAffluenceThreshold()) {
    tradeCounselAddSpeculativeBidNeeds(
      need: speculativeNeed,
      available: <CommodityId, int>{},
      projected: projected,
      carryForwardBids: const {},
      state: game.worldMarketState,
    );
  }

  final candidates = <TradeCounselRecommendation>[];
  for (final order in book) {
    final rankScore = _rankScoreForOrder(
      order: order,
      worldMarket: game.worldMarketState,
      rules: rules,
    );
    final reason = tradeCounselReasonForOrder(
      order: order,
      deficitNeed: deficitNeed,
      speculativeNeed: speculativeNeed,
    );
    candidates.add(
      TradeCounselRecommendation(
        recommendationId: tradeCounselStableIdForOrder(order),
        order: order,
        rankScore: rankScore,
        briefReasonKey: reason,
        detailReasonKeys: [reason],
        isHighlight: false,
      ),
    );
  }

  final sortedHighlights = [...candidates]
    ..sort((a, b) {
      final scoreCmp = b.rankScore.compareTo(a.rankScore);
      if (scoreCmp != 0) return scoreCmp;
      return a.recommendationId.compareTo(b.recommendationId);
    });
  final highlightIds = sortedHighlights
      .take(_kMaxHighlights)
      .map((r) => r.recommendationId)
      .toSet();

  final recommendations = [
    for (final candidate in candidates)
      TradeCounselRecommendation(
        recommendationId: candidate.recommendationId,
        order: candidate.order,
        rankScore: candidate.rankScore,
        briefReasonKey: candidate.briefReasonKey,
        detailReasonKeys: candidate.detailReasonKeys,
        isHighlight: highlightIds.contains(candidate.recommendationId),
      ),
  ];

  return TradeCounselBookResult(
    recommendations: recommendations,
    book: book,
  );
}

Map<String, TradeCounselRecommendation> tradeCounselHighlightsByCommodityId(
  TradeCounselBookResult result,
) {
  return {
    for (final recommendation in result.recommendations)
      if (recommendation.isHighlight)
        recommendation.order.commodityId: recommendation,
  };
}
