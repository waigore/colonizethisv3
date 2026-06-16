// Widget tests for the Market tab price-column alignment slice (Refs #3487).
//
// SPEC/ui/trade-screen.md § Market tab — price column alignment (`#3487` slice).
//
// Pins that coin + price render in a fixed-width trailing column so the
// rightmost digit of each price shares a vertical edge across commodity rows.

import 'package:colonizethis_app/config/app_constants.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/screens/trade_screen.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const Size _kMinViewport = Size(kMinViewportWidth, 640);

Game _buildGame({
  Map<CommodityId, int>? prices,
}) {
  return Game(
    id: 'test_trade_screen_market_tab_price_column',
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
  Size viewport = const Size(800, 900),
}) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(viewport);

  final Player player = game.players.first;
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      ],
      child: MaterialApp(
        theme: AppThemes.editorialMonocle,
        home: MediaQuery(
          data: MediaQueryData(size: viewport),
          child: TradeScreen(game: game, player: player),
        ),
      ),
    ),
  );
  await tester.pump();
}

double _priceTextRight(
  WidgetTester tester,
  CommodityId commodityId,
  String priceText,
) {
  final Finder priceFinder = find.descendant(
    of: find.byKey(TradeScreen.marketCommodityRowKey(commodityId)),
    matching: find.text(priceText),
  );
  expect(priceFinder, findsOneWidget);
  return tester.getTopRight(priceFinder).dx;
}

void main() {
  suppressLogsForTests();

  group('TradeScreen Market tab price column alignment (#3487)', () {
    testWidgets(
      'price right edges share a column across rows with different digit '
      'lengths',
      (tester) async {
        await _pumpTradeScreen(
          tester,
          game: _buildGame(
            prices: const <CommodityId, int>{
              'timber': 5,
              'iron': 220,
            },
          ),
        );

        final double timberPriceRight =
            _priceTextRight(tester, 'timber', '5');
        final double ironPriceRight =
            _priceTextRight(tester, 'iron', '220');

        expect(
          timberPriceRight,
          closeTo(ironPriceRight, 1),
          reason: 'Single-digit and three-digit prices must share the same '
              'right edge (shared price column).',
        );
      },
    );

    testWidgets(
      'price right edge is flush with the row right padding boundary',
      (tester) async {
        await _pumpTradeScreen(
          tester,
          game: _buildGame(
            prices: const <CommodityId, int>{'timber': 30},
          ),
        );

        final double priceRight = _priceTextRight(tester, 'timber', '30');
        final double rowRight = tester
            .getTopRight(find.byKey(TradeScreen.marketCommodityRowKey('timber')))
            .dx;

        expect(
          priceRight,
          closeTo(rowRight, 1),
          reason: 'The price digits must hug the row inner-right edge.',
        );
      },
    );

    testWidgets(
      'coin paints immediately to the left of the price text',
      (tester) async {
        await _pumpTradeScreen(
          tester,
          game: _buildGame(
            prices: const <CommodityId, int>{'timber': 30},
          ),
        );

        final coinFinder = find.descendant(
          of: find.byKey(TradeScreen.marketCommodityRowKey('timber')),
          matching: find.byKey(TradeScreen.marketRowPriceCoinIconKey('timber')),
        );
        final priceFinder = find.descendant(
          of: find.byKey(TradeScreen.marketCommodityRowKey('timber')),
          matching: find.text('30'),
        );

        final coinRect = tester.getRect(coinFinder);
        final priceRect = tester.getRect(priceFinder);

        expect(
          coinRect.right,
          lessThanOrEqualTo(priceRect.left),
          reason: 'Treasury-coin glyph must remain immediately left of price.',
        );
      },
    );

    testWidgets(
      'rows with different name lengths still share the price column edge',
      (tester) async {
        await _pumpTradeScreen(
          tester,
          game: _buildGame(
            prices: const <CommodityId, int>{
              'timber': 30,
              'refinedSugar': 70,
            },
          ),
        );

        final double timberPriceRight =
            _priceTextRight(tester, 'timber', '30');
        final double sugarPriceRight =
            _priceTextRight(tester, 'refinedSugar', '70');

        expect(
          timberPriceRight,
          closeTo(sugarPriceRight, 1),
          reason: 'Short and long commodity names must not stagger the price '
              'column.',
        );
      },
    );

    testWidgets(
      'shared price column holds at kMinViewportWidth (320 dp)',
      (tester) async {
        await _pumpTradeScreen(
          tester,
          game: _buildGame(
            prices: const <CommodityId, int>{
              'grain': 50,
              'timber': 5,
            },
          ),
          viewport: _kMinViewport,
        );

        expect(tester.takeException(), isNull);

        final double grainPriceRight =
            _priceTextRight(tester, 'grain', '50');
        final double timberPriceRight =
            _priceTextRight(tester, 'timber', '5');

        expect(
          grainPriceRight,
          closeTo(timberPriceRight, 1),
          reason: '320 dp viewport must preserve the shared price column.',
        );
      },
    );
  });
}
