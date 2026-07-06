// Market tab body for the World Market Trade screen
// (Refs #2993, #3093, #3487, #3546, split out from `trade_screen.dart` to
// keep the host file under the repo code-review physical-line limit and the
// issue #3594 ≤700-line target — see
// `SPEC/program/dart-file-non-comment-line-size.md` and the
// `.cursor/rules/colonizethis-code-review.mdc` >1000-physical-line rule).
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

  /// Projected treasury change this turn from the player's **non-bid**
  /// staged orders (build / recruit / civilian / subsidy commitments).
  ///
  /// Reads [summary.projectedDelta], which is the signed treasury delta
  /// from `projectOrderEffects` over the **current** `Orders` (which
  /// already includes the player's staged bids). Adding the player's
  /// running bid spend back nets the bid contribution out of the
  /// projection so the helper passes a non-bid-only delta into
  /// `treasuryAvailableForBidsByPlayer` per
  /// `SPEC/ui/trade-screen.md` § Market tab — treasury bid cap.
  ///
  /// Returns `0` when [summary.projectedDelta] is `null` — typical for
  /// Widgetbook stories and isolated widget tests that run without
  /// `gameServiceProvider` map data.
  int _projectedNonBidTreasuryDelta(
    int? projectedDelta,
    int stagedBidSpend,
  ) {
    if (projectedDelta == null) return 0;
    return projectedDelta + stagedBidSpend;
  }

  void _handleDirectionChanged({
    required CurrentOrdersNotifier ordersNotifier,
    required Orders orders,
    required Map<CommodityId, int> productionInputConsumption,
    required int? projectedTreasuryDelta,
    required CommodityId commodityId,
    required TradeOrderType? next,
  }) {
    if (next == null) {
      final Orders updated = removeTradeOrderForPlayer(
        orders: orders,
        playerId: playerId,
        commodityId: commodityId,
      );
      if (!identical(updated, orders)) ordersNotifier.replaceAll(updated);
      return;
    }
    final TradeOrder? prior = tradeOrderForPlayerCommodity(
      orders,
      playerId,
      commodityId,
    );
    final int desiredQuantity =
        prior?.quantity ?? TradeScreen.marketRowQuantityDefault;
    final int priority =
        prior?.priority ?? TradeScreen.marketRowDefaultPriority;

    int quantity = desiredQuantity;
    if (next == TradeOrderType.bid) {
      // Refs #2993 E5c: clamp the staged bid quantity so the
      // cross-commodity bid total never exceeds the player's
      // tradeCargoCapacity. The row's own prior bid contribution (if
      // any) is added back because it is already included in the
      // running total and will be replaced by `applyTradeOrderForPlayer`.
      final int tradeCargoCapacity =
          cargoHoldsForHomeFleet(game, playerId);
      final int totalStagedBid = _totalStagedBidQuantity(orders, playerId);
      final int priorBidContribution =
          prior?.type == TradeOrderType.bid ? prior!.quantity : 0;
      final int maxAllowedBidQuantity =
          (tradeCargoCapacity - totalStagedBid) + priorBidContribution;
      if (maxAllowedBidQuantity <= 0) {
        // Cargo budget exhausted — refuse the toggle so the row stays
        // in its prior direction (or remains `None`). The warning row
        // is already mounted (or will mount as soon as a bid lands).
        return;
      }
      if (desiredQuantity > maxAllowedBidQuantity) {
        quantity = maxAllowedBidQuantity;
      }
      // Refs #3093 — treasury bid budget cap. The cross-commodity bid
      // total spend (`Σ qty × effectiveMarketPrice`) must not exceed
      // the player's `treasuryAvailableForBidsByPlayer` (today: raw
      // treasury; pending-cost subtraction is a documented follow-up
      // per `SPEC/game/world-market.md` § Treasury budget for bids).
      // Subtract the row's own prior bid contribution to the running
      // spend total so this row's *replacement* quantity is measured
      // against the fresh headroom.
      //
      // When `rowPrice` is null (manufactured commodities whose first
      // market price is discovered in-game and the catalog has no
      // default — the row's price text reads as the em-dash) the
      // treasury clamp is **skipped** so the cargo cap remains the
      // only constraint. The validator-side enforcement (follow-up)
      // covers the spend-over-treasury case independently.
      final int? rowPrice = effectiveMarketPriceForCommodityId(
        commodityId: commodityId,
        worldMarket: game.worldMarketState,
        resourceRules: ResourceRules.defaultRules,
      );
      if (rowPrice != null && rowPrice > 0) {
        final int totalStagedBidSpend = stagedBidTotalSpendByPlayer(
          orders: orders,
          playerId: playerId,
          game: game,
          resourceRules: ResourceRules.defaultRules,
        );
        final int treasuryBudget = treasuryAvailableForBidsByPlayer(
          game: game,
          playerId: playerId,
          projectedNonBidTreasuryDelta: _projectedNonBidTreasuryDelta(
            projectedTreasuryDelta,
            totalStagedBidSpend,
          ),
        );
        final int priorRowBidSpend = prior?.type == TradeOrderType.bid
            ? prior!.quantity * rowPrice
            : 0;
        final int otherBidSpend = totalStagedBidSpend - priorRowBidSpend;
        final int treasuryHeadroom = treasuryBudget - otherBidSpend;
        if (treasuryHeadroom < rowPrice) {
          // Not enough treasury to bid even 1 unit at the row's price
          // → silent no-op so the row stays in its prior direction.
          return;
        }
        final int treasuryQuantityCap = treasuryHeadroom ~/ rowPrice;
        if (quantity > treasuryQuantityCap) {
          quantity = treasuryQuantityCap;
        }
        if (quantity <= 0) return;
      }
    } else if (next == TradeOrderType.offer) {
      // Refs #3093 — sellable clamp slice. The per-commodity offer cap
      // is `max(0, stockpile − industryAllocation)`. Industry
      // allocation is the per-commodity input consumption projected
      // from the player's current production allocations via
      // `productionInputConsumptionByCommodityIdForAssignments`
      // (`SPEC/program/order-projections.md` § Production input
      // consumption projection). Mutual exclusion guarantees the row
      // is the only staged offer for the commodity, so the cap is
      // applied directly to the row's quantity without subtracting
      // sibling offers.
      final int rowCap = offerCapByCommodityId(
        game: game,
        playerId: playerId,
        productionInputConsumptionByCommodityId: productionInputConsumption,
      )[commodityId] ??
          0;
      if (rowCap <= 0) {
        // Stockpile exhausted — refuse the toggle so the row stays in
        // its prior direction (or remains `None`).
        return;
      }
      if (desiredQuantity > rowCap) {
        quantity = rowCap;
      }
    }
    final TradeOrder nextOrder = TradeOrder(
      commodityId: commodityId,
      type: next,
      quantity: quantity,
      priority: priority,
    );
    final Orders updated = applyTradeOrderForPlayer(
      orders: orders,
      playerId: playerId,
      order: nextOrder,
    );
    ordersNotifier.replaceAll(updated);
  }

  void _handleQuantityDelta({
    required CurrentOrdersNotifier ordersNotifier,
    required Orders orders,
    required Map<CommodityId, int> productionInputConsumption,
    required int? projectedTreasuryDelta,
    required CommodityId commodityId,
    required int delta,
  }) {
    final TradeOrder? prior = tradeOrderForPlayerCommodity(
      orders,
      playerId,
      commodityId,
    );
    if (prior == null) return; // No staged direction → ignore.
    final int rawNext = prior.quantity + delta;
    if (rawNext < TradeScreen.marketRowQuantityMin) return;
    if (rawNext == prior.quantity) return;
    if (prior.type == TradeOrderType.bid && delta > 0) {
      // Refs #2993 E5c: increment is blocked when the cross-commodity
      // bid budget is exhausted. The row's own current quantity is
      // already part of `totalStagedBid` — we only need any unused
      // headroom to grow it by `delta`.
      final int tradeCargoCapacity =
          cargoHoldsForHomeFleet(game, playerId);
      final int totalStagedBid = _totalStagedBidQuantity(orders, playerId);
      if (totalStagedBid + delta > tradeCargoCapacity) return;
      // Refs #3093 — treasury bid budget cap. Block the `+` tap when
      // the cross-commodity bid total spend would exceed the player's
      // available treasury. The row's own current spend is already
      // part of `totalStagedBidSpend` — we only need the extra `delta`
      // at the row's effective per-unit price to fit inside the
      // remaining treasury budget.
      //
      // When `rowPrice` is null (manufactured commodities with no
      // catalog default — the row's price reads as the em-dash) the
      // treasury check is **skipped** so the cargo cap remains the
      // only constraint; the validator-side enforcement (follow-up)
      // catches over-spend cases independently.
      final int? rowPrice = effectiveMarketPriceForCommodityId(
        commodityId: commodityId,
        worldMarket: game.worldMarketState,
        resourceRules: ResourceRules.defaultRules,
      );
      if (rowPrice != null && rowPrice > 0) {
        final int totalStagedBidSpend = stagedBidTotalSpendByPlayer(
          orders: orders,
          playerId: playerId,
          game: game,
          resourceRules: ResourceRules.defaultRules,
        );
        final int treasuryBudget = treasuryAvailableForBidsByPlayer(
          game: game,
          playerId: playerId,
          projectedNonBidTreasuryDelta: _projectedNonBidTreasuryDelta(
            projectedTreasuryDelta,
            totalStagedBidSpend,
          ),
        );
        if (totalStagedBidSpend + delta * rowPrice > treasuryBudget) return;
      }
    } else if (prior.type == TradeOrderType.offer && delta > 0) {
      // Refs #3093 — sellable clamp slice. Block the `+` tap when the
      // per-commodity offer cap (`max(0, stockpile −
      // industryAllocation)`) is exhausted. Industry allocation comes
      // from the player's current production assignments via
      // `productionInputConsumptionByCommodityIdForAssignments`.
      // Mutual exclusion guarantees the row is the only staged offer
      // for the commodity, so the cap is applied directly to
      // `prior.quantity + delta`.
      final int rowCap = offerCapByCommodityId(
        game: game,
        playerId: playerId,
        productionInputConsumptionByCommodityId: productionInputConsumption,
      )[commodityId] ??
          0;
      if (prior.quantity + delta > rowCap) return;
    }
    final TradeOrder nextOrder = prior.copyWith(quantity: rawNext);
    final Orders updated = applyTradeOrderForPlayer(
      orders: orders,
      playerId: playerId,
      order: nextOrder,
    );
    ordersNotifier.replaceAll(updated);
  }

  /// Returns the per-row sellable headroom shown as `(N)` next to the
  /// commodity name on the Trade Market tab (Refs #3093 — sellable
  /// clamp slice). Equals `max(0, offerCap[c] − stagedOffer[c])` for
  /// the row's commodity. Mirrors
  /// `sellableHeadroomByCommodityId` but with per-row resolution so
  /// the build path passes one int per row instead of rebuilding the
  /// full map per child.
  static int _sellableHeadroomFor({
    required Map<CommodityId, int> offerCap,
    required Map<CommodityId, int> stagedOffers,
    required CommodityId commodityId,
  }) {
    final int cap = offerCap[commodityId] ?? 0;
    final int staged = stagedOffers[commodityId] ?? 0;
    final int headroom = cap - staged;
    return headroom < 0 ? 0 : headroom;
  }

  /// Returns the sum of `TradeOrder.quantity` across all staged
  /// `TradeOrderType.bid` orders for [playerId] in [orders]. Offers do
  /// not consume cargo (per `#2988` § Cargo Constraint Model) and are
  /// excluded from the sum.
  static int _totalStagedBidQuantity(Orders orders, String playerId) {
    final List<TradeOrder>? list = orders.tradeOrdersByPlayerId[playerId];
    if (list == null || list.isEmpty) return 0;
    int total = 0;
    for (final TradeOrder o in list) {
      if (o.type == TradeOrderType.bid) total += o.quantity;
    }
    return total;
  }

  static String _volumeText(MarketActivity activity) {
    return '$bidsLabel ${activity.totalBidQuantity} / '
        '$offersLabel ${activity.totalOfferQuantity}';
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
  static _SectionedTradeableCommodities _tradeableCommoditiesByCategory() {
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
    bool isFirstSection = true,
  }) {
    if (commodities.isEmpty) return const <Widget>[];
    return <Widget>[
      if (!isFirstSection) const SizedBox(height: 12),
      CtSectionLabel(sectionLabel, key: sectionKey),
      const SizedBox(height: 6),
      for (int index = 0; index < commodities.length; index++)
        Padding(
          key: TradeScreen.marketCommodityRowKey(commodities[index].id),
          padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
          child: _MarketCommodityRow(
            commodityId: commodities[index].id,
            commodityDisplayName:
                commodities[index].displayName ?? commodities[index].id,
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
  static String _formatPrice(int? price, {required CommodityId commodityId}) {
    final ResourceRules rules =
        TradeScreen.marketPriceResourceRulesOverride ??
        ResourceRules.defaultRules;
    final int? effective =
        price ?? rules.defaultMarketPriceForCommodityId(commodityId);
    if (effective == null) return priceUnknownGlyph;
    return effective.toString();
  }
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
