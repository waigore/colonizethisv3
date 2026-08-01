// Market-tab catalog helpers and section row builders.
// Split from `trade_screen_market_tab_handlers.dart` to keep each trade-screen
// part under the repo file-size target (Refs #3878).


import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../../widgets/ct_section_label.dart';
import '../../widgets/production/commodity_ui_helpers.dart';
import 'trade_screen_contract_market.dart';
import 'trade_screen_market_row.dart';
import 'trade_screen_market_tab.dart';
import 'trade_screen_market_tab_order_handlers.dart';

extension MarketTabContentCatalog on MarketTabContent {
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
  ///
  /// When [wideLayout] is true (content width ≥
  /// [TradeScreenMarketKeys.marketTwoColumnMinWidth]), rows render in a
  /// row-major two-column grid with compact two-line rows (Refs #4227).
  List<Widget> buildCommoditySectionWidgets({
    required Key sectionKey,
    required String sectionLabel,
    required List<Commodity> commodities,
    required Map<CommodityId, int> offerCap,
    required Map<CommodityId, int> stagedOffers,
    required int bidTypeCap,
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
    required Set<CommodityId> firstRightCommodityIds,
    bool isFirstSection = true,
    bool wideLayout = false,
  }) {
    if (commodities.isEmpty) return const <Widget>[];
    return <Widget>[
      if (!isFirstSection) const SizedBox(height: 12),
      CtSectionLabel(sectionLabel, key: sectionKey),
      const SizedBox(height: 6),
      if (wideLayout)
        ..._buildWideCommodityGrid(
          commodities: commodities,
          offerCap: offerCap,
          stagedOffers: stagedOffers,
          bidTypeCap: bidTypeCap,
          market: market,
          orders: orders,
          nameStyle: nameStyle,
          priceStyle: priceStyle,
          volumeStyle: volumeStyle,
          quantityStyle: quantityStyle,
          onDirectionChanged: onDirectionChanged,
          onQuantityDelta: onQuantityDelta,
          l10n: l10n,
          firstRightCommodityIds: firstRightCommodityIds,
        )
      else
        ..._buildNarrowCommodityList(
          commodities: commodities,
          offerCap: offerCap,
          stagedOffers: stagedOffers,
          bidTypeCap: bidTypeCap,
          market: market,
          orders: orders,
          nameStyle: nameStyle,
          priceStyle: priceStyle,
          volumeStyle: volumeStyle,
          quantityStyle: quantityStyle,
          onDirectionChanged: onDirectionChanged,
          onQuantityDelta: onQuantityDelta,
          l10n: l10n,
          firstRightCommodityIds: firstRightCommodityIds,
        ),
    ];
  }

  List<Widget> _buildNarrowCommodityList({
    required List<Commodity> commodities,
    required Map<CommodityId, int> offerCap,
    required Map<CommodityId, int> stagedOffers,
    required int bidTypeCap,
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
    required Set<CommodityId> firstRightCommodityIds,
  }) {
    return <Widget>[
      for (int index = 0; index < commodities.length; index++)
        Padding(
          key: TradeScreenMarketKeys.marketCommodityRowKey(commodities[index].id),
          padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
          child: _buildCommodityRow(
            commodity: commodities[index],
            compact: false,
            offerCap: offerCap,
            stagedOffers: stagedOffers,
            bidTypeCap: bidTypeCap,
            market: market,
            orders: orders,
            nameStyle: nameStyle,
            priceStyle: priceStyle,
            volumeStyle: volumeStyle,
            quantityStyle: quantityStyle,
            onDirectionChanged: onDirectionChanged,
            onQuantityDelta: onQuantityDelta,
            l10n: l10n,
            firstRightCommodityIds: firstRightCommodityIds,
          ),
        ),
    ];
  }

