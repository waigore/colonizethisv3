// Full-screen World Market Trade screen. SPEC/ui/trade-screen.md.
//
// **Scope (Refs #2993 E5a + E5b + E5c + E6):**
// - E5a (already shipped) — route + screen ID + dark editorial-monocle
//   chrome + observe-mode guard + two-tab body (Market + Deal Book) +
//   read-only commodity table (last market price + previous-turn
//   aggregate `Bids / Offers` volumes per commodity, sorted alphabetically
//   by display name).
// - E5b (already shipped) — interactive bid/offer/none direction selector
//   and quantity stepper per row, wired to `currentOrdersProvider` so
//   each change updates `Orders.tradeOrdersByPlayerId[player.id]` via the
//   pure helpers `applyTradeOrderForPlayer` / `removeTradeOrderForPlayer`
//   in `colonizethis_logic`. Mutual exclusion is structural: at most
//   one staged `TradeOrder` per (player, commodityId) pair, so toggling
//   from `Bid` to `Offer` (or vice versa) replaces the prior direction
//   in place.
// - E5c (already shipped) — cross-commodity cargo-remaining indicator +
//   cap + warning. A persistent header strip above the commodity list
//   renders `Cargo remaining: X` where
//   `X = max(0, tradeCargoCapacity − totalBid)`. `tradeCargoCapacity` is
//   `cargoHoldsForHomeFleet(game, player.id)` (falling back to
//   `defaultCargoHoldsStub = 24` when the player has no home fleet).
//   `totalBid` is the sum of staged `TradeOrderType.bid` quantities for
//   the player; offers don't consume cargo (per #2988 §Cargo Constraint
//   Model). When the cap is reached (`remainingCargo == 0 AND
//   totalBid > 0`), a warning row is mounted below the indicator. Bid
//   increments and `Bid` toggles are clamped so the cross-commodity bid
//   total never exceeds `tradeCargoCapacity`.
// - E6 (this slice) — Deal Book live two-panel ledger. The Deal Book tab
//   body now renders the player's own previous-turn `FilledDeal`s and
//   carry-forward orders, sourced from
//   `Game.worldMarketState.lastTurnActivity[*].deals` (filtered by
//   `buyerFactionId` / `sellerFactionId`) and
//   `WorldMarketState.carryForward{Bids,Offers}ByFactionId[playerId]`.
//   Two panels — `Your bids` (left, treasury spent) and `Your offers`
//   (right, treasury received) — each with a Filled section and an
//   Unfilled (carry-forward) section, plus a totals row that sums
//   `quantity × pricePerUnit` over the filled deals only (carry-forwards
//   have not cleared so they do not contribute to treasury totals). On
//   viewports narrower than `dealBookTwoPanelMinWidth` (600 dp) the two
//   panels stack vertically; otherwise they sit side-by-side. The Deal
//   Book is purely read-only — observe-mode does not need a separate
//   `IgnorePointer` wrap because the ledger has no interactive controls.
//
// Observe mode (the GP-observation `canMutateViaUi == false` case,
// distinct from the "global observe / panels not defined" sentinel)
// wraps the Market tab controls in `IgnorePointer` and visually dims
// them so the table reads as read-only; the cargo indicator + warning
// stay live (they read directly from `Game` + `currentOrdersProvider`).
// The Deal Book ledger is rendered identically regardless of edit
// permission — it always reflects the resolved-turn state.
//
// Deferred to follow-up slices:
// - Priority dropdown (default priority 1 today; integration with the
//   `kMaxTradePriority` API surface is tracked under #2989).
//
// The two-tab structure is the durable wireframe E6 builds inside, so
// the contract this file ships matches what
// `SPEC/ui/trade-screen.md` § Layout / wireframe records as the canonical
// body for the screen.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/app_constants.dart';
import '../../../config/editorial_monocle_palette.dart';
import '../../../config/ui_screen_ids.dart';
import '../../../providers/games_provider.dart';
import '../../../widgets/ct_choice_chip.dart';
import '../../../widgets/ct_game_feature_screen_shell.dart';
import '../../../widgets/ct_panel.dart';
import '../../../widgets/ct_tab_strip.dart';
import '../../../widgets/ct_top_bar.dart';
import '../../../widgets/resource_icon.dart';
import '../../../widgets/strict_asset_icon.dart';
import '../shell_player_context.dart';
import '../widgets/observe_mode_not_defined_panel.dart';

