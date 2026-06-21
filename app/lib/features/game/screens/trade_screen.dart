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
import '../../../l10n/l10n.dart';
import '../../../providers/games_provider.dart';
import '../../../providers/production_allocation_provider.dart';
import '../../../providers/treasury_summary_provider.dart';
import '../../../widgets/ct_choice_chip.dart';
import '../../../widgets/ct_game_feature_screen_shell.dart';
import '../../../widgets/ct_panel.dart';
import '../../../widgets/ct_section_label.dart';
import '../../../widgets/ct_spacing.dart';
import '../../../widgets/ct_tab_strip.dart';
import '../../../widgets/ct_top_bar.dart';
import '../../../widgets/resource_icon.dart';
import '../../../widgets/strict_asset_icon.dart';
import '../shell_player_context.dart';
import '../widgets/shell_player_guarded_body.dart';
import 'trade_section_handlers.dart';

part 'trade_screen_deal_book.dart';
part 'trade_screen_market_row.dart';
part 'trade_screen_market_tab.dart';

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

  /// Stable widget key for the `Food` category section header inside
  /// the Market tab commodity list (Refs `#3093` § Layout & grouping
  /// — sectioned grouping slice). Pin point for widget tests asserting
  /// the Food section label is mounted at the top of the list with
  /// the food commodities beneath it. The widget at this key is a
  /// `CtSectionLabel` whose visible text resolves from
  /// `l10n.production_food` (English fallback `Food`) so the trade
  /// screen reuses the existing Production-panel l10n surface.
  static const Key marketSectionFoodKey =
      ValueKey<String>('tradeScreenMarketSection:food');

  /// Stable widget key for the `Raw Materials` category section header
  /// inside the Market tab commodity list (Refs `#3093` § Layout &
  /// grouping — sectioned grouping slice). Visible text resolves from
  /// `l10n.production_rawMaterials` (English fallback `Raw Materials`).
  static const Key marketSectionRawMaterialsKey =
      ValueKey<String>('tradeScreenMarketSection:rawMaterials');

  /// Stable widget key for the `Manufactured` category section header
  /// inside the Market tab commodity list (Refs `#3093` § Layout &
  /// grouping — sectioned grouping slice). Visible text resolves from
  /// `l10n.production_manufactured` (English fallback `Manufactured`).
  static const Key marketSectionManufacturedKey =
      ValueKey<String>('tradeScreenMarketSection:manufactured');

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

  /// Fixed width of the trailing market-price column (coin + price text)
  /// on Market row line 1 (Refs `#3487`). The same width on every row so
  /// the right edge of the price digits shares a vertical column across
  /// the commodity list. Sized to fit [marketRowPriceCoinIconSize] +
  /// [marketRowPriceColumnInnerGap] + three-digit catalog default prices
  /// (e.g. manufactured `steel` at `530`) at [titleSmall] without clipping.
  static const double marketRowPriceColumnWidth = 64;

  /// Horizontal gap between the treasury-coin glyph and the price text
  /// inside the trailing market-price column (Refs `#3487`).
  static const double marketRowPriceColumnInnerGap = 4;

  /// When non-null, overrides [ResourceRules.defaultRules] for Market tab
  /// price formatting only. Widget tests set this to exercise the em-dash
  /// fallback path without a catalog default (Refs `#3487` AC4).
  @visibleForTesting
  static ResourceRules? marketPriceResourceRulesOverride;

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

  /// Formats a filled-deal unit price for Deal Book rows (Refs #3093).
  ///
  /// `FilledDeal.pricePerUnit` may still be a legacy `double` on older
  /// saves; display uses `floor` so the readout matches integer market
  /// prices per `SPEC/game/world-market.md` § Price discovery.
  static String formatFilledDealUnitPrice(double pricePerUnit) =>
      pricePerUnit.floor().toString();

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
        final shell = shellRef.read(shellPlayerContextProvider);
        // ignore: avoid_hardcoded_strings_in_widgets
        final sentinel = observeNotDefinedSentinel(shell, 'Trade');
        if (sentinel != null) return sentinel;
        final bool canEdit = shell.canMutateViaUi;
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
      padding: const EdgeInsets.all(CtSpacing.l),
      child: CtPanel(
        padding: const EdgeInsets.all(CtSpacing.l),
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

/// The Market tab body (`_MarketTabContent`, `_SectionedTradeableCommodities`)
/// lives in the `trade_screen_market_tab.dart` part fragment, and its
/// per-commodity row widgets (`_MarketCommodityRow`,
/// `_MarketCommodityRowHeader`, `_MarketCommodityRowControls`,
/// `_StepperButton`) live in the `trade_screen_market_row.dart` part
/// fragment, keeping this host file under the repo code-review
/// physical-line limit and the issue #3594 ≤700-line target
/// (`SPEC/program/dart-file-non-comment-line-size.md`).

