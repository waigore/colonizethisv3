// Full-screen World Market Trade screen. SPEC/ui/trade-screen.md.
//
// **Scope of the current slice (Refs #2993 E5a — Market tab read-only
// commodity table):** route + screen ID + dark editorial-monocle chrome +
// observe-mode guard + two-tab body (Market + Deal Book). The Market tab
// now renders a read-only commodity table sourced from `Game.worldMarketState`
// (last market price + previous-turn aggregate `Bids / Offers` volumes per
// commodity, sorted alphabetically by display name). The Deal Book tab
// remains a placeholder until `MarketActivity` per-player ledger work
// lands (Refs #2989, #2990, #2993 E6).
//
// The interactive Market controls (bid/offer toggle, quantity stepper,
// priority dropdown, cargo-remaining indicator) remain deferred to
// follow-up slices that depend on `currentOrdersProvider` plumbing
// (Refs #2993 E5b — Cargo) and the Deal Book live ledger (Refs #2993 E6).
// The two-tab structure is the durable wireframe those follow-up slices
// continue to build on, so the contract this file ships matches what
// `SPEC/ui/trade-screen.md` § Layout / wireframe records as the canonical
// body for the screen.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_constants.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../widgets/ct_game_feature_screen_shell.dart';
import '../../../widgets/ct_panel.dart';
import '../../../widgets/ct_tab_strip.dart';
import '../../../widgets/ct_top_bar.dart';
import '../../../widgets/strict_asset_icon.dart';
import '../shell_player_context.dart';
import '../widgets/observe_mode_not_defined_panel.dart';

/// Full-screen World Market trade screen.
///
/// Dark editorial-monocle chrome per `SPEC/ui/trade-screen.md` § Top bar: a
/// `CtTopBar` carrying the `Map` back affordance, the 18 × 18 pixel-art
/// trade icon, and the literal title `Trade`. The body is a two-tab
/// `CtTabStrip` (Market + Deal Book). The Market tab renders a
/// read-only commodity table sourced from `game.worldMarketState`
/// (Refs #2993 E5a); the Deal Book tab keeps the placeholder copy until
/// the per-player ledger work for Refs #2993 E6 lands.
class TradeScreen extends ConsumerWidget {
  const TradeScreen({super.key, required this.game, required this.player});

  /// SPEC/ui/trade-screen.md — [UiScreenIds.tradeScreen].
  static const screenId = UiScreenIds.tradeScreen;

  /// Localized back-button label rendered immediately after the chevron on
  /// the dark-theme `CtTopBar`. SPEC requires the literal `"Map"` so the
  /// affordance reads `"← Map"`.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String topBarBackLabel = 'Map';

  /// Title text shown in the dark-theme `CtTopBar`. SPEC mandates the
  /// literal `"Trade"` (Cinzel display font is configured at the theme
  /// level).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String topBarTitle = 'Trade';

  /// Pixel-art icon asset rendered between the back affordance and the
  /// title (SPEC § Top bar — 18 × 18 px trade icon).
  static const String topBarIconAsset =
      '${kAppIconAssetPrefix}ui_icon_trade.png';

  /// Stable widget key for the trade top bar — lets widget tests pin the
  /// dark-theme chrome without coupling to localized strings.
  static const Key topBarKey = ValueKey<String>('tradeScreenTopBar');

  /// Stable widget key for the two-tab body root (Market + Deal Book).
  /// Replaces the prior `placeholderBodyKey` from the E1+E2+E3 scaffold —
  /// the tab strip is the durable structure the follow-up Market /
  /// Deal-Book slices build on, so this key remains stable when the
  /// per-tab bodies are wired to live `WorldMarketState` data in #2993
  /// E5+E6.
  static const Key tabsBodyKey = ValueKey<String>('tradeScreenTabsBody');

  /// Stable widget key for the Market tab body. Pin point for widget
  /// tests asserting the Market tab body is present in the tab strip's
  /// `IndexedStack` (visible when the Market tab is selected, which is
  /// the default). The same key spans the placeholder, the read-only
  /// commodity table introduced by Refs #2993 E5a, and the live
  /// interactive controls planned for follow-up E5 slices.
  static const Key marketTabBodyKey =
      ValueKey<String>('tradeScreenMarketTabBody');