  List<Widget> _buildWideCommodityGrid({
    required List<Commodity> commodities,
    required Map<CommodityId, int> offerCap,
    required Map<CommodityId, int> stagedOffers,
    required int bidTypeCap,
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
    required Set<CommodityId> firstRightCommodityIds,
  }) {
    final List<Widget> rows = <Widget>[];
    for (int index = 0; index < commodities.length; index += 2) {
      final Commodity left = commodities[index];
      final Commodity? right =
          index + 1 < commodities.length ? commodities[index + 1] : null;
      rows.add(
        Padding(
          padding: EdgeInsets.only(
            top: index == 0 ? 0 : TradeScreenMarketKeys.marketGridRowGap,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Padding(
                  key: TradeScreenMarketKeys.marketCommodityRowKey(left.id),
                  padding: EdgeInsets.zero,
                  child: _buildCommodityRow(
                    commodity: left,
                    compact: true,
                    offerCap: offerCap,
                    stagedOffers: stagedOffers,
                    bidTypeCap: bidTypeCap,
                    market: market,
                    orders: orders,
                    nameStyle: nameStyle,
                    priceStyle: priceStyle,
                    volumeStyle: volumeStyle,
                    quantityStyle: quantityStyle,
                    onDirectionChanged: onDirectionChanged,
                    onQuantityDelta: onQuantityDelta,
                    l10n: l10n,
                    firstRightCommodityIds: firstRightCommodityIds,
                  ),
                ),
              ),
              const SizedBox(width: TradeScreenMarketKeys.marketGridColumnGap),
              Expanded(
                child: right == null
                    ? const SizedBox.shrink()
                    : Padding(
                        key: TradeScreenMarketKeys.marketCommodityRowKey(right.id),
                        padding: EdgeInsets.zero,
                        child: _buildCommodityRow(
                          commodity: right,
                          compact: true,
                          offerCap: offerCap,
                          stagedOffers: stagedOffers,
                          bidTypeCap: bidTypeCap,
                          market: market,
                          orders: orders,
                          nameStyle: nameStyle,
                          priceStyle: priceStyle,
                          volumeStyle: volumeStyle,
                          quantityStyle: quantityStyle,
                          onDirectionChanged: onDirectionChanged,
                          onQuantityDelta: onQuantityDelta,
                          l10n: l10n,
                          firstRightCommodityIds: firstRightCommodityIds,
                        ),
                      ),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  Widget _buildCommodityRow({
    required Commodity commodity,
    required bool compact,
    required Map<CommodityId, int> offerCap,
    required Map<CommodityId, int> stagedOffers,
    required int bidTypeCap,
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
    required Set<CommodityId> firstRightCommodityIds,
  }) {
    final CommodityId commodityId = commodity.id;
    final bool showFirstRightChip = firstRightCommodityIds.contains(commodityId);
    final rowParams = (
      commodityId: commodityId,
      commodityDisplayName: commodityDisplayName(l10n, commodityId),
      priceText: formatMarketPrice(
        market.prices[commodityId],
        commodityId: commodityId,
      ),
      volumeText: volumeText(
        market.lastTurnActivity[commodityId] ?? MarketActivity.empty,
      ),
      stagedOrder: tradeOrderForPlayerCommodity(orders, playerId, commodityId),
      sellableHeadroom: sellableHeadroomFor(
        offerCap: offerCap,
        stagedOffers: stagedOffers,
        commodityId: commodityId,
      ),
      offerCap: offerCap[commodityId] ?? 0,
      canSelectBid: canStageBidOnCommodity(
        orders: orders,
        playerId: playerId,
        commodityId: commodityId,
        bidTypeCap: bidTypeCap,
      ),
      nameStyle: nameStyle,
      priceStyle: priceStyle,
      volumeStyle: volumeStyle,
      quantityStyle: quantityStyle,
      onDirectionChanged: (TradeOrderType? next) =>
          onDirectionChanged(commodityId, next),
      onIncrement: () => onQuantityDelta(commodityId, 1),
      onDecrement: () => onQuantityDelta(commodityId, -1),
    );
    if (compact) {
      return MarketCommodityRowCompact(
        commodityId: rowParams.commodityId,
        commodityDisplayName: rowParams.commodityDisplayName,
        priceText: rowParams.priceText,
        volumeText: rowParams.volumeText,
        stagedOrder: rowParams.stagedOrder,
        sellableHeadroom: rowParams.sellableHeadroom,
        offerCap: rowParams.offerCap,
        canSelectBid: rowParams.canSelectBid,
        nameStyle: rowParams.nameStyle,
        priceStyle: rowParams.priceStyle,
        volumeStyle: rowParams.volumeStyle,
        quantityStyle: rowParams.quantityStyle,
        onDirectionChanged: rowParams.onDirectionChanged,
        onIncrement: rowParams.onIncrement,
        onDecrement: rowParams.onDecrement,
        showFirstRightChip: showFirstRightChip,
        firstRightChipLabel: l10n.tradeMarket_firstRightChip,
        firstRightTooltip: l10n.tradeMarket_firstRightTooltip,
      );
    }
    return MarketCommodityRow(
      commodityId: rowParams.commodityId,
      commodityDisplayName: rowParams.commodityDisplayName,
      priceText: rowParams.priceText,
      volumeText: rowParams.volumeText,
      stagedOrder: rowParams.stagedOrder,
      sellableHeadroom: rowParams.sellableHeadroom,
      offerCap: rowParams.offerCap,
      canSelectBid: rowParams.canSelectBid,
      nameStyle: rowParams.nameStyle,
      priceStyle: rowParams.priceStyle,
      volumeStyle: rowParams.volumeStyle,
      quantityStyle: rowParams.quantityStyle,
      onDirectionChanged: rowParams.onDirectionChanged,
      onIncrement: rowParams.onIncrement,
      onDecrement: rowParams.onDecrement,
      showFirstRightChip: showFirstRightChip,
      firstRightChipLabel: l10n.tradeMarket_firstRightChip,
      firstRightTooltip: l10n.tradeMarket_firstRightTooltip,
    );
  }
}

/// Returns the per-row sellable headroom shown as `(N)` next to the
/// commodity name on the Trade Market tab (Refs #3093 — sellable
/// clamp slice). Equals `max(0, offerCap[c] − stagedOffer[c])` for
/// the row's commodity. Mirrors
/// `sellableHeadroomByCommodityId` but with per-row resolution so
/// the build path passes one int per row instead of rebuilding the
/// full map per child.
int sellableHeadroomFor({
  required Map<CommodityId, int> offerCap,
  required Map<CommodityId, int> stagedOffers,
  required CommodityId commodityId,
}) {
  final int cap = offerCap[commodityId] ?? 0;
  final int staged = stagedOffers[commodityId] ?? 0;
  final int headroom = cap - staged;
  return headroom < 0 ? 0 : headroom;
}

String volumeText(MarketActivity activity) {
  return '${MarketTabContent.bidsLabel} ${activity.totalBidQuantity} / '
      '${MarketTabContent.offersLabel} ${activity.totalOfferQuantity}';
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
String formatMarketPrice(int? price, {required CommodityId commodityId}) {
  final ResourceRules rules =
      TradeScreenMarketKeys.marketPriceResourceRulesOverride ??
      ResourceRules.defaultRules;
  final int? effective =
      price ?? rules.defaultMarketPriceForCommodityId(commodityId);
  if (effective == null) return MarketTabContent.priceUnknownGlyph;
  return effective.toString();
}

/// Pre-grouped tradeable commodities passed from
/// `tradeableCommoditiesByCategory()` to the section builder. Holds
/// the three Market tab sections (food / raw materials / manufactured)
/// in catalog order so the renderer does not re-iterate
/// [CommodityCatalog.all] per section.
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
