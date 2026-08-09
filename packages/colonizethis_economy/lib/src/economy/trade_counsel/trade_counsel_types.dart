/// Trade counsel recommendation DTOs and reason keys.
library;

import 'package:colonizethis_models/colonizethis_models.dart';

enum TradeCounselReasonKey {
  surplusAboveReserve,
  industryShortage,
  speculativeInventory,
}

/// One ranked trade counsel line (full book may exceed three).
final class TradeCounselRecommendation {
  const TradeCounselRecommendation({
    required this.recommendationId,
    required this.order,
    required this.rankScore,
    required this.briefReasonKey,
    required this.detailReasonKeys,
    required this.isHighlight,
  });

  final String recommendationId;
  final TradeOrder order;
  final double rankScore;
  final TradeCounselReasonKey briefReasonKey;
  final List<TradeCounselReasonKey> detailReasonKeys;
  final bool isHighlight;
}

/// Full trade book plus highlight subset for UI stars.
final class TradeCounselBookResult {
  const TradeCounselBookResult({
    this.recommendations = const <TradeCounselRecommendation>[],
    this.book = const <TradeOrder>[],
  });

  static const empty = TradeCounselBookResult();

  final List<TradeCounselRecommendation> recommendations;
  final List<TradeOrder> book;

  bool get isEmpty => book.isEmpty;
}
