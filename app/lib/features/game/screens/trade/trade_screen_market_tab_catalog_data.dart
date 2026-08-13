// Market-tab catalog data helpers (Refs #4352).
// Split from `trade_screen_market_tab_catalog.dart`.

import 'package:colonizethis_app_l10n/l10n/l10n.dart';

import 'package:colonizethis_data/colonizethis_data.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

import 'trade_screen_contract_market.dart';
import 'trade_screen_market_tab.dart';

String volumeText(MarketActivity activity, AppLocalizations l10n) {
  return l10n.tradeMarket_lastTurnVolume(
    activity.totalBidQuantity,
    activity.totalOfferQuantity,
  );
}

/// Resolves the integer price used for Market display and delta math.
int? effectiveMarketPriceCoins(
  int? price, {
  required CommodityId commodityId,
}) {
  final ResourceRules rules =
      TradeScreenMarketKeys.marketPriceResourceRulesOverride ??
      ResourceRules.defaultRules;
  return price ?? rules.defaultMarketPriceForCommodityId(commodityId);
}

/// Returns the tradeable commodities grouped by their
/// [CommodityCategory] in catalog order.
SectionedTradeableCommodities tradeableCommoditiesByCategory() {
  final List<Commodity> food = <Commodity>[];
  final List<Commodity> rawMaterials = <Commodity>[];
  final List<Commodity> manufactured = <Commodity>[];
  for (final Commodity c in CommodityCatalog.all) {
    if (c.category == CommodityCategory.riches) continue;
    if (c.id == 'spices') continue;
    switch (c.category) {
      case CommodityCategory.food:
        food.add(c);
      case CommodityCategory.rawMaterial:
        rawMaterials.add(c);
      case CommodityCategory.manufactured:
        manufactured.add(c);
      case CommodityCategory.luxury:
      case CommodityCategory.riches:
      case CommodityCategory.advanced:
        break;
    }
  }
  return SectionedTradeableCommodities(
    food: food,
    rawMaterials: rawMaterials,
    manufactured: manufactured,
  );
}

/// Formats the per-commodity market price for the Market tab row.
String formatMarketPrice(int? price, {required CommodityId commodityId}) {
  final int? effective =
      effectiveMarketPriceCoins(price, commodityId: commodityId);
  if (effective == null) return MarketTabContent.priceUnknownGlyph;
  return effective.toString();
}

/// Pre-grouped tradeable commodities passed from
/// `tradeableCommoditiesByCategory()` to the section builder.
class SectionedTradeableCommodities {
  const SectionedTradeableCommodities({
    required this.food,
    required this.rawMaterials,
    required this.manufactured,
  });

  final List<Commodity> food;
  final List<Commodity> rawMaterials;
  final List<Commodity> manufactured;
}