  /// Stable widget key for the scrollable commodity list inside the
  /// Market tab body (Refs #2993 E5a). Lets widget tests reach the
  /// `ListView` that hosts the per-commodity rows without coupling to
  /// the row identities themselves.
  static const Key marketCommodityListKey =
      ValueKey<String>('tradeScreenMarketCommodityList');

  /// Per-row key for a Market tab commodity row. Deterministic so widget
  /// tests can pin a specific commodity (e.g. `timber`) without relying
  /// on text matching.
  static Key marketCommodityRowKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId');

  /// Stable widget key for the Deal Book tab placeholder body. Pin point
  /// for widget tests asserting the Deal Book tab body is present in the
  /// tab strip's `IndexedStack` (visible when the Deal Book tab is
  /// selected after the user taps the Deal Book label).
  static const Key dealBookTabBodyKey =
      ValueKey<String>('tradeScreenDealBookTabBody');

  /// Tab label for the Market tab (default selection). SPEC §
  /// Layout / wireframe pins the literal `"Market"` so widget tests can
  /// drive the tab via `find.text` without coupling to localization
  /// before the trade screen joins the l10n catalog.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String marketTabLabel = 'Market';

  /// Tab label for the Deal Book tab (previous-turn ledger). SPEC §
  /// Layout / wireframe pins the literal `"Deal Book"`.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookTabLabel = 'Deal Book';

  final Game game;
  final Player player;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CtGameFeatureScreenShell(
      game: game,
      topBar: const CtTopBar(
        key: topBarKey,
        title: topBarTitle,
        backButtonLabel: topBarBackLabel,
        icon: StrictAssetIcon(
          assetPath: topBarIconAsset,
          width: 18,
          height: 18,
        ),
      ),
      bodyBuilder: (context, shellRef, displayGame) {
        if (shellPanelsNotDefined(shellRef)) {
          // ignore: avoid_hardcoded_strings_in_widgets
          return const ObserveModeNotDefinedPanel(title: 'Trade');
        }
        return _TradeScreenTabsBody(
          key: tabsBodyKey,
          game: displayGame,
        );
      },
    );
  }
}

/// Two-tab body for the trade screen: Market (default) + Deal Book.
///
/// Hosts a [CtTabStrip] inside a [CtPanel] so the dark editorial-monocle
/// surface mirrors the chrome already established for sibling
/// full-screen feature surfaces (production, diplomacy). The Market tab
/// renders a read-only commodity table sourced from
/// [Game.worldMarketState] (Refs #2993 E5a); the Deal Book tab keeps the
/// placeholder copy until the per-player ledger work for Refs #2993 E6
/// lands. The two-tab structure stays as the durable wireframe so the
/// follow-up interactive Market controls (toggle, stepper, priority
/// dropdown, cargo indicator) can swap each tab body in place without
/// remounting the strip.
class _TradeScreenTabsBody extends StatelessWidget {
  const _TradeScreenTabsBody({super.key, required this.game});

  final Game game;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: CtPanel(
        padding: const EdgeInsets.all(16),
        child: CtTabStrip(
          tabLabels: const <String>[
            TradeScreen.marketTabLabel,
            TradeScreen.dealBookTabLabel,
          ],
          tabViews: <Widget>[
            _MarketTabContent(
              key: TradeScreen.marketTabBodyKey,
              game: game,
            ),
            const _DealBookTabPlaceholder(
              key: TradeScreen.dealBookTabBodyKey,
            ),
          ],
        ),
      ),
    );
  }
}

/// Read-only commodity table for the Market tab (Refs #2993 E5a).
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
///   [WorldMarketState.lastTurnActivity] (`bodySmall`, `--muted`).
///
/// Rows are sorted by display name (case-insensitive) so the order is
/// deterministic for widget tests and Widgetbook stories. The list is
/// scrollable (the future bid/offer controls in Refs #2993 E5b extend
/// each row in place; the cargo indicator header from Refs #2993 E5c
/// lands above the list when its plumbing arrives — Refs #2988 §UI
/// Design).
class _MarketTabContent extends StatelessWidget {
  const _MarketTabContent({super.key, required this.game});

  final Game game;

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

