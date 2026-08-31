// Widget tests for the Trade Market tab observe-mode chrome parity
// (Refs #3093 — observe-mode rendering parity slice).
//
// SPEC/ui/trade-screen.md § Market tab — observe-mode chrome parity
// (`#3093` slice).
//
// Issue context (Refs #3093 § Observe mode):
//   "Given `canMutateViaUi == false`, when Trade Market renders,
//    then grouping/icons/prices/stockpile still show and controls do
//    not mutate orders."
//
// The interaction-blocking half of that AC is already pinned by
// `trade_screen_market_tab_e5b_interactive_controls_test.dart`
// (chips + steppers mounted under `IgnorePointer` when
// `canMutateViaUi == false`). This file closes the verification gap
// on the chrome half — none of the existing slice tests assert that
// the `#3093`-era read-only surfaces (sectioned grouping, row icons,
// sellable readout, integer price text) remain mounted under observe
// mode, so a regression that hides the chrome under `IgnorePointer`
// would silently slip through CI.
//
// Pins (one positive AC per `#3093` chrome surface, plus one
// negative AC for the em-dash glyph):
//
//   * Sectioned grouping (Food / Raw Materials / Manufactured)
//     remains mounted — `TradeScreenMarketKeys.marketSectionFoodKey`,
//     `marketSectionRawMaterialsKey`,
//     `marketSectionManufacturedKey` each resolve to exactly one
//     widget when `canMutateViaUi == false`.
//   * Row icons (leading `ResourceIcon` 20 dp + trailing treasury
//     coin 14 dp) remain mounted on every tradeable row when
//     `canMutateViaUi == false` — `marketRowResourceIconKey(c.id)`
//     and `marketRowPriceCoinIconKey(c.id)` resolve to one widget
//     each per tradeable commodity.
//   * Sellable readout `(N)` remains mounted on every tradeable row
//     when `canMutateViaUi == false` — visible text equals the raw
//     stockpile quantity when no offers / reservations exist.
//   * Integer price text remains mounted under observe mode —
//     `worldMarketState.prices == {timber: 30}` renders the literal
//     `30` on the timber row.
//   * Every tradeable row's price column resolves to a finite
//     integer under observe mode — when `worldMarketState.prices`
//     omits a commodity (e.g. `iron`) the catalog default-price
//     fallback (`ResourceRules.defaultMarketPriceForCommodityId`)
//     supplies the row's published integer price (e.g. `iron == 80`)
//     so the em-dash glyph (`_MarketTabContent.priceUnknownGlyph` —
//     `—`) never paints in the price slot per `#3093`
//     (`SPEC/game/world-market.md` § Price discovery — "the catalog
//     default covers every tradeable commodity"). The quantity-idle
//     readout (`marketRowQuantityTextKey` rendering
//     `marketRowQuantityIdleGlyph` — `—` — when no direction is
//     staged) is orthogonal chrome and shares the same literal but
//     is not in scope for this pin.

import 'package:colonizethis_app/config/app_constants.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';

CommodityId get _timber => CommodityCatalog.timber.id;

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab observe-mode chrome parity (Refs #3093)', () {
    testWidgets('sectioned grouping (Food / Raw Materials / Manufactured) '
        'remains mounted when canMutateViaUi == false', (tester) async {
      await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_market_tab_observe_mode_chrome',
          stockpile: tradeableStockpileFilled(99),
        ),
        canMutateViaUi: false,
      );

      final marketTab = find.byKey(TradeScreenMarketKeys.marketTabBodyKey);
      expect(
        marketTab,
        findsOneWidget,
        reason:
            'Refs #3093 observe-mode chrome parity: the Market tab '
            'body must still mount under observe mode — the body is '
            'wrapped in IgnorePointer + Opacity but not removed '
            '(SPEC/ui/trade-screen.md § Body — Observe-mode).',
      );

      for (final Key sectionKey in <Key>[
        TradeScreenMarketKeys.marketSectionFoodKey,
        TradeScreenMarketKeys.marketSectionRawMaterialsKey,
        TradeScreenMarketKeys.marketSectionManufacturedKey,
      ]) {
        expect(
          find.descendant(of: marketTab, matching: find.byKey(sectionKey)),
          findsOneWidget,
          reason:
              'Refs #3093 observe-mode chrome parity: the '
              'sectioned grouping header keyed $sectionKey must '
              'still mount when canMutateViaUi == false — section '
              'labels are read-only chrome that never depends on '
              'the player\'s ability to mutate orders.',
        );
      }
    });

    testWidgets('row icons (leading ResourceIcon 20 dp + trailing treasury '
        'coin 14 dp) remain mounted on every tradeable row when '
        'canMutateViaUi == false', (tester) async {
      await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_market_tab_observe_mode_chrome',
          stockpile: tradeableStockpileFilled(99),
        ),
        canMutateViaUi: false,
      );

      final list = find.byKey(TradeScreenMarketKeys.marketCommodityListKey);
      expect(list, findsOneWidget);

      for (final Commodity c in CommodityCatalog.all) {
        if (c.category == CommodityCategory.riches || c.id == 'spices') {
          continue;
        }
        final iconFinder = find.descendant(
          of: list,
          matching: find.byKey(TradeScreenMarketKeys.marketRowResourceIconKey(c.id)),
        );
        expect(
          iconFinder,
          findsOneWidget,
          reason:
              'Refs #3093 observe-mode chrome parity: tradeable '
              'commodity `${c.id}` must still mount its '
              'ResourceIcon under observe mode — row icons are '
              'decorative chrome that never depends on '
              'canMutateViaUi.',
        );
        final ResourceIcon icon = tester.widget<ResourceIcon>(iconFinder);
        expect(
          icon.size,
          TradeScreenMarketKeys.marketRowResourceIconSize,
          reason:
              'Refs #3093 observe-mode chrome parity: leading '
              'ResourceIcon on row `${c.id}` must paint at 20 dp '
              'regardless of canMutateViaUi.',
        );

        final coinFinder = find.descendant(
          of: list,
          matching: find.byKey(TradeScreenMarketKeys.marketRowPriceCoinIconKey(c.id)),
        );
        expect(
          coinFinder,
          findsOneWidget,
          reason:
              'Refs #3093 observe-mode chrome parity: tradeable '
              'commodity `${c.id}` must still mount its trailing '
              'treasury-coin StrictAssetIcon under observe mode.',
        );
        final StrictAssetIcon coin = tester.widget<StrictAssetIcon>(coinFinder);
        expect(
          coin.assetPath,
          '${kAppIconAssetPrefix}ui_icon_treasury_coin.png',
          reason:
              'Refs #3093 observe-mode chrome parity: trailing '
              'coin glyph on row `${c.id}` must still reuse the '
              'canonical treasury-coin asset under observe mode.',
        );
        expect(coin.width, TradeScreenMarketKeys.marketRowPriceCoinIconSize);
        expect(coin.height, TradeScreenMarketKeys.marketRowPriceCoinIconSize);
      }
    });

    testWidgets('sellable readout `(N)` remains mounted on every tradeable row '
        'when canMutateViaUi == false (N = raw stockpile when no '
        'offers / industry-allocation reservations exist)', (tester) async {
      await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_market_tab_observe_mode_chrome',
          stockpile: tradeableStockpileFilled(99),
        ),
        canMutateViaUi: false,
      );

      final list = find.byKey(TradeScreenMarketKeys.marketCommodityListKey);
      expect(list, findsOneWidget);

      for (final Commodity c in CommodityCatalog.all) {
        if (c.category == CommodityCategory.riches || c.id == 'spices') {
          continue;
}
