// Market tab body for the World Market Trade screen
// (Refs #2993, #3093, #3487, #3546, split out from `trade_screen.dart` to
// keep the host file under the repo code-review physical-line limit and the
// issue #3594 ≤700-line target — see
// `SPEC/program/dart-file-non-comment-line-size.md` and the
// `.cursor/rules/colonizethis-code-review.mdc` >1000-physical-line rule).
//
// Order handlers and catalog helpers live in
// `trade_screen_market_tab_handlers.dart` (Refs #3878).
//
// All classes here are library-private (`_MarketTabContent`,
// `_SectionedTradeableCommodities`) and consumed only by
// `_TradeScreenTabsBody` inside the parent library, so they keep using
// `TradeScreen` static constants and the sibling `_MarketCommodityRow`
// part fragment without further plumbing.

part of 'trade_screen.dart';

/// Interactive commodity table for the Market tab (Refs #2993 E5a + E5b).
///
/// Renders one row per tradeable commodity (the full
/// [CommodityCatalog.all] list with [CommodityCategory.riches] and
/// `spices` filtered out per SPEC/game/world-market.md §Tradeable
/// commodities — 22 rows total). Each row pins:
///
/// * `commodity name` (`titleSmall`, `--accent`),
/// * `last market price` from [WorldMarketState.prices] (`titleSmall`,
///   `--accentBright`) — formatted to one decimal place; a long em dash
///   renders when the commodity is absent from the state map (an
///   empty / un-seeded market — typically only seen in tests),
/// * the previous-turn aggregate volume line `Bids X / Offers Y` from
///   [WorldMarketState.lastTurnActivity] (`bodySmall`, `--muted`),
/// * the interactive direction selector (`None` / `Bid` / `Offer`)
///   wired to `currentOrdersProvider` so each chip tap stages or
///   removes a [TradeOrder] for the commodity (Refs #2993 E5b),
/// * the interactive quantity stepper (`-` / quantity / `+`) that
///   adjusts the staged [TradeOrder.quantity] when a direction is
///   selected; idle when the row is `None`.
///
/// Rows are sorted by display name (case-insensitive) so the order is
/// deterministic for widget tests and Widgetbook stories. The list is
/// scrollable (the cargo indicator header from Refs #2993 E5c lands
/// above the list when its plumbing arrives — Refs #2988 §UI Design).
class _MarketTabContent extends ConsumerWidget {
  const _MarketTabContent({
    super.key,
    required this.game,
    required this.playerId,
    required this.canEdit,
  });

  final Game game;
  final String playerId;
  final bool canEdit;

  /// Rendered when a commodity has no entry in [WorldMarketState.prices]
  /// (typically only happens in unit tests / Widgetbook stories that
  /// instantiate `WorldMarketState.empty`).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String priceUnknownGlyph = '—';

  /// Inline label prefix for the previous-turn bid volume column.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String bidsLabel = 'Bids';

  /// Inline label prefix for the previous-turn offer volume column.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String offersLabel = 'Offers';

  /// Localized chip label for the `None` direction (no staged trade
  /// order on this row).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String noneChipLabel = 'None';

  /// Localized chip label for the `Bid` direction (stages a
  /// [TradeOrderType.bid] for the commodity).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String bidChipLabel = 'Bid';

  /// Localized chip label for the `Offer` direction (stages a
  /// [TradeOrderType.offer] for the commodity).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String offerChipLabel = 'Offer';

  /// Tooltip / semantic label for the decrement stepper button.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String decrementSemanticLabel = 'Decrease quantity';