  @override
  Widget build(BuildContext context) {
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

    final List<Commodity> rows = _tradeableCommoditiesSortedByDisplayName();
    final WorldMarketState market = game.worldMarketState;

    // SingleChildScrollView + Column (instead of ListView.builder) so
    // every commodity row is built up-front. Widget tests pin all 22
    // tradeable rows by key without scrolling; the row count is bounded
    // by the catalog size (22) so the eager build cost is negligible
    // and the deterministic ordering survives Widgetbook stories that
    // render the screen inside a non-scrollable container.
    return SingleChildScrollView(
      key: TradeScreen.marketCommodityListKey,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (int index = 0; index < rows.length; index++)
            Padding(
              key: TradeScreen.marketCommodityRowKey(rows[index].id),
              padding: EdgeInsets.only(top: index == 0 ? 0 : 12),
              child: _MarketCommodityRow(
                commodityDisplayName:
                    rows[index].displayName ?? rows[index].id,
                priceText: _formatPrice(market.prices[rows[index].id]),
                volumeText: _volumeText(
                  market.lastTurnActivity[rows[index].id] ??
                      MarketActivity.empty,
                ),
                nameStyle: nameStyle,
                priceStyle: priceStyle,
                volumeStyle: volumeStyle,
              ),
            ),
        ],
      ),
    );
  }

  static String _volumeText(MarketActivity activity) {
    return '$bidsLabel ${activity.totalBidQuantity} / '
        '$offersLabel ${activity.totalOfferQuantity}';
  }

  /// Returns the tradeable commodities (catalog minus riches + spices)
  /// sorted alphabetically by display name (case-insensitive). Spices
  /// are excluded explicitly per Refs #2988 §UI Design — the Market tab
  /// shows 22 tradeable rows (full catalog minus riches and spices).
  static List<Commodity> _tradeableCommoditiesSortedByDisplayName() {
    final List<Commodity> filtered = <Commodity>[
      for (final Commodity c in CommodityCatalog.all)
        if (c.category != CommodityCategory.riches && c.id != 'spices') c,
    ];
    filtered.sort((Commodity a, Commodity b) {
      final String an = (a.displayName ?? a.id).toLowerCase();
      final String bn = (b.displayName ?? b.id).toLowerCase();
      return an.compareTo(bn);
    });
    return filtered;
  }

  static String _formatPrice(double? price) {
    if (price == null) return priceUnknownGlyph;
    return price.toStringAsFixed(1);
  }
}

/// One row of the Market tab read-only commodity table. Lays the
/// content on a two-line column so the row remains overflow-safe at
/// the 320 dp minimum viewport (SPEC/ui/mobile-adaptation.md §7).
class _MarketCommodityRow extends StatelessWidget {
  const _MarketCommodityRow({
    required this.commodityDisplayName,
    required this.priceText,
    required this.volumeText,
    required this.nameStyle,
    required this.priceStyle,
    required this.volumeStyle,
  });

  final String commodityDisplayName;
  final String priceText;
  final String volumeText;
  final TextStyle nameStyle;
  final TextStyle priceStyle;
  final TextStyle volumeStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Expanded(
              child: Text(
                commodityDisplayName,
                style: nameStyle,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(priceText, style: priceStyle),
          ],
        ),
        const SizedBox(height: 2),
        Text(volumeText, style: volumeStyle),
      ],
    );
  }
}

/// Placeholder body for the Deal Book tab (`#2993` E6 unlocks the live
/// previous-turn ledger once a per-player ledger surface ships on top
/// of #2989 / #2990's `MarketActivity` + world-market turn phase).
class _DealBookTabPlaceholder extends StatelessWidget {
  const _DealBookTabPlaceholder({super.key});

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String _titleText = 'Deal Book';

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String _bodyText =
      'Previous-turn filled, partial, and unfilled bids and offers — '
      'with treasury totals — render here once the world-market turn '
      'phase ships (Refs #2989, #2990, #2993 E6).';

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle titleStyle =
        (theme.textTheme.titleMedium ?? const TextStyle(fontSize: 16))
            .copyWith(color: EditorialMonoclePalette.accent);
    final TextStyle bodyStyle =
        (theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14))
            .copyWith(color: EditorialMonoclePalette.muted);
    return Align(
      alignment: Alignment.topLeft,
      child: CtPanel(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(_titleText, style: titleStyle),
            const SizedBox(height: 8),
            Text(_bodyText, style: bodyStyle),
          ],
        ),
      ),
    );
  }
}
