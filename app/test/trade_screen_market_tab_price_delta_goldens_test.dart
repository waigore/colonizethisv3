// Widget goldens for Market last-turn price-move deltas (Refs #4345).
// Pixel baselines under `app/test/goldens/` close the verify-github-issue
// UI proof gap (AC1 success +£N / AC2 danger −£N).
//
// SPEC: SPEC/ui/trade-screen.md § Market tab — last-turn price move.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen_market_tab.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'trade_screen_test_support.dart';

const String _humanPlayerId = kTradeTestHumanPlayerId;

Map<CommodityId, int> _deltaGoldenPrices() {
  return <CommodityId, int>{
    CommodityCatalog.grain.id: 8,
    CommodityCatalog.timber.id: 36,
    CommodityCatalog.iron.id: 30,
  };
}

Future<void> _pumpMarketTabGolden(
  WidgetTester tester, {
  required Key boundaryKey,
  required Game game,
  required Size viewport,
}) async {
  final Player player = game.players.firstWhere(
    (Player p) => p.id == _humanPlayerId,
  );

  await pumpGoldenHost(
    tester,
    boundaryKey: boundaryKey,
    physicalSize: viewport,
    center: false,
    includeLocalizations: true,
    wrapInProviderScope: true,
    overrides: <Override>[
      currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      shellPlayerContextProvider.overrideWith(
        (Ref ref) => tradeTestShellPlayerContext(player: player),
      ),
    ],
    child: SizedBox(
      width: viewport.width,
      height: viewport.height,
      child: MarketTabContent(
        game: game,
        playerId: _humanPlayerId,
        canEdit: true,
      ),
    ),
  );
}

void main() {
  suppressLogsForTests();

  group('TradeScreen Market last-turn price-delta goldens (Refs #4345)', () {
    testWidgets(
      'golden: timber row shows success +£N (AC1)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeMarketTimberPriceDeltaUpGolden',
        );

        await _pumpMarketTabGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(
            prices: _deltaGoldenPrices(),
            lastTurnActivity: <CommodityId, MarketActivity>{
              CommodityCatalog.timber.id: const MarketActivity(
                totalBidQuantity: 2,
                totalOfferQuantity: 1,
                priceChangePercent: 0.2,
              ),
            },
          ),
          viewport: const Size(480, 720),
        );

        final Finder timberRow = find.byKey(
          TradeScreenMarketKeys.marketCommodityRowKey('timber'),
        );
        await tester.scrollUntilVisible(
          timberRow,
          80,
          scrollable: find.byType(Scrollable).first,
        );
        await pumpForGolden(tester);

        expect(tester.takeException(), isNull);
        expect(timberRow, findsOneWidget);
        expect(find.text('+£6'), findsOneWidget);
        expect(
          find.byKey(
            TradeScreenMarketKeys.marketRowPriceDeltaKey(
              CommodityCatalog.timber.id,
            ),
          ),
          findsOneWidget,
        );

        await expectLater(
          timberRow,
          matchesGoldenFile('goldens/trade_market_timber_price_delta_up.png'),
        );
      },
    );

    testWidgets(
      'golden: iron row shows danger −£N unicode minus (AC2)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeMarketIronPriceDeltaDownGolden',
        );
        final double fallPercent = (30 / 33) - 1.0;

        await _pumpMarketTabGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(
            prices: _deltaGoldenPrices(),
            lastTurnActivity: <CommodityId, MarketActivity>{
              CommodityCatalog.iron.id: MarketActivity(
                totalBidQuantity: 1,
                totalOfferQuantity: 3,
                priceChangePercent: fallPercent,
              ),
            },
          ),
          viewport: const Size(480, 720),
        );

        final Finder ironRow = find.byKey(
          TradeScreenMarketKeys.marketCommodityRowKey('iron'),
        );
        await tester.scrollUntilVisible(
          ironRow,
          80,
          scrollable: find.byType(Scrollable).first,
        );
        await pumpForGolden(tester);

        expect(tester.takeException(), isNull);
        expect(ironRow, findsOneWidget);
        expect(find.text('\u2212£3'), findsOneWidget);
        expect(
          find.byKey(
            TradeScreenMarketKeys.marketRowPriceDeltaKey(
              CommodityCatalog.iron.id,
            ),
          ),
          findsOneWidget,
        );

        await expectLater(
          ironRow,
          matchesGoldenFile('goldens/trade_market_iron_price_delta_down.png'),
        );
      },
    );
  });
}
