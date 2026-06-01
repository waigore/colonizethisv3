// Widget tests for the Market tab row icons slice (Refs #3093 — row-icons).
//
// SPEC/ui/trade-screen.md § Market tab — row icons (`#3093` slice).
//
// Pins the durable contract that every Market row carries:
//
//   * a 20 dp leading [ResourceIcon] keyed
//     `TradeScreen.marketRowResourceIconKey(commodityId)` immediately
//     before the commodity display name on line 1, so each row reads
//     the same commodity glyph as its Production-panel counterpart
//     (`CtResourceCell.leadingIconSize == 20`);
//   * a 14 dp trailing treasury-coin [StrictAssetIcon] keyed
//     `TradeScreen.marketRowPriceCoinIconKey(commodityId)` immediately
//     before the integer price text on line 1, using the same
//     `assets/icons/32/ui_icon_treasury_coin.png` asset family as the
//     game tab bar treasury chip;
//   * the coin glyph is always mounted regardless of whether the row
//     resolves to an integer price or the em-dash fallback (issue
//     #3093 — "prices are never unknown in normal play" — the coin
//     acts as a visual currency cue rather than a price-availability
//     flag);
//   * the existing sellable readout key and price text remain mounted
//     unchanged so the existing E5a / E5b / E5c / sellable-clamp
//     contracts still hold.
//
// Negative coverage:
//
//   * the row icon keys must NOT leak into rows for non-tradeable
//     commodities (riches set, spices) — those rows are not mounted in
//     the Market tab body at all.

