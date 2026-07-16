// Market-tab catalog helpers and section row builders.
// Split from `trade_screen_market_tab_handlers.dart` to keep each trade-screen
// part under the repo file-size target (Refs #3878).

part of 'trade_screen.dart';

extension _MarketTabContentCatalog on _MarketTabContent {
  /// Builds the widget list that renders one Market commodity category
  /// section: a `CtSectionLabel` header keyed by [sectionKey] followed
  /// by the per-commodity rows for [commodities] in their input order.
  /// Returns an empty list when [commodities] is empty so an absent
  /// category does not leak an orphan header (defensive — every
  /// section is non-empty on the live catalog today; a future ruleset
  /// could thin them out).
  ///
  /// [isFirstSection] controls the leading vertical gap so the first
  /// section snugs against the cargo header without leaving extra
  /// whitespace, and subsequent sections get a 12 dp separator that
  /// matches the Production panel's between-section gap.
  List<Widget> _buildCommoditySectionWidgets({
    required Key sectionKey,
    required String sectionLabel,
    required List<Commodity> commodities,
    required Map<CommodityId, int> offerCap,
    required Map<CommodityId, int> stagedOffers,
    required WorldMarketState market,
    required Orders orders,
    required TextStyle nameStyle,
    required TextStyle priceStyle,
    required TextStyle volumeStyle,
    required TextStyle quantityStyle,
    required void Function(CommodityId commodityId, TradeOrderType? next)
        onDirectionChanged,
    required void Function(CommodityId commodityId, int delta) onQuantityDelta,
    required AppLocalizations l10n,
    bool isFirstSection = true,
  }) {
    if (commodities.isEmpty) return const <Widget>[];
    return <Widget>[
      if (!isFirstSection) const SizedBox(height: 12),
      CtSectionLabel(sectionLabel, key: sectionKey),
      const SizedBox(height: 6),
      for (int index = 0; index < commodities.length; index++)
        Padding(
          key: TradeScreenMarketKeys.marketCommodityRowKey(commodities[index].id),
          padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
          child: _MarketCommodityRow(
            commodityId: commodities[index].id,
            commodityDisplayName:
                commodityDisplayName(l10n, commodities[index].id),
            priceText: _formatPrice(
              market.prices[commodities[index].id],
              commodityId: commodities[index].id,
            ),
            volumeText: _volumeText(
              market.lastTurnActivity[commodities[index].id] ??
                  MarketActivity.empty,
            ),
            stagedOrder: tradeOrderForPlayerCommodity(
              orders,
              playerId,
              commodities[index].id,
            ),
            sellableHeadroom: _sellableHeadroomFor(
              offerCap: offerCap,
              stagedOffers: stagedOffers,
              commodityId: commodities[index].id,
            ),
            offerCap: offerCap[commodities[index].id] ?? 0,
            nameStyle: nameStyle,
            priceStyle: priceStyle,
            volumeStyle: volumeStyle,
            quantityStyle: quantityStyle,
            onDirectionChanged: (TradeOrderType? next) =>
                onDirectionChanged(commodities[index].id, next),
            onIncrement: () => onQuantityDelta(commodities[index].id, 1),
            onDecrement: () => onQuantityDelta(commodities[index].id, -1),
          ),
        ),
    ];
  }
}

/// Returns the per-row sellable headroom shown as `(N)` next to the
/// commodity name on the Trade Market tab (Refs #3093 — sellable
/// clamp slice). Equals `max(0, offerCap[c] − stagedOffer[c])` for
/// the row's commodity. Mirrors
/// `sellableHeadroomByCommodityId` but with per-row resolution so
/// the build path passes one int per row instead of rebuilding the
/// full map per child.
int _sellableHeadroomFor({
  required Map<CommodityId, int> offerCap,
  required Map<CommodityId, int> stagedOffers,
  required CommodityId commodityId,
}) {
  final int cap = offerCap[commodityId] ?? 0;
  final int staged = stagedOffers[commodityId] ?? 0;
  final int headroom = cap - staged;
  return headroom < 0 ? 0 : headroom;
}

String _volumeText(MarketActivity activity) {
  return '${_MarketTabContent.bidsLabel} ${activity.totalBidQuantity} / '
      '${_MarketTabContent.offersLabel} ${activity.totalOfferQuantity}';
}

/// Returns the tradeable commodities grouped by their
/// [CommodityCategory] in catalog order (Refs `#3093` § Layout &
/// grouping — sectioned grouping slice). Spices and riches are
/// excluded per `SPEC/game/world-market.md` § Tradeable commodities,
/// leaving 22 rows split across three sections (food / raw materials
/// / manufactured). Within each section the per-commodity order
/// preserves `CommodityCatalog.all` iteration order so this surface
/// matches the Production panel's Available subpanel (which iterates
/// the same catalog list filtered by category).
_SectionedTradeableCommodities _tradeableCommoditiesByCategory() {
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
  return _SectionedTradeableCommodities(
    food: food,
    rawMaterials: rawMaterials,
    manufactured: manufactured,
  );
}

/// Formats the per-commodity market price for the Market tab row.
///
/// Prices on `Game.worldMarketState.prices` are integers per
/// `SPEC/game/world-market.md` § Price discovery and SPEC/ui/trade-screen.md
/// § Market tab — read-only commodity table. When the prices map lacks an
/// entry for a tradeable commodity, this helper falls back to the catalog
/// default from `ResourceRules.defaultRules.defaultMarketPriceForCommodityId`,
/// which now covers every tradeable commodity — raw resources (per the
/// `Resource` enum default-price map) and manufactured commodities (per
/// `SPEC/game/commodity-catalog.md` § Manufactured base prices). The
/// canonical em-dash glyph is a defensive fallback retained for future
/// commodity additions that ship without a catalog default.
String _formatPrice(int? price, {required CommodityId commodityId}) {
  final ResourceRules rules =
      TradeScreenMarketKeys.marketPriceResourceRulesOverride ??
      ResourceRules.defaultRules;
  final int? effective =
      price ?? rules.defaultMarketPriceForCommodityId(commodityId);
  if (effective == null) return _MarketTabContent.priceUnknownGlyph;
  return effective.toString();
}

/// Pre-grouped tradeable commodities passed from
/// `_tradeableCommoditiesByCategory()` to the section builder. Holds
/// the three Market tab sections (food / raw materials / manufactured)
/// in catalog order so the renderer does not re-iterate
/// [CommodityCatalog.all] per section.
class _SectionedTradeableCommodities {
  const _SectionedTradeableCommodities({
    required this.food,
    required this.rawMaterials,
    required this.manufactured,
  });

  final List<Commodity> food;
  final List<Commodity> rawMaterials;
  final List<Commodity> manufactured;
}
