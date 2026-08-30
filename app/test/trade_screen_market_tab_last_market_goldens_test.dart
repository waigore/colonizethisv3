// Widget goldens for Market Last market chip (Refs #4653).
// Pixel baselines under `app/test/goldens/`.
//
// SPEC: SPEC/ui/trade-screen.md § Market tab — last market chip.

import 'package:colonizethis_app/config/constants.dart';
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

  group('TradeScreen Market Last market goldens (Refs #4653)', () {
    testWidgets('golden: timber Last market chip vs fabric zero-activity row', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('tradeMarketLastMarketChipGolden');

      await _pumpMarketTabGolden(
        tester,
        boundaryKey: boundaryKey,
        game: buildTradeTestGame(
          lastTurnActivity: const <CommodityId, MarketActivity>{
            'timber': MarketActivity(
              totalBidQuantity: 12,
              totalOfferQuantity: 8,
            ),
          },
        ),
        viewport: const Size(360, 720),
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
      expect(
        find.byKey(TradeScreenMarketKeys.marketRowLastMarketChipKey('timber')),
        findsOneWidget,
      );
      expect(
        find.byKey(TradeScreenMarketKeys.marketRowLastMarketChipKey('fabric')),
        findsNothing,
      );

      await expectLater(
        timberRow,
        matchesGoldenFile('goldens/trade_market_timber_last_market_chip.png'),
      );
    });

    testWidgets('golden: 320 dp wrap keeps Bid/Offer/quantity unclipped', (
      WidgetTester tester,
    ) async {
      const boundaryKey = ValueKey<String>('tradeMarketLastMarketNarrowGolden');

      await _pumpMarketTabGolden(
        tester,
        boundaryKey: boundaryKey,
        game: buildTradeTestGame(
          lastTurnActivity: const <CommodityId, MarketActivity>{
            'timber': MarketActivity(
              totalBidQuantity: 12,
              totalOfferQuantity: 8,
            ),
          },
        ),
        viewport: const Size(kMinViewportWidth, 640),
      );

      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/trade_market_last_market_narrow_320.png'),
      );
    });
  });
}