import 'package:colonizethis_app/config/app_constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/screens/trade_screen.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/resource_icon.dart';
import 'package:colonizethis_app/widgets/strict_asset_icon.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Builds a synthetic Game with one human player so the Market tab
/// renders without depending on the in-game shell. Mirrors the
/// lightweight Game factory in `trade_screen_market_tab_commodity_table_test.dart`.
Game _buildGame({
  Map<CommodityId, int>? prices,
}) {
  return Game(
    id: 'test_trade_screen_market_tab_row_icons',
    worldState: WorldState(
      turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    turnTimeMapping: TurnTimeMapping.gdd01,
    players: [
      // ignore: avoid_hardcoded_strings_in_widgets
      Player(id: 'gp_h', displayName: 'England', isHuman: true, treasury: 500),
    ],
    diplomacyRelations: const [],
    diplomaticHistoryEvents: const [],
    dossierEvidenceEntries: const [],
    worldMarketState: WorldMarketState(
      prices: prices ?? const <CommodityId, int>{},
      lastTurnActivity: const <CommodityId, MarketActivity>{},
    ),
  );
}

Future<void> _pumpTradeScreen(
  WidgetTester tester, {
  required Game game,
}) async {
  final Player player = game.players.first;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      ],
      child: MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: TradeScreen(game: game, player: player),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab row icons (Refs #3093)', () {
    testWidgets(
      'every tradeable row mounts a 20 dp ResourceIcon keyed '
      'marketRowResourceIconKey under the marketCommodityListKey',
      (tester) async {
        await _pumpTradeScreen(tester, game: _buildGame());

        final list = find.byKey(TradeScreen.marketCommodityListKey);
        expect(list, findsOneWidget);

        final List<Commodity> tradeable = <Commodity>[
          for (final Commodity c in CommodityCatalog.all)
            if (c.category != CommodityCategory.riches && c.id != 'spices') c,
        ];
        expect(
          tradeable.length,
          22,
          reason:
              'SPEC/game/world-market.md §Tradeable commodities — '
              'must be 22 rows; if this drifts, the row-icons slice '
              'pin must also be updated.',
        );

        for (final Commodity c in tradeable) {
          final iconFinder = find.descendant(
            of: list,
            matching: find.byKey(TradeScreen.marketRowResourceIconKey(c.id)),
          );
          expect(
            iconFinder,
            findsOneWidget,
            reason:
                'tradeable commodity `${c.id}` must mount its '
                'ResourceIcon keyed '
                'tradeScreenMarketRow:${c.id}:resourceIcon.',
          );

          // The keyed widget must be a ResourceIcon (not just any
          // widget under the key) so screen-reader and analyzer tooling
          // can rely on the type contract.
          final ResourceIcon icon = tester.widget<ResourceIcon>(iconFinder);
          expect(
            icon.commodityId,
            c.id,
            reason:
                'ResourceIcon on the row for `${c.id}` must carry the '
                'matching commodityId so the asset paint matches the '
                'row label.',
          );
          expect(
            icon.size,
            TradeScreen.marketRowResourceIconSize,
            reason:
                'ResourceIcon on the Trade row must paint at 20 dp '
                '(TradeScreen.marketRowResourceIconSize) — matches the '
                'Production panel `CtResourceCell.leadingIconSize`.',
          );
        }
      },
    );

    testWidgets(
      'every tradeable row mounts a 14 dp treasury-coin StrictAssetIcon '
      'keyed marketRowPriceCoinIconKey under the marketCommodityListKey',
      (tester) async {
        await _pumpTradeScreen(
          tester,
          // Mix priced (timber=30) and unpriced (no entry) commodities
          // to prove the coin glyph mounts in both cases — it is a
          // visual currency cue, not a price-availability flag.
          game: _buildGame(
            prices: const <CommodityId, int>{'timber': 30},
          ),
        );

        final list = find.byKey(TradeScreen.marketCommodityListKey);
        expect(list, findsOneWidget);

        final List<Commodity> tradeable = <Commodity>[
          for (final Commodity c in CommodityCatalog.all)
            if (c.category != CommodityCategory.riches && c.id != 'spices') c,
        ];

        for (final Commodity c in tradeable) {
          final coinFinder = find.descendant(
            of: list,
            matching: find.byKey(TradeScreen.marketRowPriceCoinIconKey(c.id)),
          );
          expect(
            coinFinder,
            findsOneWidget,
            reason:
                'tradeable commodity `${c.id}` must mount its '
                'treasury-coin StrictAssetIcon keyed '
                'tradeScreenMarketRow:${c.id}:priceCoin regardless of '
                'whether the row resolves to an integer price or the '
                'em-dash fallback.',
          );

          final StrictAssetIcon coin =
              tester.widget<StrictAssetIcon>(coinFinder);
          expect(
            coin.assetPath,
            '${kAppIconAssetPrefix}ui_icon_treasury_coin.png',
            reason:
                'Trade row coin must reuse the canonical '
                'ui_icon_treasury_coin.png asset (same family as the '
                'game tab bar treasury chip).',
          );
          expect(coin.width, TradeScreen.marketRowPriceCoinIconSize);
          expect(coin.height, TradeScreen.marketRowPriceCoinIconSize);
        }
      },
    );

    testWidgets(
      'on the timber row (price = 30), the ResourceIcon paints to the '
      'left of the commodity name and the coin paints to the left of '
      'the integer price text',
      (tester) async {
        await _pumpTradeScreen(
          tester,
          game: _buildGame(
            prices: const <CommodityId, int>{'timber': 30},
          ),
        );

        final iconRect = tester.getRect(
          find.byKey(TradeScreen.marketRowResourceIconKey('timber')),
        );
        // ignore: avoid_hardcoded_strings_in_widgets
        final nameRect = tester.getRect(find.text('Timber'));
        final coinRect = tester.getRect(
          find.byKey(TradeScreen.marketRowPriceCoinIconKey('timber')),
        );
        // ignore: avoid_hardcoded_strings_in_widgets
        final priceRect = tester.getRect(find.text('30'));

        expect(
          iconRect.right,
          lessThanOrEqualTo(nameRect.left),
          reason:
              'Leading ResourceIcon must paint to the left of the '
              'commodity display name on line 1.',
        );
        expect(
          coinRect.right,
          lessThanOrEqualTo(priceRect.left),
          reason:
              'Trailing treasury-coin glyph must paint immediately to '
              'the left of the integer price text on line 1.',
        );

        // The ResourceIcon's painted side length must equal the SPEC
        // constant (20 dp) so a future refactor that swaps the size
        // away from CtResourceCell.leadingIconSize trips this pin.
        expect(iconRect.width, TradeScreen.marketRowResourceIconSize);
        expect(iconRect.height, TradeScreen.marketRowResourceIconSize);
        expect(coinRect.width, TradeScreen.marketRowPriceCoinIconSize);
        expect(coinRect.height, TradeScreen.marketRowPriceCoinIconSize);
      },
    );

    testWidgets(
      'row icon keys never leak into rows for excluded commodities '
      '(negative AC: no ResourceIcon / coin keys for gold, silver, '
      'gems, diamonds, spices)',
      (tester) async {
        await _pumpTradeScreen(tester, game: _buildGame());

        for (final CommodityId excluded in <CommodityId>[
          CommodityCatalog.gold.id,
          CommodityCatalog.silver.id,
          CommodityCatalog.gems.id,
          CommodityCatalog.diamonds.id,
          CommodityCatalog.spices.id,
        ]) {
          expect(
            find.byKey(TradeScreen.marketRowResourceIconKey(excluded)),
            findsNothing,
            reason:
                'SPEC/game/world-market.md §Tradeable commodities — '
                '`$excluded` is not tradeable and must not mount its '
                'row ResourceIcon.',
          );
          expect(
            find.byKey(TradeScreen.marketRowPriceCoinIconKey(excluded)),
            findsNothing,
            reason:
                'SPEC/game/world-market.md §Tradeable commodities — '
                '`$excluded` is not tradeable and must not mount its '
                'row treasury-coin glyph.',
          );
        }
      },
    );
  });
}
