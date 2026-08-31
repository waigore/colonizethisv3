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
        final sellableFinder = find.descendant(
          of: list,
          matching: find.byKey(TradeScreenMarketKeys.marketRowSellableReadoutKey(c.id)),
        );
        expect(
          sellableFinder,
          findsOneWidget,
          reason:
              'Refs #3093 observe-mode chrome parity: the sellable '
              'readout for tradeable commodity `${c.id}` must '
              'still mount under observe mode — the readout '
              'reflects the player\'s stockpile / reservation '
              'state regardless of canMutateViaUi.',
        );
        final Text sellable = tester.widget<Text>(sellableFinder);
        expect(
          sellable.data,
          // ignore: avoid_hardcoded_strings_in_widgets
          '(99)',
          reason:
              'Refs #3093 observe-mode chrome parity: with raw '
              'stockpile 99, no staged offers, and no '
              'industry-allocation reservations, the sellable '
              'readout for `${c.id}` must render the literal '
              '`(99)` under observe mode.',
        );
      }
    });

    testWidgets('integer price text remains mounted under observe mode — '
        'worldMarketState.prices == {timber: 30} renders the literal '
        '`30` on the timber row', (tester) async {
      await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_market_tab_observe_mode_chrome',
          stockpile: tradeableStockpileFilled(99),
          prices: const <CommodityId, int>{'timber': 30},
        ),
        canMutateViaUi: false,
      );

      final timberRow = find.byKey(TradeScreenMarketKeys.marketCommodityRowKey(_timber));
      expect(timberRow, findsOneWidget);
      expect(
        find.descendant(
          of: timberRow,
          // ignore: avoid_hardcoded_strings_in_widgets
          matching: find.text('30'),
        ),
        findsOneWidget,
        reason:
            'Refs #3093 observe-mode chrome parity: the integer '
            'price text rendered by `_formatPrice` must still '
            'mount under observe mode — integer-price chrome is '
            'read-only and never depends on canMutateViaUi.',
      );
    });

    testWidgets('catalog default-price fallback resolves under observe mode — '
        'iron row (price absent from worldMarketState.prices) renders '
        'the integer catalog default `80` immediately to the right of '
        'the row treasury-coin glyph (no em-dash in the price slot)', (
      tester,
    ) async {
      // worldMarketState.prices is intentionally empty here so the
      // row must fall back to ResourceRules.defaultMarketPriceForCommodityId
      // for every tradeable commodity. The negative pin uses iron
      // (catalog default = 80 per ResourceRules.defaultRules) so a
      // regression that drops the catalog fallback under observe
      // mode surfaces as the em-dash glyph appearing in the price
      // slot instead of the integer literal `80`.
      await pumpTradeScreenWithContainer(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_market_tab_observe_mode_chrome',
          stockpile: tradeableStockpileFilled(99),
        ),
        canMutateViaUi: false,
      );

      final ironRow = find.byKey(
        TradeScreenMarketKeys.marketCommodityRowKey(CommodityCatalog.iron.id),
      );
      expect(ironRow, findsOneWidget);

      expect(
        find.descendant(
          of: ironRow,
          // ignore: avoid_hardcoded_strings_in_widgets
          matching: find.text('80'),
        ),
        findsOneWidget,
        reason:
            'Refs #3093 observe-mode chrome parity: with '
            'worldMarketState.prices empty, the iron row must '
            'still render the published catalog default price `80` '
            'under observe mode (ResourceRules.defaultRules '
            'covers every tradeable commodity per '
            'SPEC/game/world-market.md § Price discovery). The '
            'em-dash glyph must never paint in the price slot.',
      );

      // The coin glyph mounts to the immediate left of the price
      // text, so pinning the spatial relationship under observe
      // mode guards against a regression that hides the coin or
      // the integer price specifically on the observed surface.
      final coinRect = tester.getRect(
        find.byKey(
          TradeScreenMarketKeys.marketRowPriceCoinIconKey(CommodityCatalog.iron.id),
        ),
      );
      final priceRect = tester.getRect(
        find.descendant(
          of: ironRow,
          // ignore: avoid_hardcoded_strings_in_widgets
          matching: find.text('80'),
        ),
      );
      expect(
        coinRect.right,
        lessThanOrEqualTo(priceRect.left),
        reason:
            'Refs #3093 observe-mode chrome parity: the trailing '
            'treasury-coin glyph must still paint immediately to '
            'the left of the integer price text under observe '
            'mode (Refs #3093 § Market tab — row icons).',
      );
    });
  });
}