part 'trade_screen_deal_book.dart';

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
  const TradeScreen({
    super.key,
    required this.game,
    required this.player,
    this.initialTabIndex = 0,
  }) : assert(
          initialTabIndex >= 0 && initialTabIndex < 2,
          'initialTabIndex must be 0 (Market) or 1 (Deal Book) for TradeScreen',
        );

  /// Initially-selected tab index for the body's `CtTabStrip`. Defaults
  /// to `0` so the dark-theme E4 contract (Market tab visible on first
  /// mount) is preserved for the production route. Story builders /
  /// widget tests opt into the Deal Book tab (`1`) without simulating a
  /// label tap; the underlying `CtTabStrip.initialTabIndex` is the only
  /// surface that propagates the override.
  final int initialTabIndex;

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

  /// Per-row key for the `None` direction chip on a Market tab row
  /// (Refs #2993 E5b). Tapping the chip removes any staged trade order
  /// for the commodity from `currentOrdersProvider`.
  static Key marketRowNoneChipKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:none');

  /// Per-row key for the `Bid` direction chip on a Market tab row
  /// (Refs #2993 E5b). Tapping the chip stages a `TradeOrderType.bid`
  /// for the commodity (replacing any prior offer for that commodity).
  static Key marketRowBidChipKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:bid');

  /// Per-row key for the `Offer` direction chip on a Market tab row
  /// (Refs #2993 E5b). Tapping the chip stages a `TradeOrderType.offer`
  /// for the commodity (replacing any prior bid for that commodity).
  static Key marketRowOfferChipKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:offer');

  /// Per-row key for the decrement button of the quantity stepper on a
  /// Market tab row (Refs #2993 E5b). Disabled when there is no staged
  /// trade order for the commodity or when its quantity is at the lower
  /// bound (`marketRowQuantityMin`).
  static Key marketRowDecrementKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:decrement');

  /// Per-row key for the increment button of the quantity stepper on a
  /// Market tab row (Refs #2993 E5b). Increments the staged trade order
  /// quantity by 1.
  static Key marketRowIncrementKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:increment');

  /// Per-row key for the quantity readout (`Text`) of the stepper on a
  /// Market tab row (Refs #2993 E5b). Shows the staged
  /// `TradeOrder.quantity` (or `marketRowQuantityIdleGlyph` when no
  /// trade order is staged for the commodity).
  static Key marketRowQuantityTextKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:quantity');

  /// Per-row key for the inline sellable-headroom readout rendered as
  /// `(N)` immediately after the commodity name on line 1 of the row.
  /// `N` is the per-commodity offer cap minus the row's already-staged
  /// offer quantity, sourced from
  /// `sellableHeadroomByCommodityId` (Refs #3093 — sellable clamp
  /// slice). Pin point for widget tests asserting the readout reflects
  /// the player's stockpile / staged-offer state without coupling to
  /// text-matching on the parent name line.
  static Key marketRowSellableReadoutKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:sellable');

  /// Per-row key for the leading `ResourceIcon` paint on line 1 of the
  /// Market row, immediately before the commodity display name (Refs
  /// `#3093` — row-icons slice). Mounted exactly once per row. When the
  /// commodity has no `ResourceIcon` asset (catalog gap), the icon
  /// widget still mounts under this key but paints an empty
  /// `SizedBox(marketRowResourceIconSize × marketRowResourceIconSize)`
  /// fallback per [`ResourceIcon.build`].
  static Key marketRowResourceIconKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:resourceIcon');

  /// Per-row key for the trailing treasury-coin glyph rendered
  /// immediately before the integer price text on line 1 of the Market
  /// row (Refs `#3093` — row-icons slice). Always mounted regardless of
  /// whether the row resolves to an integer price or the em-dash
  /// fallback so the coin acts as a visual currency cue rather than a
  /// price-availability flag.
  static Key marketRowPriceCoinIconKey(CommodityId commodityId) =>
      ValueKey<String>('tradeScreenMarketRow:$commodityId:priceCoin');

  /// Logical-pixel side length of the leading `ResourceIcon` paint on
  /// each Market row (Refs `#3093` — row-icons slice). 20 dp matches
  /// the Production panel's `CtResourceCell.leadingIconSize` so the
  /// Trade row's commodity glyph reads the same physical size as its
  /// Production-panel counterpart.
  static const double marketRowResourceIconSize = 20;

  /// Logical-pixel side length of the trailing treasury-coin glyph
  /// rendered next to the integer price on each Market row (Refs
  /// `#3093` — row-icons slice). 14 dp keeps the coin visually
  /// subordinate to the 20 dp `ResourceIcon` so the row reads
  /// `[ResourceIcon 20] Name (N) … [Coin 14] 30`.
  static const double marketRowPriceCoinIconSize = 14;

  /// Asset path of the treasury-coin glyph rendered next to each
  /// Market row's integer price (Refs `#3093` — row-icons slice). Same
  /// asset family as the game tab bar treasury chip
  /// (`GameTabBar._iconSize == 18`) so the coin visually anchors money
  /// across screens without re-issuing a different art asset.
  static const String marketRowPriceCoinAssetPath =
      '${kAppIconAssetPrefix}ui_icon_treasury_coin.png';

  /// Lower bound for the per-row quantity stepper when a trade order is
  /// staged. Setting the stepper below 1 is equivalent to choosing
  /// `None`, which removes the order — so the stepper is clamped at 1
  /// while a direction is selected.
  static const int marketRowQuantityMin = 1;

  /// Default starting quantity when the player first selects `Bid` or
  /// `Offer` on a row that has no staged trade order. Always 1 (the
  /// stepper minimum); the player increments from there. The
  /// per-commodity / cargo cap clamps the upper bound in #2993 E5c.
  static const int marketRowQuantityDefault = 1;

  /// Default `TradeOrder.priority` assigned when the player first
  /// stages a `Bid` or `Offer` on a row. The interactive priority
  /// dropdown is deferred to a follow-up slice; until the
  /// `kMaxTradePriority` API surface is wired (#2989), the row uses the
  /// highest tier (priority 1) so staged orders are stable.
  // ignore: avoid-non-null-assertion
  static const int marketRowDefaultPriority = 1;

  /// Glyph rendered in the per-row quantity readout when no trade order
  /// is staged for a commodity (`None` direction). Mirrors the price
  /// em-dash so the visual language is consistent across the row.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String marketRowQuantityIdleGlyph = '—';

  /// Stable widget key for the cross-commodity cargo indicator header
  /// rendered above the Market tab commodity list (Refs #2993 E5c).
  /// The widget at this key renders `Cargo remaining: X` where
  /// `X = max(0, tradeCargoCapacity − totalStagedBidQuantity)`.
  static const Key marketCargoIndicatorKey =
      ValueKey<String>('tradeScreenMarketCargoIndicator');

  /// Stable widget key for the cargo-limit warning row rendered below
  /// the cargo indicator (Refs #2993 E5c). Only mounted when
  /// `remainingCargo == 0` AND `totalStagedBidQuantity > 0`; absent
  /// otherwise so widget tests can `expect(find.byKey(...), findsNothing)`
  /// in the steady non-saturated state.
  static const Key marketCargoWarningKey =
      ValueKey<String>('tradeScreenMarketCargoWarning');

  /// Localized cargo indicator prefix. SPEC/ui/trade-screen.md §
  /// Cargo indicator pins the literal `"Cargo remaining:"` so widget
  /// tests can drive the indicator via `find.text` without coupling to
  /// the localization catalog before the trade screen is l10n-ised.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String cargoIndicatorPrefix = 'Cargo remaining:';

  /// Cargo-limit warning copy rendered below the cargo indicator when
  /// the staged cross-commodity bid total saturates the player's
  /// `tradeCargoCapacity` (Refs #2993 E5c).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String cargoLimitWarningText =
      'Cargo limit reached — increase your fleet capacity or reduce bids.';

  /// Stable widget key for the Deal Book tab body. Pin point for widget
  /// tests asserting the Deal Book tab body is present in the tab
  /// strip's `IndexedStack` (visible when the Deal Book tab is selected
  /// after the user taps the Deal Book label). Refs #2993 E6 swapped
  /// the placeholder for `_DealBookTabContent` — the key is intentionally
  /// stable so existing tab-switch tests keep pinning the same body root.
  static const Key dealBookTabBodyKey =
      ValueKey<String>('tradeScreenDealBookTabBody');

  /// Stable widget key for the root of the live Deal Book ledger content
  /// (Refs #2993 E6). Sits directly under `dealBookTabBodyKey` and pins
  /// the two-panel layout so widget tests can scope queries.
  static const Key dealBookContentKey =
      ValueKey<String>('tradeScreenDealBookContent');

  /// Side identifier used to scope per-row Deal Book keys to the bids
  /// panel (commodities the player **bought**).
  static const String dealBookSideBids = 'bids';

  /// Side identifier used to scope per-row Deal Book keys to the offers
  /// panel (commodities the player **sold**).
  static const String dealBookSideOffers = 'offers';

  /// Stable widget key for the Deal Book bids panel container
  /// (Refs #2993 E6).
  static const Key dealBookBidsPanelKey =
      ValueKey<String>('tradeScreenDealBookBidsPanel');

  /// Stable widget key for the Deal Book offers panel container
  /// (Refs #2993 E6).
  static const Key dealBookOffersPanelKey =
      ValueKey<String>('tradeScreenDealBookOffersPanel');

  /// Stable widget key for the Deal Book bids panel treasury-totals row
  /// (`Total spent: N`). Always mounted under the bids panel even when
  /// `filledTotal == 0` so widget tests can pin the totals affordance.
  static const Key dealBookBidsTotalsKey =
      ValueKey<String>('tradeScreenDealBookBidsTotals');

  /// Stable widget key for the Deal Book offers panel treasury-totals
  /// row (`Total received: N`).
  static const Key dealBookOffersTotalsKey =
      ValueKey<String>('tradeScreenDealBookOffersTotals');

  /// Stable widget key for the Deal Book bids panel empty-state copy.
  /// Mounted only when the player has zero filled bids **and** zero
  /// carry-forward bids for the resolved turn; absent otherwise.
  static const Key dealBookBidsEmptyKey =
      ValueKey<String>('tradeScreenDealBookBidsEmpty');

  /// Stable widget key for the Deal Book offers panel empty-state copy.
  /// Mounted only when the player has zero filled sales **and** zero
  /// carry-forward offers for the resolved turn; absent otherwise.
  static const Key dealBookOffersEmptyKey =
      ValueKey<String>('tradeScreenDealBookOffersEmpty');

  /// Per-row Deal Book key for a filled deal row, scoped by `side`
  /// (`dealBookSideBids` or `dealBookSideOffers`) and the row's
  /// zero-based index inside the per-side filled-deals list. Lets widget
  /// tests pin a specific filled row without coupling to text matching.
  static Key dealBookFilledRowKey(String side, int index) =>
      ValueKey<String>('tradeScreenDealBookFilledRow:$side:$index');

  /// Per-row Deal Book key for an unfilled (carry-forward) order row,
  /// scoped by `side` and zero-based index.
  static Key dealBookUnfilledRowKey(String side, int index) =>
      ValueKey<String>('tradeScreenDealBookUnfilledRow:$side:$index');

  /// Minimum viewport width (logical px) above which the Deal Book
  /// renders its two panels side-by-side. Below this threshold the
  /// panels stack vertically so the 320 dp minimum viewport stays
  /// overflow-safe per `SPEC/ui/mobile-adaptation.md` § 7.
  static const double dealBookTwoPanelMinWidth = 600;

  /// Localized title for the Deal Book bids panel — the player's
  /// previous-turn buying activity (filled buys + carry-forward bids).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookBidsPanelTitle = 'Your bids';

  /// Localized title for the Deal Book offers panel — the player's
  /// previous-turn selling activity (filled sales + carry-forward
  /// offers).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookOffersPanelTitle = 'Your offers';

  /// Localized section heading for filled rows inside a Deal Book panel.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookFilledHeading = 'Filled';

  /// Localized section heading for carry-forward (unfilled) rows inside
  /// a Deal Book panel.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookUnfilledHeading = 'Unfilled (carry-forward)';

  /// Localized empty-state copy for the bids panel when the player has
  /// neither filled bids nor carry-forward bids for the resolved turn.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookBidsEmptyText =
      'No bids placed last turn.';

  /// Localized empty-state copy for the offers panel when the player
  /// has neither filled sales nor carry-forward offers for the resolved
  /// turn.
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookOffersEmptyText =
      'No offers placed last turn.';

  /// Localized totals label for the bids panel (treasury spent on
  /// filled buys this turn — carry-forwards excluded because they have
  /// not cleared).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookTotalSpentLabel = 'Total spent';

  /// Localized totals label for the offers panel (treasury received
  /// from filled sales this turn — carry-forwards excluded).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookTotalReceivedLabel = 'Total received';

  /// Localized empty-state copy rendered inside a Deal Book panel's
  /// **Filled** section when the player has no filled rows on that side
  /// (but does have carry-forwards, so the panel itself is non-empty).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookFilledEmptyText = 'No deals filled this turn.';

  /// Localized empty-state copy rendered inside a Deal Book panel's
  /// **Unfilled** section when the player has no carry-forward orders
  /// on that side (but does have filled rows, so the panel itself is
  /// non-empty).
  // ignore: avoid_hardcoded_strings_in_widgets
  static const String dealBookUnfilledEmptyText =
      'No orders carrying forward.';

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
        final bool canEdit =
            shellRef.read(shellPlayerContextProvider).canMutateViaUi;
        return _TradeScreenTabsBody(
          key: tabsBodyKey,
          game: displayGame,
          playerId: player.id,
          canEdit: canEdit,
          initialTabIndex: initialTabIndex,
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
/// now renders the interactive bid/offer/none + quantity stepper row
/// sourced from [Game.worldMarketState] + `currentOrdersProvider`
/// (Refs #2993 E5a + E5b); the Deal Book tab keeps the placeholder copy
/// until the per-player ledger work for Refs #2993 E6 lands. The
/// two-tab structure stays as the durable wireframe so the follow-up
/// cargo indicator + priority dropdown + Deal Book ledger slices can
/// swap each tab body in place without remounting the strip.
class _TradeScreenTabsBody extends StatelessWidget {
  const _TradeScreenTabsBody({
    super.key,
    required this.game,
    required this.playerId,
    required this.canEdit,
    this.initialTabIndex = 0,
  });

  final Game game;
  final String playerId;
  final bool canEdit;
  final int initialTabIndex;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: CtPanel(
        padding: const EdgeInsets.all(16),
        child: CtTabStrip(
          initialTabIndex: initialTabIndex,
          tabLabels: const <String>[
            TradeScreen.marketTabLabel,
            TradeScreen.dealBookTabLabel,
          ],
          tabViews: <Widget>[
            _MarketTabContent(
              key: TradeScreen.marketTabBodyKey,
              game: game,
              playerId: playerId,
              canEdit: canEdit,
            ),
            _DealBookTabContent(
              key: TradeScreen.dealBookTabBodyKey,
              game: game,
              playerId: playerId,
            ),
          ],
        ),
      ),
    );
  }
}

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

    final List<Commodity> rows = _tradeableCommoditiesSortedByDisplayName();
    final WorldMarketState market = game.worldMarketState;
    final Orders orders = ref.watch(currentOrdersProvider);

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
    // frame.
    final Map<CommodityId, int> offerCap = offerCapByCommodityId(
      game: game,
      playerId: playerId,
    );
    final Map<CommodityId, int> stagedOffers =
        stagedOfferQuantitiesByCommodityId(
      orders: orders,
      playerId: playerId,
    );

    // SingleChildScrollView + Column (instead of ListView.builder) so
    // every commodity row is built up-front. Widget tests pin all 22
    // tradeable rows by key without scrolling; the row count is bounded
    // by the catalog size (22) so the eager build cost is negligible
    // and the deterministic ordering survives Widgetbook stories that
    // render the screen inside a non-scrollable container.
    final Widget list = SingleChildScrollView(
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
                commodityId: rows[index].id,
                commodityDisplayName:
                    rows[index].displayName ?? rows[index].id,
                priceText: _formatPrice(
                  market.prices[rows[index].id],
                  commodityId: rows[index].id,
                ),
                volumeText: _volumeText(
                  market.lastTurnActivity[rows[index].id] ??
                      MarketActivity.empty,
                ),
                stagedOrder: tradeOrderForPlayerCommodity(
                  orders,
                  playerId,
                  rows[index].id,
                ),
                sellableHeadroom: _sellableHeadroomFor(
                  offerCap: offerCap,
                  stagedOffers: stagedOffers,
                  commodityId: rows[index].id,
                ),
                offerCap: offerCap[rows[index].id] ?? 0,
                nameStyle: nameStyle,
                priceStyle: priceStyle,
                volumeStyle: volumeStyle,
                quantityStyle: quantityStyle,
                onDirectionChanged: (TradeOrderType? next) =>
                    _handleDirectionChanged(ref, rows[index].id, next),
                onIncrement: () =>
                    _handleQuantityDelta(ref, rows[index].id, 1),
                onDecrement: () =>
                    _handleQuantityDelta(ref, rows[index].id, -1),
              ),
            ),
        ],
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

  void _handleDirectionChanged(
    WidgetRef ref,
    CommodityId commodityId,
    TradeOrderType? next,
  ) {
    final CurrentOrdersNotifier notifier =
        ref.read(currentOrdersProvider.notifier);
    final Orders orders = ref.read(currentOrdersProvider);
    if (next == null) {
      final Orders updated = removeTradeOrderForPlayer(
        orders: orders,
        playerId: playerId,
        commodityId: commodityId,
      );
      if (!identical(updated, orders)) notifier.replaceAll(updated);
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
        final int treasuryBudget = treasuryAvailableForBidsByPlayer(
          game: game,
          playerId: playerId,
        );
        final int totalStagedBidSpend = stagedBidTotalSpendByPlayer(
          orders: orders,
          playerId: playerId,
          game: game,
          resourceRules: ResourceRules.defaultRules,
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
      // is `stockpile − industryAllocation` (alloc treated as 0 until
      // a generic projector lands; see
      // `sellable_quantity.dart`). Mutual exclusion guarantees the row
      // is the only staged offer for the commodity, so the cap is
      // applied directly to the row's quantity without subtracting
      // sibling offers.
      final int rowCap = offerCapByCommodityId(
        game: game,
        playerId: playerId,
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
    notifier.replaceAll(updated);
  }

  void _handleQuantityDelta(
    WidgetRef ref,
    CommodityId commodityId,
    int delta,
  ) {
    final CurrentOrdersNotifier notifier =
        ref.read(currentOrdersProvider.notifier);
    final Orders orders = ref.read(currentOrdersProvider);
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
        final int treasuryBudget = treasuryAvailableForBidsByPlayer(
          game: game,
          playerId: playerId,
        );
        final int totalStagedBidSpend = stagedBidTotalSpendByPlayer(
          orders: orders,
          playerId: playerId,
          game: game,
          resourceRules: ResourceRules.defaultRules,
        );
        if (totalStagedBidSpend + delta * rowPrice > treasuryBudget) return;
      }
    } else if (prior.type == TradeOrderType.offer && delta > 0) {
      // Refs #3093 — sellable clamp slice. Block the `+` tap when the
      // per-commodity offer cap (`stockpile − industryAllocation`,
      // alloc=0 today) is exhausted. Mutual exclusion guarantees the
      // row is the only staged offer for the commodity, so the cap is
      // applied directly to `prior.quantity + delta`.
      final int rowCap = offerCapByCommodityId(
        game: game,
        playerId: playerId,
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
    notifier.replaceAll(updated);
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

  /// Formats the per-commodity market price for the Market tab row.
  ///
  /// Prices on `Game.worldMarketState.prices` are integers per
  /// `SPEC/game/world-market.md` § Price discovery and SPEC/ui/trade-screen.md
  /// § Market tab — read-only commodity table. When the prices map lacks an
  /// entry for a tradeable commodity, this helper falls back to the
  /// `defaultMarketPrice` int from `ResourceRules.defaultRules` (per the
  /// resource catalog) so the row never renders the unknown-price em-dash
  /// for raw resources whose catalog default price is published. The
  /// canonical em-dash glyph remains the fallback only when neither the
  /// market state nor the catalog has a value (manufactured commodities,
  /// whose first market price is discovered in-game, are not enumerated in
  /// `ResourceRules.defaultMarketPrice` today and so render the em-dash
  /// until they participate in a market turn — tracked as follow-up to
  /// #3093).
  static String _formatPrice(int? price, {required CommodityId commodityId}) {
    final int? effective =
        price ?? ResourceRules.defaultRules
            .defaultMarketPriceForCommodityId(commodityId);
    if (effective == null) return priceUnknownGlyph;
    return effective.toString();
  }
}

/// One row of the Market tab commodity table. Lays the read-only
/// content on the first two lines and the interactive direction
/// selector + stepper on a third line so the row remains overflow-safe
/// at the 320 dp minimum viewport (SPEC/ui/mobile-adaptation.md §7).
class _MarketCommodityRow extends StatelessWidget {
  const _MarketCommodityRow({
    required this.commodityId,
    required this.commodityDisplayName,
    required this.priceText,
    required this.volumeText,
    required this.stagedOrder,
    required this.sellableHeadroom,
    required this.offerCap,
    required this.nameStyle,
    required this.priceStyle,
    required this.volumeStyle,
    required this.quantityStyle,
    required this.onDirectionChanged,
    required this.onIncrement,
    required this.onDecrement,
  });

  final CommodityId commodityId;
  final String commodityDisplayName;
  final String priceText;
  final String volumeText;
  final TradeOrder? stagedOrder;

  /// Refs #3093 — sellable clamp slice. The `(N)` value rendered
  /// next to the commodity name. Computed in [_MarketTabContent] as
  /// `max(0, offerCap − stagedOffer)`.
  final int sellableHeadroom;

  /// Refs #3093 — sellable clamp slice. The per-commodity offer cap
  /// (`stockpile − industryAllocation`, alloc=0 today). Used to gate
  /// the Offer chip and offer-side `+` button so they read as
  /// disabled when the cap is `0`.
  final int offerCap;

  final TextStyle nameStyle;
  final TextStyle priceStyle;
  final TextStyle volumeStyle;
  final TextStyle quantityStyle;
  final ValueChanged<TradeOrderType?> onDirectionChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  bool get _hasStagedOrder => stagedOrder != null;

  String get _quantityText => stagedOrder == null
      ? TradeScreen.marketRowQuantityIdleGlyph
      : stagedOrder!.quantity.toString();

  bool get _canDecrement =>
      stagedOrder != null &&
      stagedOrder!.quantity > TradeScreen.marketRowQuantityMin;

  /// True when the row's `+` button can grow the staged order quantity.
  /// For bids the cross-commodity cargo cap (Refs #2993 E5c) gates this
  /// via the `_handleQuantityDelta` no-op when cargo is exhausted; for
  /// offers (Refs #3093) the per-commodity offer cap caps the row at
  /// `offerCap` so the button reads as disabled at saturation.
  bool get _canIncrement {
    if (!_hasStagedOrder) return false;
    if (stagedOrder!.type == TradeOrderType.offer) {
      return stagedOrder!.quantity < offerCap;
    }
    return true;
  }

  /// True when the Offer chip can be toggled on. When the per-commodity
  /// offer cap is `0` (stockpile exhausted) and no offer is already
  /// staged, the chip reads as disabled so the player gets immediate
  /// visual feedback that no units are sellable.
  bool get _canSelectOffer {
    if (stagedOrder?.type == TradeOrderType.offer) return true;
    return offerCap > 0;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _MarketCommodityRowHeader(
          commodityId: commodityId,
          commodityDisplayName: commodityDisplayName,
          priceText: priceText,
          sellableHeadroom: sellableHeadroom,
          nameStyle: nameStyle,
          priceStyle: priceStyle,
        ),
        const SizedBox(height: 2),
        Text(volumeText, style: volumeStyle),
        const SizedBox(height: 6),
        _MarketCommodityRowControls(
          commodityId: commodityId,
          stagedType: stagedOrder?.type,
          quantityText: _quantityText,
          quantityStyle: quantityStyle,
          canDecrement: _canDecrement,
          canIncrement: _canIncrement,
          canSelectOffer: _canSelectOffer,
          onDirectionChanged: onDirectionChanged,
          onIncrement: onIncrement,
          onDecrement: onDecrement,
        ),
      ],
    );
  }
}

/// Top read-only line of a Market tab commodity row (Refs #3093):
/// resource icon, commodity name, sellable `(N)` headroom readout,
/// a flexible spacer, then the coin icon and current market price.
/// Extracted from `_MarketCommodityRow.build` to keep the parent
/// `build` body within the `widget_build_method_too_long` AST cap.
class _MarketCommodityRowHeader extends StatelessWidget {
  const _MarketCommodityRowHeader({
    required this.commodityId,
    required this.commodityDisplayName,
    required this.priceText,
    required this.sellableHeadroom,
    required this.nameStyle,
    required this.priceStyle,
  });

  final CommodityId commodityId;
  final String commodityDisplayName;
  final String priceText;
  final int sellableHeadroom;
  final TextStyle nameStyle;
  final TextStyle priceStyle;

  @override
  Widget build(BuildContext context) {
    final TextStyle sellableStyle = nameStyle.copyWith(
      color: EditorialMonoclePalette.muted,
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        ResourceIcon(
          key: TradeScreen.marketRowResourceIconKey(commodityId),
          commodityId: commodityId,
          size: TradeScreen.marketRowResourceIconSize,
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            commodityDisplayName,
            style: nameStyle,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          // ignore: avoid_hardcoded_strings_in_widgets
          '($sellableHeadroom)',
          key: TradeScreen.marketRowSellableReadoutKey(commodityId),
          style: sellableStyle,
        ),
        const Spacer(),
        const SizedBox(width: 8),
        StrictAssetIcon(
          key: TradeScreen.marketRowPriceCoinIconKey(commodityId),
          assetPath: TradeScreen.marketRowPriceCoinAssetPath,
          width: TradeScreen.marketRowPriceCoinIconSize,
          height: TradeScreen.marketRowPriceCoinIconSize,
        ),
        const SizedBox(width: 4),
        Text(priceText, style: priceStyle),
      ],
    );
  }
}

