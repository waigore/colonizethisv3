import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

String tradeCounselBriefForReason(
  AppLocalizations l10n,
  TradeCounselReasonKey key,
) {
  return switch (key) {
    TradeCounselReasonKey.surplusAboveReserve =>
      l10n.tradeCounsel_reason_surplusAboveReserve_brief,
    TradeCounselReasonKey.industryShortage =>
      l10n.tradeCounsel_reason_industryShortage_brief,
    TradeCounselReasonKey.speculativeInventory =>
      l10n.tradeCounsel_reason_speculativeInventory_brief,
  };
}

String tradeCounselTitleForRecommendation(
  AppLocalizations l10n,
  TradeCounselRecommendation recommendation,
) {
  final commodity = CommodityCatalog.byId[recommendation.order.commodityId];
  final name = commodity?.displayName ?? recommendation.order.commodityId;
  final qty = recommendation.order.quantity;
  return recommendation.order.type == TradeOrderType.bid
      ? l10n.tradeCounsel_title_bid(name, qty)
      : l10n.tradeCounsel_title_offer(name, qty);
}

String commodityDisplayNameForTradeCounsel(
  AppLocalizations l10n,
  CommodityId commodityId,
) {
  final commodity = CommodityCatalog.byId[commodityId];
  if (commodity == null) return commodityId;
  return commodity.displayName;
}