  /// Tooltip / semantic label for the increment stepper button.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String incrementSemanticLabel = 'Increase quantity';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ThemeData theme = Theme.of(context);
    final TextStyle nameStyle =
        (theme.textTheme.titleSmall ?? const TextStyle(fontSize: 14))
            .copyWith(color: EditorialMonoclePalette.accent);
    final TextStyle priceStyle =
        (theme.textTheme.titleSmall ?? const TextStyle(fontSize: 14))
            .copyWith(color: EditorialMonoclePalette.accentBright);
    final TextStyle volumeStyle =
        (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12))
            .copyWith(color: EditorialMonoclePalette.muted);
    final TextStyle quantityStyle =
        (theme.textTheme.titleSmall ?? const TextStyle(fontSize: 14))
            .copyWith(color: EditorialMonoclePalette.accentBright);
    final TextStyle cargoIndicatorStyle =
        (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12))
            .copyWith(color: EditorialMonoclePalette.accent);
    final TextStyle cargoWarningStyle =
        (theme.textTheme.bodySmall ?? const TextStyle(fontSize: 12))
            .copyWith(color: EditorialMonoclePalette.danger);

    final _SectionedTradeableCommodities sectioned =
        _tradeableCommoditiesByCategory();
    final AppLocalizations l10n = appL10n(context);
    final WorldMarketState market = game.worldMarketState;
    final Orders orders = ref.watch(currentOrdersProvider);
    final CurrentOrdersNotifier ordersNotifier =
        ref.read(currentOrdersProvider.notifier);

    int? readProjectedTreasuryDelta() {
      try {
        return ref.read(treasurySummaryProvider).projectedDelta;
      } on Object {
        return null;
      }
    }

    final int tradeCargoCapacity = cargoHoldsForHomeFleet(game, playerId);
    final int totalStagedBid = _totalStagedBidQuantity(orders, playerId);
    final int remainingCargo = tradeCargoCapacity - totalStagedBid;
    final int clampedRemaining = remainingCargo < 0 ? 0 : remainingCargo;
    final bool warningVisible =
        clampedRemaining == 0 && totalStagedBid > 0;

    // Refs #3093 — sellable clamp slice. Compute the per-commodity offer
    // cap and the player's already-staged offer quantities once per
    // build so the rows below render `(headroom)` and clamp Offer
    // toggles / `+` increments consistently. The helpers live in
    // `colonizethis_logic` (pure functions) and are safe to call per
    // frame. Industry-allocation reservations come from the player's
    // current production assignments (derived from
    // `productionDesiredOutputProvider`); subtracting them from the
    // raw stockpile makes the sellable readout match
    // `SPEC/game/world-market.md` § Per-commodity quantity cap. We
    // `watch` the provider so allocation changes (e.g. the user
    // returning from the Production screen) immediately refresh the
    // sellable readouts without leaving the Market tab.
    final Map<String, int> desiredOutputByRecipe =
        ref.watch(productionDesiredOutputProvider);
    final Map<CommodityId, int> productionInputConsumption =
        _consumptionForDesiredOutput(desiredOutputByRecipe);
    final Map<CommodityId, int> offerCap = offerCapByCommodityId(
      game: game,
      playerId: playerId,
      productionInputConsumptionByCommodityId: productionInputConsumption,
    );
    final Map<CommodityId, int> stagedOffers =
        stagedOfferQuantitiesByCommodityId(
      orders: orders,
      playerId: playerId,
    );

    // Refs #3546 — collapse the three verbatim per-section closure pairs into a
    // single factory call. The shared per-build order context is bound once;
    // the projected treasury delta is still read lazily per interaction inside
    // the factory (behaviour-preserving).
    final TradeSectionHandlers sectionHandlers = buildTradeSectionHandlers(
      readProjectedTreasuryDelta: readProjectedTreasuryDelta,
      handleDirectionChanged: ({
        required CommodityId commodityId,
        required TradeOrderType? next,
        required int? projectedTreasuryDelta,
      }) =>
          _handleDirectionChanged(
            ordersNotifier: ordersNotifier,
            orders: orders,
            productionInputConsumption: productionInputConsumption,
            projectedTreasuryDelta: projectedTreasuryDelta,
            commodityId: commodityId,
            next: next,
          ),
      handleQuantityDelta: ({
        required CommodityId commodityId,
        required int delta,
        required int? projectedTreasuryDelta,
      }) =>
          _handleQuantityDelta(
            ordersNotifier: ordersNotifier,
            orders: orders,
            productionInputConsumption: productionInputConsumption,
            projectedTreasuryDelta: projectedTreasuryDelta,
            commodityId: commodityId,
            delta: delta,
          ),
    );

    // SingleChildScrollView + Column (instead of ListView.builder) so
    // every commodity row is built up-front. Widget tests pin all 22
    // tradeable rows by key without scrolling; the row count is bounded
    // by the catalog size (22) so the eager build cost is negligible
    // and the deterministic ordering survives Widgetbook stories that
    // render the screen inside a non-scrollable container.
    //
    // Refs `#3093` — sectioned grouping slice. Rows are grouped by
    // commodity category (Food → Raw Materials → Manufactured) under
    // `CtSectionLabel` headers, mirroring the Production panel's
    // Available subpanel so the two surfaces read consistently. Within
    // each section, rows follow `CommodityCatalog.all` catalog order
    // (no per-section alphabetical sort); this matches the Production
    // panel's intra-section ordering.
    final List<Widget> sectionWidgets = <Widget>[
      ..._buildCommoditySectionWidgets(
        sectionKey: TradeScreen.marketSectionFoodKey,
        sectionLabel: l10n.production_food,
        commodities: sectioned.food,
        offerCap: offerCap,
        stagedOffers: stagedOffers,
        market: market,
        orders: orders,
        nameStyle: nameStyle,
        priceStyle: priceStyle,
        volumeStyle: volumeStyle,
        quantityStyle: quantityStyle,
        onDirectionChanged: sectionHandlers.onDirectionChanged,
        onQuantityDelta: sectionHandlers.onQuantityDelta,
      ),
      ..._buildCommoditySectionWidgets(
        sectionKey: TradeScreen.marketSectionRawMaterialsKey,
        sectionLabel: l10n.production_rawMaterials,
        commodities: sectioned.rawMaterials,
        offerCap: offerCap,
        stagedOffers: stagedOffers,
        market: market,
        orders: orders,
        nameStyle: nameStyle,
        priceStyle: priceStyle,
        volumeStyle: volumeStyle,
        quantityStyle: quantityStyle,
        onDirectionChanged: sectionHandlers.onDirectionChanged,
        onQuantityDelta: sectionHandlers.onQuantityDelta,
        isFirstSection: false,
      ),
      ..._buildCommoditySectionWidgets(
        sectionKey: TradeScreen.marketSectionManufacturedKey,
        sectionLabel: l10n.production_manufactured,
        commodities: sectioned.manufactured,
        offerCap: offerCap,
        stagedOffers: stagedOffers,
        market: market,
        orders: orders,
        nameStyle: nameStyle,
        priceStyle: priceStyle,
        volumeStyle: volumeStyle,
        quantityStyle: quantityStyle,
        onDirectionChanged: sectionHandlers.onDirectionChanged,
        onQuantityDelta: sectionHandlers.onQuantityDelta,
        isFirstSection: false,
      ),
    ];

    final Widget list = SingleChildScrollView(
      key: TradeScreen.marketCommodityListKey,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: sectionWidgets,
      ),
    );

    final Widget header = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          // ignore: avoid_hardcoded_strings_in_widgets
          '${TradeScreen.cargoIndicatorPrefix} $clampedRemaining',
          key: TradeScreen.marketCargoIndicatorKey,
          style: cargoIndicatorStyle,
        ),
        if (warningVisible) ...<Widget>[
          const SizedBox(height: 4),
          Text(
            TradeScreen.cargoLimitWarningText,
            key: TradeScreen.marketCargoWarningKey,
            style: cargoWarningStyle,
          ),
        ],
        const SizedBox(height: 8),
      ],
    );

    final Widget body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        header,
        // Flexible so the scrollable list still wins remaining height
        // when the body is mounted inside a constrained column (the
        // ancestor CtPanel + IndexedStack); when unconstrained it falls
        // back to the natural intrinsic height.
        Flexible(child: list),
      ],
    );

    // Observe-mode (canMutateViaUi == false): wrap the **interactive**
    // list in IgnorePointer + Opacity so the chips and stepper read as
    // read-only, but leave the cargo indicator + warning header live
    // (they're read-only telemetry that should still surface state).
    if (!canEdit) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          header,
          Flexible(
            child: Opacity(
              opacity: _observeModeOpacity,
              child: IgnorePointer(child: list),
            ),
          ),
        ],
      );
    }
    return body;
  }

  /// Visual dim factor applied to the Market tab body when the screen
  /// is in observe mode (`canMutateViaUi == false`). Matches the
  /// editorial-monocle conventions for read-only surfaces.
  static const double _observeModeOpacity = 0.7;

  /// Pure helper: build the per-commodity production-input consumption
  /// map for a desired-output snapshot. Extracted so `build` (which
  /// `watch`es the provider) and the handlers (which `read` it) share
  /// one normalisation path.
  static Map<CommodityId, int> _consumptionForDesiredOutput(
    Map<String, int> desiredOutputByRecipe,
  ) {
    if (desiredOutputByRecipe.isEmpty) {
      return const <CommodityId, int>{};
    }
    final List<AssignedRecipe> assignments =
        assignedRecipesFromDesiredOutput(desiredOutputByRecipe);
    if (assignments.isEmpty) {
      return const <CommodityId, int>{};
    }
    return productionInputConsumptionByCommodityIdForAssignments(assignments);
  }
}
