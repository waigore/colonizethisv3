// Widget goldens for the Trade Market tab wide two-column + compact rows
// (Refs #4227). Pixel baselines under `app/test/goldens/` close the
// verify-github-issue UI proof gap flagged on issue #4227.
//
// Golden mapping:
//  - AC-1/AC-2  wide row-major two-column grid + compact two-line rows
//  - AC-3       narrow single-column two-line stacked rows
//
// SPEC: SPEC/ui/trade-screen.md § Market tab — wide two-column layout.

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

import 'package:colonizethis_app/config/constants.dart';

import 'golden_capture_harness.dart';
import 'trade_screen_test_support.dart';

const String _humanPlayerId = kTradeTestHumanPlayerId;

/// Stable prices for deterministic golden pixels across commodities.
Map<CommodityId, int> _tradeMarketGoldenPrices() {
  return <CommodityId, int>{
    CommodityCatalog.grain.id: 8,
    CommodityCatalog.meat.id: 12,
    CommodityCatalog.timber.id: 40,
    CommodityCatalog.iron.id: 80,
    CommodityCatalog.lumber.id: 60,
    CommodityCatalog.fabric.id: 70,
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

  group('TradeScreen Market tab wide layout goldens (Refs #4227)', () {
    testWidgets(
      'golden: wide two-column compact food section (AC-1/AC-2)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeMarketWideTwoColumnGolden',
        );

        await _pumpMarketTabGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(
            prices: _tradeMarketGoldenPrices(),
            lastTurnActivity: <CommodityId, MarketActivity>{
              CommodityCatalog.grain.id: const MarketActivity(
                totalBidQuantity: 4,
                totalOfferQuantity: 2,
              ),
              CommodityCatalog.meat.id: const MarketActivity(
                totalBidQuantity: 1,
                totalOfferQuantity: 6,
              ),
            },
          ),
          viewport: const Size(800, 360),
        );

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(TradeScreenMarketKeys.marketSectionFoodKey),
          findsOneWidget,
        );
        expect(
          find.byKey(TradeScreenMarketKeys.marketCommodityRowKey('grain')),
          findsOneWidget,
        );
        expect(
          find.byKey(TradeScreenMarketKeys.marketCommodityRowKey('meat')),
          findsOneWidget,
        );

        final Offset grainOffset = tester.getTopLeft(
          find.byKey(TradeScreenMarketKeys.marketCommodityRowKey('grain')),
        );
        final Offset meatOffset = tester.getTopLeft(
          find.byKey(TradeScreenMarketKeys.marketCommodityRowKey('meat')),
        );
        expect(meatOffset.dx, greaterThan(grainOffset.dx));
        expect(meatOffset.dy, grainOffset.dy);

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile('goldens/trade_market_wide_two_column.png'),
        );
      },
    );

    testWidgets(
      'golden: narrow stacked two-line rows (AC-3)',
      (WidgetTester tester) async {
        const boundaryKey = ValueKey<String>(
          'tradeMarketNarrowStackedGolden',
        );

        await _pumpMarketTabGolden(
          tester,
          boundaryKey: boundaryKey,
          game: buildTradeTestGame(
            prices: _tradeMarketGoldenPrices(),
          ),
          viewport: Size(kNarrowBreakpoint - 1, 420),
        );

        expect(tester.takeException(), isNull);
        expect(
          find.byKey(TradeScreenMarketKeys.marketCommodityRowKey('grain')),
          findsOneWidget,
        );

        final Offset grainOffset = tester.getTopLeft(
          find.byKey(TradeScreenMarketKeys.marketCommodityRowKey('grain')),
        );
        final Offset meatOffset = tester.getTopLeft(
          find.byKey(TradeScreenMarketKeys.marketCommodityRowKey('meat')),
        );
        expect(meatOffset.dy, greaterThan(grainOffset.dy));

        await expectLater(
          find.byKey(boundaryKey),
          matchesGoldenFile('goldens/trade_market_narrow_stacked.png'),
        );
      },
    );
  });
}
