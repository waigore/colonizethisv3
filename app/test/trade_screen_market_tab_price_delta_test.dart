// Widget + unit tests for Market last-turn price move (Refs #4345).
// SPEC/ui/trade-screen.md § Market tab — last-turn price move.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen_market_price_delta.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'trade_screen_test_support.dart';

void main() {
  suppressLogsForTests();

  group('marketPriceDeltaCoins helper (#4345)', () {
    test('positive percent reconstructs success delta', () {
      // 30 → 36 with percent 0.2
      expect(
        marketPriceDeltaCoins(currentPrice: 36, priceChangePercent: 0.2),
        6,
      );
      expect(formatMarketPriceDelta(6), '+£6');
    });

    test('negative percent reconstructs danger delta with unicode minus', () {
      // 33 → 30 with percent ≈ −0.0909… from integer prices 30/33−1
      final double percent = (30 / 33) - 1.0;
      expect(
        marketPriceDeltaCoins(currentPrice: 30, priceChangePercent: percent),
        -3,
      );
      expect(formatMarketPriceDelta(-3), '\u2212£3');
    });

    test('omits when percent is zero, missing price, or delta rounds to 0', () {
      expect(
        marketPriceDeltaCoins(currentPrice: 30, priceChangePercent: 0),
        isNull,
      );
      expect(
        marketPriceDeltaCoins(currentPrice: null, priceChangePercent: 0.2),
        isNull,
      );
      expect(
        marketPriceDeltaCoins(currentPrice: 30, priceChangePercent: -1.0),
        isNull,
      );
    });
  });

  group('TradeScreen Market last-turn price move (#4345)', () {
    testWidgets(
      'shows success +£N when last-turn percent reconstructs a rise',
      (tester) async {
        await pumpTradeScreen(
          tester,
          game: buildTradeTestGame(
            prices: const <CommodityId, int>{'timber': 36},
            lastTurnActivity: const <CommodityId, MarketActivity>{
              'timber': MarketActivity(priceChangePercent: 0.2),
            },
          ),
          viewport: const Size(400, 4096),
        );

        final Finder delta = find.byKey(
          TradeScreenMarketKeys.marketRowPriceDeltaKey(
            CommodityCatalog.timber.id,
          ),
        );
        expect(delta, findsOneWidget);
        expect(find.text('+£6'), findsOneWidget);
        final Text widget = tester.widget<Text>(delta);
        expect(widget.style?.color, EditorialMonoclePalette.success);
        expect(find.textContaining('%'), findsNothing);
      },
    );

    testWidgets(
      'shows danger −£N (unicode minus) when last-turn percent falls',
      (tester) async {
        final double percent = (30 / 33) - 1.0;
        await pumpTradeScreen(
          tester,
          game: buildTradeTestGame(
            prices: const <CommodityId, int>{'timber': 30},
            lastTurnActivity: <CommodityId, MarketActivity>{
              'timber': MarketActivity(priceChangePercent: percent),
            },
          ),
          viewport: const Size(400, 4096),
        );

        final Finder delta = find.byKey(
          TradeScreenMarketKeys.marketRowPriceDeltaKey(
            CommodityCatalog.timber.id,
          ),
        );
        expect(delta, findsOneWidget);
        expect(find.text('\u2212£3'), findsOneWidget);
        final Text widget = tester.widget<Text>(delta);
        expect(widget.style?.color, EditorialMonoclePalette.danger);
      },
    );

    testWidgets(
      'omits delta when activity missing or percent zero',
      (tester) async {
        await pumpTradeScreen(
          tester,
          game: buildTradeTestGame(
            prices: const <CommodityId, int>{'timber': 30, 'iron': 80},
            lastTurnActivity: const <CommodityId, MarketActivity>{
              'iron': MarketActivity(priceChangePercent: 0),
            },
          ),
          viewport: const Size(400, 4096),
        );

        expect(
          find.byKey(
            TradeScreenMarketKeys.marketRowPriceDeltaKey(
              CommodityCatalog.timber.id,
            ),
          ),
          findsNothing,
        );
        expect(
          find.byKey(
            TradeScreenMarketKeys.marketRowPriceDeltaKey(
              CommodityCatalog.iron.id,
            ),
          ),
          findsNothing,
        );
      },
    );

    testWidgets(
      'price cluster tooltip explains last market move and this-turn clear',
      (tester) async {
        await pumpTradeScreen(
          tester,
          game: buildTradeTestGame(
            prices: const <CommodityId, int>{'timber': 36},
            lastTurnActivity: const <CommodityId, MarketActivity>{
              'timber': MarketActivity(priceChangePercent: 0.2),
            },
          ),
          viewport: const Size(400, 4096),
        );

        final Finder delta = find.byKey(
          TradeScreenMarketKeys.marketRowPriceDeltaKey(
            CommodityCatalog.timber.id,
          ),
        );
        final Tooltip tip = tester.widget<Tooltip>(
          find.ancestor(of: delta, matching: find.byType(Tooltip)).first,
        );
        expect(
          tip.message,
          "Last market moved this price. This turn's deals use the price shown.",
        );
      },
    );

    testWidgets(
      'delta and last-turn volume still render in observe / read-only mode',
      (tester) async {
        await pumpTradeScreen(
          tester,
          game: buildTradeTestGame(
            prices: const <CommodityId, int>{'timber': 36},
            lastTurnActivity: const <CommodityId, MarketActivity>{
              'timber': MarketActivity(
                totalBidQuantity: 4,
                totalOfferQuantity: 2,
                priceChangePercent: 0.2,
              ),
            },
          ),
          canMutateViaUi: false,
          viewport: const Size(400, 4096),
        );

        expect(find.text('+£6'), findsOneWidget);
        expect(find.text('Last turn: bids 4 · offers 2'), findsOneWidget);
      },
    );

    testWidgets(
      '320 dp and wide two-column layouts keep coin price visible with delta',
      (tester) async {
        final Game game = buildTradeTestGame(
          prices: const <CommodityId, int>{'timber': 36},
          lastTurnActivity: const <CommodityId, MarketActivity>{
            'timber': MarketActivity(priceChangePercent: 0.2),
          },
        );

        await pumpTradeScreen(
          tester,
          game: game,
          viewport: const Size(kMinViewportWidth, 640),
        );
        expect(tester.takeException(), isNull);
        expect(find.text('36'), findsWidgets);
        expect(find.text('+£6'), findsOneWidget);

        await pumpTradeScreen(
          tester,
          game: game,
          viewport: const Size(700, 4096),
        );
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(
            TradeScreenMarketKeys.marketRowPriceDeltaKey(
              CommodityCatalog.timber.id,
            ),
          ),
          findsOneWidget,
        );
      },
    );
  });
}