/// Interactive controls strip below the static read-only data on a
/// Market tab commodity row (Refs #2993 E5b).
class _MarketCommodityRowControls extends StatelessWidget {
  const _MarketCommodityRowControls({
    required this.commodityId,
    required this.stagedType,
    required this.quantityText,
    required this.quantityStyle,
    required this.canDecrement,
    required this.canIncrement,
    required this.canSelectOffer,
    required this.onDirectionChanged,
    required this.onIncrement,
    required this.onDecrement,
  });

  final CommodityId commodityId;
  final TradeOrderType? stagedType;
  final String quantityText;
  final TextStyle quantityStyle;
  final bool canDecrement;
  final bool canIncrement;

  /// Refs #3093 — sellable clamp slice. When `false` the Offer chip
  /// reads as disabled (no `onSelected` handler) so the player cannot
  /// stage an offer for a commodity whose per-commodity offer cap is
  /// `0`. Offers already staged on the row remain interactive (the
  /// player can decrement / drop them) regardless of this gate.
  final bool canSelectOffer;

  final ValueChanged<TradeOrderType?> onDirectionChanged;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        CtChoiceChip(
          key: TradeScreen.marketRowNoneChipKey(commodityId),
          selected: stagedType == null,
          onSelected: (_) => onDirectionChanged(null),
          label: const Text(_MarketTabContent.noneChipLabel),
        ),
        CtChoiceChip(
          key: TradeScreen.marketRowBidChipKey(commodityId),
          selected: stagedType == TradeOrderType.bid,
          onSelected: (_) => onDirectionChanged(TradeOrderType.bid),
          label: const Text(_MarketTabContent.bidChipLabel),
        ),
        CtChoiceChip(
          key: TradeScreen.marketRowOfferChipKey(commodityId),
          selected: stagedType == TradeOrderType.offer,
          onSelected: canSelectOffer
              ? (_) => onDirectionChanged(TradeOrderType.offer)
              : null,
          label: const Text(_MarketTabContent.offerChipLabel),
        ),
        _StepperButton(
          buttonKey: TradeScreen.marketRowDecrementKey(commodityId),
          // ignore: avoid_hardcoded_strings_in_widgets
          glyph: '−',
          semanticLabel: _MarketTabContent.decrementSemanticLabel,
          onPressed: canDecrement ? onDecrement : null,
        ),
        SizedBox(
          width: 28,
          child: Text(
            quantityText,
            key: TradeScreen.marketRowQuantityTextKey(commodityId),
            style: quantityStyle,
            textAlign: TextAlign.center,
          ),
        ),
        _StepperButton(
          buttonKey: TradeScreen.marketRowIncrementKey(commodityId),
          // ignore: avoid_hardcoded_strings_in_widgets
          glyph: '+',
          semanticLabel: _MarketTabContent.incrementSemanticLabel,
          onPressed: canIncrement ? onIncrement : null,
        ),
      ],
    );
  }
}

/// Compact stepper button used by [_MarketCommodityRowControls]. Uses
/// an `InkWell` so the chrome stays in the editorial-monocle palette
/// (no Material elevated buttons or accent splash colours).
class _StepperButton extends StatelessWidget {
  const _StepperButton({
    required this.buttonKey,
    required this.glyph,
    required this.semanticLabel,
    required this.onPressed,
  });

  final Key buttonKey;
  final String glyph;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextStyle glyphStyle =
        (theme.textTheme.titleSmall ?? const TextStyle(fontSize: 14))
            .copyWith(
              color: onPressed == null
                  ? EditorialMonoclePalette.muted
                  : EditorialMonoclePalette.accent,
            );
    final Color borderColor = onPressed == null
        ? EditorialMonoclePalette.muted
        : EditorialMonoclePalette.accent;
    return Semantics(
      button: true,
      enabled: onPressed != null,
      label: semanticLabel,
      child: InkWell(
        key: buttonKey,
        onTap: onPressed,
        child: Container(
          width: 28,
          height: 24,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: EditorialMonoclePalette.surface.withValues(alpha: 0.5),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Text(glyph, style: glyphStyle),
        ),
      ),
    );
  }
}

