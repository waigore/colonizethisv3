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

import '../../../../config/app_constants.dart';
import '../../../../config/editorial_monocle_palette.dart';
import '../../../../config/ui_screen_ids.dart';
import '../../../../l10n/l10n.dart';
import '../../../../providers/games_provider.dart';
import '../../../../providers/production_allocation_provider.dart';
import '../../../../providers/treasury_summary_provider.dart';
import '../../../../widgets/ct_choice_chip.dart';
import '../../../../widgets/ct_game_feature_screen_shell.dart';
import '../../../../widgets/ct_panel.dart';
import '../../../../widgets/ct_section_label.dart';
import '../../../../widgets/ct_spacing.dart';
import '../../../../widgets/ct_tab_strip.dart';
import '../../../../widgets/ct_top_bar.dart';
import '../../../../widgets/resource_icon.dart';
import '../../../../widgets/strict_asset_icon.dart';
import '../../widgets/shell/shell_player_context.dart';
import '../../widgets/shell/shell_player_guarded_body.dart';
import 'trade_section_handlers.dart';

part 'trade_screen_contract.dart';
part 'trade_screen_contract_market.dart';
part 'trade_screen_contract_deal_book.dart';
part 'trade_screen_deal_book.dart';
part 'trade_screen_deal_book_panel.dart';
part 'trade_screen_deal_book_rows.dart';
part 'trade_screen_market_row.dart';
part 'trade_screen_market_row_controls.dart';
part 'trade_screen_market_row_header.dart';
part 'trade_screen_market_row_stepper.dart';
part 'trade_screen_market_tab.dart';
part 'trade_screen_market_tab_build.dart';
part 'trade_screen_market_tab_cargo_header.dart';
part 'trade_screen_market_tab_order_handlers.dart';
part 'trade_screen_market_tab_catalog.dart';
part 'trade_screen_tabs_body.dart';

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

  static const String topBarBackLabel = _TradeScreenContract.topBarBackLabel;
  static const String topBarTitle = _TradeScreenContract.topBarTitle;
  static const String topBarIconAsset = _TradeScreenContract.topBarIconAsset;
  static const Key topBarKey = _TradeScreenContract.topBarKey;
  static const Key tabsBodyKey = _TradeScreenContract.tabsBodyKey;
  static const Key marketTabBodyKey = _TradeScreenContract.marketTabBodyKey;
  static const Key marketCommodityListKey =
      _TradeScreenContract.marketCommodityListKey;
  static const Key marketSectionFoodKey =
      _TradeScreenContract.marketSectionFoodKey;
  static const Key marketSectionRawMaterialsKey =
      _TradeScreenContract.marketSectionRawMaterialsKey;
  static const Key marketSectionManufacturedKey =
      _TradeScreenContract.marketSectionManufacturedKey;
  static Key marketCommodityRowKey(CommodityId commodityId) =>
      _TradeScreenContract.marketCommodityRowKey(commodityId);
  static Key marketRowNoneChipKey(CommodityId commodityId) =>
      _TradeScreenContract.marketRowNoneChipKey(commodityId);
  static Key marketRowBidChipKey(CommodityId commodityId) =>
      _TradeScreenContract.marketRowBidChipKey(commodityId);
  static Key marketRowOfferChipKey(CommodityId commodityId) =>
      _TradeScreenContract.marketRowOfferChipKey(commodityId);
  static Key marketRowDecrementKey(CommodityId commodityId) =>
      _TradeScreenContract.marketRowDecrementKey(commodityId);
  static Key marketRowIncrementKey(CommodityId commodityId) =>
      _TradeScreenContract.marketRowIncrementKey(commodityId);
  static Key marketRowQuantityTextKey(CommodityId commodityId) =>
      _TradeScreenContract.marketRowQuantityTextKey(commodityId);
  static Key marketRowSellableReadoutKey(CommodityId commodityId) =>
      _TradeScreenContract.marketRowSellableReadoutKey(commodityId);
  static Key marketRowResourceIconKey(CommodityId commodityId) =>
      _TradeScreenContract.marketRowResourceIconKey(commodityId);
  static Key marketRowPriceCoinIconKey(CommodityId commodityId) =>
      _TradeScreenContract.marketRowPriceCoinIconKey(commodityId);
  static const double marketRowResourceIconSize =
      _TradeScreenContract.marketRowResourceIconSize;
  static const double marketRowPriceCoinIconSize =
      _TradeScreenContract.marketRowPriceCoinIconSize;
  static const double marketRowPriceColumnWidth =
      _TradeScreenContract.marketRowPriceColumnWidth;
  static const double marketRowPriceColumnInnerGap =
      _TradeScreenContract.marketRowPriceColumnInnerGap;
  @visibleForTesting
  static ResourceRules? get marketPriceResourceRulesOverride =>
      _TradeScreenContract.marketPriceResourceRulesOverride;
  @visibleForTesting
  static set marketPriceResourceRulesOverride(ResourceRules? value) =>
      _TradeScreenContract.marketPriceResourceRulesOverride = value;
  static const String marketRowPriceCoinAssetPath =
      _TradeScreenContract.marketRowPriceCoinAssetPath;
  static const int marketRowQuantityMin =
      _TradeScreenContract.marketRowQuantityMin;
  static const int marketRowQuantityDefault =
      _TradeScreenContract.marketRowQuantityDefault;
  static const int marketRowDefaultPriority =
      _TradeScreenContract.marketRowDefaultPriority;
  static const String marketRowQuantityIdleGlyph =
      _TradeScreenContract.marketRowQuantityIdleGlyph;
  static const Key marketCargoIndicatorKey =
      _TradeScreenContract.marketCargoIndicatorKey;
  static const Key marketCargoWarningKey =
      _TradeScreenContract.marketCargoWarningKey;
  static const String cargoIndicatorPrefix =
      _TradeScreenContract.cargoIndicatorPrefix;
  static const String cargoLimitWarningText =
      _TradeScreenContract.cargoLimitWarningText;
  static const Key dealBookTabBodyKey = _TradeScreenContract.dealBookTabBodyKey;
  static const Key dealBookContentKey = _TradeScreenContract.dealBookContentKey;
  static const String dealBookSideBids = _TradeScreenContract.dealBookSideBids;
  static const String dealBookSideOffers =
      _TradeScreenContract.dealBookSideOffers;
  static const Key dealBookBidsPanelKey =
      _TradeScreenContract.dealBookBidsPanelKey;
  static const Key dealBookOffersPanelKey =
      _TradeScreenContract.dealBookOffersPanelKey;
  static const Key dealBookBidsTotalsKey =
      _TradeScreenContract.dealBookBidsTotalsKey;
  static const Key dealBookOffersTotalsKey =
      _TradeScreenContract.dealBookOffersTotalsKey;
  static const Key dealBookBidsEmptyKey =
      _TradeScreenContract.dealBookBidsEmptyKey;
  static const Key dealBookOffersEmptyKey =
      _TradeScreenContract.dealBookOffersEmptyKey;
  static Key dealBookFilledRowKey(String side, int index) =>
      _TradeScreenContract.dealBookFilledRowKey(side, index);
  static Key dealBookUnfilledRowKey(String side, int index) =>
      _TradeScreenContract.dealBookUnfilledRowKey(side, index);
  static const double dealBookTwoPanelMinWidth =
      _TradeScreenContract.dealBookTwoPanelMinWidth;
  static const String dealBookBidsPanelTitle =
      _TradeScreenContract.dealBookBidsPanelTitle;
  static const String dealBookOffersPanelTitle =
      _TradeScreenContract.dealBookOffersPanelTitle;
  static const String dealBookFilledHeading =
      _TradeScreenContract.dealBookFilledHeading;
  static const String dealBookUnfilledHeading =
      _TradeScreenContract.dealBookUnfilledHeading;
  static const String dealBookBidsEmptyText =
      _TradeScreenContract.dealBookBidsEmptyText;
  static const String dealBookOffersEmptyText =
      _TradeScreenContract.dealBookOffersEmptyText;
  static const String dealBookTotalSpentLabel =
      _TradeScreenContract.dealBookTotalSpentLabel;
  static const String dealBookTotalReceivedLabel =
      _TradeScreenContract.dealBookTotalReceivedLabel;
  static String formatFilledDealUnitPrice(double pricePerUnit) =>
      _TradeScreenContract.formatFilledDealUnitPrice(pricePerUnit);
  static const String dealBookFilledEmptyText =
      _TradeScreenContract.dealBookFilledEmptyText;
  static const String dealBookUnfilledEmptyText =
      _TradeScreenContract.dealBookUnfilledEmptyText;
  static const String marketTabLabel = _TradeScreenContract.marketTabLabel;
  static const String dealBookTabLabel = _TradeScreenContract.dealBookTabLabel;

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

/// The Market tab body (`_MarketTabContent`, `_SectionedTradeableCommodities`)
/// lives in the `trade_screen_market_tab.dart` part fragment, and its
/// per-commodity row widgets (`_MarketCommodityRow`,
/// `_MarketCommodityRowHeader`, `_MarketCommodityRowControls`,
/// `_StepperButton`) live in the `trade_screen_market_row.dart` part
/// fragment, keeping this host file under the repo code-review
/// physical-line limit and the issue #3594 ≤700-line target
/// (`SPEC/program/dart-file-non-comment-line-size.md`).

