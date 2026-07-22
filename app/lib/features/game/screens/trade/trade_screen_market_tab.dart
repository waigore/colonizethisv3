// Market tab body for the World Market Trade screen
// (Refs #2993, #3093, #3487, #3546, split out from `trade_screen.dart` to
// keep the host file under the repo code-review physical-line limit and the
// issue #3594 ≤700-line target — see
// `SPEC/program/dart-file-non-comment-line-size.md` and the
// `.cursor/rules/colonizethis-code-review.mdc` >1000-physical-line rule).
//
// Order handlers, catalog helpers, and the `build` implementation live in
// `trade_screen_market_tab_order_handlers.dart`,
// `trade_screen_market_tab_catalog.dart`, and
// `trade_screen_market_tab_build.dart` (Refs #3878).
//
// All classes here are library-private (`MarketTabContent`,
// `SectionedTradeableCommodities`) and consumed only by
// `TradeScreenTabsBody` inside the parent library, so they keep using
// `TradeScreen` static constants and the sibling `MarketCommodityRow`
// part fragment without further plumbing.

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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../../../providers/games_provider.dart';
import '../../../../providers/production_allocation_provider.dart';
import '../../../../providers/treasury_summary_provider.dart';
import 'trade_screen_market_tab_build.dart';

class MarketTabContent extends ConsumerWidget {
  const MarketTabContent({
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
    final Orders orders = ref.watch(currentOrdersProvider);
    final CurrentOrdersNotifier ordersNotifier =
        ref.read(currentOrdersProvider.notifier);
    final Map<String, int> desiredOutputByRecipe =
        ref.watch(productionDesiredOutputProvider);
    int? readProjectedTreasuryDelta() {
      try {
        return ref.read(treasurySummaryProvider).projectedDelta;
      } on Object {
        return null;
      }
    }

    return buildMarketTabBody(
      context,
      orders: orders,
      ordersNotifier: ordersNotifier,
      desiredOutputByRecipe: desiredOutputByRecipe,
      readProjectedTreasuryDelta: readProjectedTreasuryDelta,
    );
  }
}
