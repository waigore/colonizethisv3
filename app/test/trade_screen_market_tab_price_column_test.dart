// Widget tests for the Market tab price-column alignment slice (Refs #3487).
//
// SPEC/ui/trade-screen.md § Market tab — price column alignment (`#3487` slice).
//
// Pins that coin + price render in a fixed-width trailing column so the
// rightmost digit of each price shares a vertical edge across commodity rows.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/trade_screen_test_support.dart';

const Size _kMinViewport = Size(kMinViewportWidth, 640);

double _priceTextRight(
  WidgetTester tester,
  CommodityId commodityId,
  String priceText,
) {
  final Finder priceFinder = find.descendant(
    of: _trailingPriceRowFinder(commodityId),
    matching: find.text(priceText),
  );
  expect(priceFinder, findsOneWidget);
  return tester.getTopRight(priceFinder).dx;
}

Finder _trailingPriceRowFinder(CommodityId commodityId) {
  final Finder coinFinder = find.byKey(
    TradeScreenMarketKeys.marketRowPriceCoinIconKey(commodityId),
  );
  return find.ancestor(
    of: coinFinder,
    matching: find.byWidgetPredicate(
      (Widget widget) =>
          widget is Row && widget.mainAxisSize == MainAxisSize.min,
    ),
  );
}

/// Empty [ResourceRules] so `_formatPrice` can render the em-dash fallback
/// for commodities absent from `worldMarketState.prices` (Refs #3487 AC4).
ResourceRules _emptyMarketPriceRules() {
  return ResourceRules(
    regionRule: const <Resource, ResourceRegionRule>{},
    allowedTerrains: const <Resource, List<TerrainType>>{},
    defaultMarketPrice: const <Resource, int>{},
  );
}

void main() {
  suppressLogsForTests();

  tearDown(() {
    TradeScreenMarketKeys.marketPriceResourceRulesOverride = null;
  });

  group('TradeScreen Market tab price column alignment (#3487)', () {
    testWidgets(
      'price right edges share a column across rows with different digit '
      'lengths',
      (tester) async {
        await pumpTradeScreen(
          tester,
          game: buildTradeTestGame(
            id: 'test_trade_screen_market_tab_price_column',
            prices: const <CommodityId, int>{'timber': 5, 'iron': 220},
          ),
        );

        final double timberPriceRight = _priceTextRight(tester, 'timber', '5');
        final double ironPriceRight = _priceTextRight(tester, 'iron', '220');

        expect(
          timberPriceRight,
          closeTo(ironPriceRight, 1),
          reason:
              'Single-digit and three-digit prices must share the same '
              'right edge (shared price column).',
        );
      },
    );

    testWidgets(
      'price right edge is flush with the row right padding boundary',
      (tester) async {
        await pumpTradeScreen(
          tester,
          game: buildTradeTestGame(
            id: 'test_trade_screen_market_tab_price_column',
            prices: const <CommodityId, int>{'timber': 30},
          ),
        );

        final double priceRight = _priceTextRight(tester, 'timber', '30');
        final double rowRight = tester
            .getTopRight(
              find.byKey(TradeScreenMarketKeys.marketCommodityRowKey('timber')),
            )
            .dx;

        expect(
          priceRight,
          closeTo(rowRight, 1),
          reason: 'The price digits must hug the row inner-right edge.',
        );
      },
    );

    testWidgets('coin paints immediately to the left of the price text', (
      tester,
    ) async {
      await pumpTradeScreen(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_market_tab_price_column',
          prices: const <CommodityId, int>{'timber': 30},
        ),
      );

      final coinFinder = find.descendant(
        of: find.byKey(TradeScreenMarketKeys.marketCommodityRowKey('timber')),
        matching: find.byKey(TradeScreenMarketKeys.marketRowPriceCoinIconKey('timber')),
      );
      final priceFinder = find.descendant(
        of: find.byKey(TradeScreenMarketKeys.marketCommodityRowKey('timber')),
        matching: find.text('30'),
      );

      final coinRect = tester.getRect(coinFinder);
      final priceRect = tester.getRect(priceFinder);

      expect(
        coinRect.right,
        lessThanOrEqualTo(priceRect.left),
        reason: 'Treasury-coin glyph must remain immediately left of price.',
      );
    });

    testWidgets(
      'rows with different name lengths still share the price column edge',
      (tester) async {
        await pumpTradeScreen(
          tester,
          game: buildTradeTestGame(
            id: 'test_trade_screen_market_tab_price_column',
            prices: const <CommodityId, int>{'timber': 30, 'refinedSugar': 70},
          ),
        );

        final double timberPriceRight = _priceTextRight(tester, 'timber', '30');
        final double sugarPriceRight = _priceTextRight(
          tester,
          'refinedSugar',
          '70',
        );

        expect(
          timberPriceRight,
          closeTo(sugarPriceRight, 1),
          reason:
              'Short and long commodity names must not stagger the price '
              'column.',
        );
      },
    );

    testWidgets(
      'em-dash price fallback shares the trailing column with integer '
      'prices',
      (tester) async {
        TradeScreenMarketKeys.marketPriceResourceRulesOverride = _emptyMarketPriceRules();

        await pumpTradeScreen(
          tester,
          game: buildTradeTestGame(
            id: 'test_trade_screen_market_tab_price_column',
            prices: const <CommodityId, int>{'timber': 5},
          ),
        );

        final double integerPriceRight = _priceTextRight(tester, 'timber', '5');
        final double emDashPriceRight = _priceTextRight(
          tester,
          'iron',
          // ignore: avoid_hardcoded_strings_in_widgets
          '—',
        );

        expect(
          emDashPriceRight,
          closeTo(integerPriceRight, 1),
          reason:
              'Em-dash fallback must right-align in the same column as '
              'integer prices.',
        );

        final coinFinder = find.descendant(
          of: find.byKey(TradeScreenMarketKeys.marketCommodityRowKey('iron')),
          matching: find.byKey(TradeScreenMarketKeys.marketRowPriceCoinIconKey('iron')),
        );
        expect(
          coinFinder,
          findsOneWidget,
          reason: 'Treasury-coin glyph must remain mounted for em-dash rows.',
        );
      },
    );

    testWidgets('shared price column holds at kMinViewportWidth (320 dp)', (
      tester,
    ) async {
      await pumpTradeScreen(
        tester,
        game: buildTradeTestGame(
          id: 'test_trade_screen_market_tab_price_column',
          prices: const <CommodityId, int>{'grain': 50, 'timber': 5},
        ),
        viewport: _kMinViewport,
      );

      expect(tester.takeException(), isNull);

      final double grainPriceRight = _priceTextRight(tester, 'grain', '50');
      final double timberPriceRight = _priceTextRight(tester, 'timber', '5');

      expect(
        grainPriceRight,
        closeTo(timberPriceRight, 1),
        reason: '320 dp viewport must preserve the shared price column.',
      );
    });
  });
}
