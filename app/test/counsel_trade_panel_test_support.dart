// Shared Counsel Trade tab fixtures and golden hosts (Refs #4282).

import 'package:colonizethis_app/features/game/screens/counsel/counsel_trade_tab_body.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';

const Size kCounselTradePanelGoldenViewport = Size(360, 720);

TradeOrder _tradeCounselTestOrder({
  required String commodityId,
  required TradeOrderType type,
  int quantity = 4,
}) {
  return TradeOrder(
    commodityId: commodityId,
    type: type,
    quantity: quantity,
    priority: 1,
  );
}

TradeCounselRecommendation counselTestTradeOfferRecommendation({
  String commodityId = 'timber',
  int quantity = 12,
  bool isHighlight = true,
}) {
  return TradeCounselRecommendation(
    recommendationId: 'offer:$commodityId',
    order: _tradeCounselTestOrder(
      commodityId: commodityId,
      type: TradeOrderType.offer,
      quantity: quantity,
    ),
    rankScore: 20,
    briefReasonKey: TradeCounselReasonKey.surplusAboveReserve,
    detailReasonKeys: const [TradeCounselReasonKey.surplusAboveReserve],
    isHighlight: isHighlight,
  );
}

TradeCounselRecommendation counselTestTradeBidRecommendation({
  String commodityId = 'fabric',
  int quantity = 6,
  bool isHighlight = true,
}) {
  return TradeCounselRecommendation(
    recommendationId: 'bid:$commodityId',
    order: _tradeCounselTestOrder(
      commodityId: commodityId,
      type: TradeOrderType.bid,
      quantity: quantity,
    ),
    rankScore: 18,
    briefReasonKey: TradeCounselReasonKey.industryShortage,
    detailReasonKeys: const [TradeCounselReasonKey.industryShortage],
    isHighlight: isHighlight,
  );
}

TradeCounselRecommendation counselTestTradeSpeculativeBidRecommendation({
  String commodityId = 'grain',
  int quantity = 8,
  bool isHighlight = true,
}) {
  return TradeCounselRecommendation(
    recommendationId: 'bid:$commodityId',
    order: _tradeCounselTestOrder(
      commodityId: commodityId,
      type: TradeOrderType.bid,
      quantity: quantity,
    ),
    rankScore: 14,
    briefReasonKey: TradeCounselReasonKey.speculativeInventory,
    detailReasonKeys: const [TradeCounselReasonKey.speculativeInventory],
    isHighlight: isHighlight,
  );
}

List<TradeCounselRecommendation> counselTestDefaultTradeRecommendations() {
  return [
    counselTestTradeOfferRecommendation(),
    counselTestTradeBidRecommendation(),
    counselTestTradeSpeculativeBidRecommendation(isHighlight: false),
  ];
}

List<TradeOrder> counselTestTradeBookFromRecommendations(
  List<TradeCounselRecommendation> recommendations,
) {
  return recommendations.map((recommendation) => recommendation.order).toList();
}

/// Mirrors the Trade tab column inside [CounselScreen] for golden captures.
Widget counselTradeTabGoldenHost({
  required List<TradeCounselRecommendation> recommendations,
  List<TradeOrder> book = const <TradeOrder>[],
  String? highlightRecommendationId,
  bool canEdit = true,
  CounselTradeCallbacks callbacks = const CounselTradeCallbacks(),
  Size viewport = kCounselTradePanelGoldenViewport,
}) {
  final l10n = lookupAppLocalizations(const Locale('en'));
  final resolvedBook = book.isEmpty
      ? counselTestTradeBookFromRecommendations(recommendations)
      : book;
  return SizedBox(
    width: viewport.width,
    height: viewport.height,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: Text(
            l10n.tradeCounsel_tabTrade,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: CounselTradeTabBody(
            recommendations: recommendations,
            book: resolvedBook,
            highlightRecommendationId: highlightRecommendationId,
            l10n: l10n,
            canEdit: canEdit,
            callbacks: callbacks,
          ),
        ),
      ],
    ),
  );
}
