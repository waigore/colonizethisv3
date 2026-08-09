// Market-tab `build` implementation for `MarketTabContent`.
// Split from `trade_screen_market_tab.dart` to keep each trade-screen part
// under the repo file-size target (Refs #3878).


import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:flutter/material.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';

import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../../providers/games_provider.dart';
import '../../../../widgets/ct_nine_patch_button.dart';

import 'trade_market_staging_context.dart';
import 'trade_screen_contract_market.dart';
import 'trade_screen_market_tab.dart';
import 'trade_screen_market_tab_build_sections.dart';
import 'trade_screen_market_tab_cargo_header.dart';
import 'trade_screen_market_tab_catalog.dart';
import 'trade_screen_market_tab_order_handlers.dart';
import 'trade_section_handlers.dart';

extension MarketTabContentBuild on MarketTabContent {
  /// Visual dim factor applied to the Market tab body when the screen
  /// is in observe mode (`canMutateViaUi == false`). Matches the
  /// editorial-monocle conventions for read-only surfaces.
  static const double observeModeOpacity = 0.7;

  Widget buildMarketTabBody(
    BuildContext context, {
    required Orders orders,
    required CurrentOrdersNotifier ordersNotifier,
    required Map<String, int> desiredOutputByRecipe,
    required int? Function() readProjectedTreasuryDelta,
    required Map<CommodityId, TradeCounselRecommendation>
        tradeCounselHighlightsByCommodityId,
    TradeOpenCounselCallback? onOpenTradeCounsel,
  }) {
    final ThemeData theme = Theme.of(context);
    final styles = marketTabTextStyles(theme);
    final TextStyle nameStyle = styles.nameStyle;
    final TextStyle priceStyle = styles.priceStyle;
    final TextStyle volumeStyle = styles.volumeStyle;
    final TextStyle quantityStyle = styles.quantityStyle;
    final TextStyle cargoIndicatorStyle = styles.cargoIndicatorStyle;
    final TextStyle cargoWarningStyle = styles.cargoWarningStyle;
    final TextStyle bidGoodsIndicatorStyle = styles.bidGoodsIndicatorStyle;
    final TextStyle bidTypeWarningStyle = styles.bidTypeWarningStyle;
    final TextStyle bidBudgetIndicatorStyle = styles.bidBudgetIndicatorStyle;
    final TextStyle bidBudgetWarningStyle = styles.bidBudgetWarningStyle;
    final SectionedTradeableCommodities sectioned =
        tradeableCommoditiesByCategory();
    final AppLocalizations l10n = appL10n(context);

    final Map<CommodityId, int> productionInputConsumption =
        _consumptionForDesiredOutput(desiredOutputByRecipe);

    final TradeSectionHandlers sectionHandlers = buildTradeSectionHandlers(
      readProjectedTreasuryDelta: readProjectedTreasuryDelta,
      handleDirectionChanged: ({
        required CommodityId commodityId,
        required TradeOrderType? next,
        required int? projectedTreasuryDelta,
      }) =>
          handleDirectionChanged(
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
          handleQuantityDelta(
            ordersNotifier: ordersNotifier,
            orders: orders,
            productionInputConsumption: productionInputConsumption,
            projectedTreasuryDelta: projectedTreasuryDelta,
            commodityId: commodityId,
            delta: delta,
          ),
    );
    final TradeMarketStagingContext staging = TradeMarketStagingContext.forMarketBuild(
      game: game,
      playerId: playerId,
      orders: orders,
      productionInputConsumption: productionInputConsumption,
      handlers: sectionHandlers,
      tradeCounselHighlightsByCommodityId: tradeCounselHighlightsByCommodityId,
      onOpenTradeCounsel: onOpenTradeCounsel,
    );

    final int tradeCargoCapacity = cargoHoldsForHomeFleet(game, playerId);
    final int totalStagedBid = totalStagedBidQuantity(orders, playerId);
    final int stagedDistinctBidCount =
        stagedDistinctBidCommodityCount(orders, playerId);
    final int bidTypeCap = staging.bidTypeCap;
    final int remainingCargo = tradeCargoCapacity - totalStagedBid;
    final int clampedRemaining = remainingCargo < 0 ? 0 : remainingCargo;
    final bool warningVisible =
        clampedRemaining == 0 && totalStagedBid > 0;

    final ({
      int budgetTotal,
      int budgetRemaining,
      bool warningVisible,
    }) bidBudgetHeader = marketTabBidBudgetHeaderState(
      game: game,
      playerId: playerId,
      orders: orders,
      projectedTreasuryDelta: readProjectedTreasuryDelta(),
      resourceRules: ResourceRules.defaultRules,
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
    //
    // Refs #4227 — wide layouts (≥ marketTwoColumnMinWidth) render a
    // row-major two-column grid per section with compact two-line rows.
    final Widget list = LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wideLayout = constraints.maxWidth >=
            TradeScreenMarketKeys.marketTwoColumnMinWidth;
        final List<Widget> sectionWidgets = buildMarketTabSectionWidgets(
          l10n: l10n,
          sectioned: sectioned,
          staging: staging,
          nameStyle: nameStyle,
          priceStyle: priceStyle,
          volumeStyle: volumeStyle,
          quantityStyle: quantityStyle,
          wideLayout: wideLayout,
        );
        return SingleChildScrollView(
          key: TradeScreenMarketKeys.marketCommodityListKey,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: sectionWidgets,
          ),
        );
      },
    );

    final Widget header = RepaintBoundary(
      key: TradeScreenMarketKeys.marketBidTypeCapGoldenKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (onOpenTradeCounsel != null)
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: CtNinePatchButton(
                  key: const ValueKey<String>('trade_market_counsel_button'),
                  onPressed: () => onOpenTradeCounsel(),
                  child: Text(l10n.tradeMarket_counsel),
                ),
              ),
            ),
          MarketTabHeaderStrip(
            stagedDistinctBidCount: stagedDistinctBidCount,
            bidTypeCap: bidTypeCap,
            clampedRemaining: clampedRemaining,
            cargoWarningVisible: warningVisible,
            bidBudgetTotal: bidBudgetHeader.budgetTotal,
            bidBudgetRemaining: bidBudgetHeader.budgetRemaining,
            bidBudgetWarningVisible: bidBudgetHeader.warningVisible,
            bidGoodsIndicatorStyle: bidGoodsIndicatorStyle,
            bidTypeWarningStyle: bidTypeWarningStyle,
            cargoIndicatorStyle: cargoIndicatorStyle,
            cargoWarningStyle: cargoWarningStyle,
            bidBudgetIndicatorStyle: bidBudgetIndicatorStyle,
            bidBudgetWarningStyle: bidBudgetWarningStyle,
          ),
        ],
      ),
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
    // read-only, but leave the bid-goods + cargo header live (they're
    // read-only telemetry that should still surface state).
    if (!canEdit) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          header,
          Flexible(
            child: Opacity(
              opacity: observeModeOpacity,
              child: IgnorePointer(child: list),
            ),
          ),
        ],
      );
    }
    return body;
  }

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
