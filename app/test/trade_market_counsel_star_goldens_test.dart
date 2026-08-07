// Widget goldens for Trade Market counsel stars (Refs #4282).
//
// Golden mapping:
//  - AC stars: commodity row shows ★ when trade counsel highlights the line
//
// SPEC: SPEC/ui/trade-screen.md § Market tab — counsel stars.

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

Map<CommodityId, int> _tradeCounselStarGoldenPrices() {
  return <CommodityId, int>{
    CommodityCatalog.timber.id: 40,
    CommodityCatalog.fabric.id: 70,
    CommodityCatalog.grain.id: 8,
  };
}

void main() {
  suppressLogsForTests();

  testWidgets(
    'golden: market row shows trade counsel star for highlighted commodity '
    '(Refs #4282)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('tradeMarketCounselStarGolden');
      final Game game = buildTradeTestGame(
        prices: _tradeCounselStarGoldenPrices(),
        stockpile: <CommodityId, int>{
          CommodityCatalog.timber.id: 80,
        },
      );
      final Player player = game.players.firstWhere(
        (Player p) => p.id == _humanPlayerId,
      );

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(480, 220),
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
          width: 480,
          height: 220,
          child: MarketTabContent(
            game: game,
            playerId: _humanPlayerId,
            canEdit: true,
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('trade_market_counsel_star')),
        findsWidgets,
      );
      expect(
        find.byKey(TradeScreenMarketKeys.marketCommodityRowKey('timber')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/trade_market_counsel_star_row.png'),
      );
    },
  );
}
