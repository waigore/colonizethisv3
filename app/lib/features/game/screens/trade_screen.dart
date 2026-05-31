// Full-screen World Market Trade screen. SPEC/ui/trade-screen.md.
//
// **Scope of this slice (Refs #2993 E4 — tab scaffold):** route + screen ID
// + dark editorial-monocle chrome + observe-mode guard + two-tab body
// (Market + Deal Book) with placeholder copy inside each tab.
//
// The interactive Market tab (commodity rows, bid/offer toggle, quantity
// stepper, priority dropdown, cargo-remaining indicator) and Deal Book
// ledger tab content remain deferred to follow-up slices that depend on
// the `WorldMarketState` / `TradeOrder` types from #2989. The tab strip
// and per-tab placeholder bodies are the durable UI structure those
// follow-up slices replace, so the scaffold contract this file ships
// matches what `SPEC/ui/trade-screen.md` § Layout / wireframe records as
// the canonical body for the screen until then.

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
/// `CtTabStrip` (Market + Deal Book) with placeholder copy inside each
/// tab; once #2989's `WorldMarketState` / `TradeOrder` data types land
/// the placeholders are replaced with the live Market commodity list and
/// Deal Book ledger described in `SPEC/ui/trade-screen.md` § Layout /
/// wireframe.
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

  /// Stable widget key for the Market tab placeholder body. Pin point for
  /// widget tests asserting the Market tab body is present in the tab
  /// strip's `IndexedStack` (visible when the Market tab is selected,
  /// which is the default).
  static const Key marketTabBodyKey =
      ValueKey<String>('tradeScreenMarketTabBody');

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
        return const _TradeScreenTabsBody(key: tabsBodyKey);
      },
    );
  }
}

/// Two-tab body for the trade screen: Market (default) + Deal Book.
///
/// Hosts a [CtTabStrip] inside a [CtPanel] so the dark editorial-monocle
/// surface mirrors the chrome already established for sibling
/// full-screen feature surfaces (production, diplomacy). Each tab body is
/// a placeholder [CtPanel] that names the parent issue and the follow-up
/// slice unlocking the live content; the placeholders match the contract
/// recorded in `SPEC/ui/trade-screen.md` § Layout / wireframe and are
/// the durable structure the live Market commodity list (#2993 E5) and
/// Deal Book ledger (#2993 E6) replace once #2989's `WorldMarketState`
/// data types land.
class _TradeScreenTabsBody extends StatelessWidget {
  const _TradeScreenTabsBody({super.key});

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
          tabViews: const <Widget>[
            _MarketTabPlaceholder(key: TradeScreen.marketTabBodyKey),
            _DealBookTabPlaceholder(key: TradeScreen.dealBookTabBodyKey),
          ],
        ),
      ),
    );
  }
}

/// Placeholder body for the Market tab (`#2993` E5 unlocks the live
/// commodity list once #2989 ships `WorldMarketState` / `TradeOrder`).
class _MarketTabPlaceholder extends StatelessWidget {
  const _MarketTabPlaceholder({super.key});

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String _titleText = 'Market';

  // ignore: avoid_hardcoded_strings_in_widgets
  static const String _bodyText =
      'Bid and offer controls, the per-commodity price + previous-turn '
      'volume rows, the priority dropdown, and the cross-commodity '
      'cargo-remaining indicator land alongside the World Market core '
      'data types (Refs #2989, #2993 E5).';

  @override
  Widget build(BuildContext context) {
    return _TabPlaceholderPanel(title: _titleText, body: _bodyText);
  }
}

/// Placeholder body for the Deal Book tab (`#2993` E6 unlocks the live
/// previous-turn ledger once #2989 / #2990 ship `MarketActivity` and
/// the world-market turn phase).
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
    return _TabPlaceholderPanel(title: _titleText, body: _bodyText);
  }
}

/// Shared placeholder body for both tabs: a single dark-token
/// [CtPanel] carrying the tab title and a muted explanatory body. Keeps
/// each tab's placeholder visually identical so reviewers can confirm
/// tab-switch behaviour without the chrome biasing the read.
class _TabPlaceholderPanel extends StatelessWidget {
  const _TabPlaceholderPanel({required this.title, required this.body});

  final String title;
  final String body;

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
            Text(title, style: titleStyle),
            const SizedBox(height: 8),
            Text(body, style: bodyStyle),
          ],
        ),
      ),
    );
  }
}
