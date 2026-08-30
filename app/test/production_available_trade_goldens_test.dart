// Goldens for Production Available Trade affordance and Trade highlight. Refs #4581.

import 'package:colonizethis_app/features/game/screens/trade/trade_screen.dart';
import 'package:colonizethis_app/features/game/screens/trade/trade_screen_market_row_highlight.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_available_trade_cell.dart';
import 'package:colonizethis_app/features/game/widgets/production/production_panel.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'golden_capture_harness.dart';
import 'production_panel_test_support.dart';
import 'trade_screen_test_support.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  testWidgets('golden: tappable Available tradeable cells at 360×640 (#4581)', (
    WidgetTester tester,
  ) async {
    final player = productionPanelTestFullPlayer();
    final game = productionPanelTestGameFor(player);
    const boundaryKey = ValueKey('production_available_opens_trade_golden');

    await pumpGoldenHost(
      tester,
      boundaryKey: boundaryKey,
      physicalSize: const Size(360, 640),
      includeLocalizations: true,
      child: ProductionPanel(
        game: game,
        player: player,
        desiredOutputByRecipe: const {},
        netDeltasByCommodity: const {},
        labourReadiness: labourReadinessForPlayer(player),
        forcesFeeding: forcesFeedingForPlayer(player),
        onDesiredOutputChanged: (_) {},
        onOpenTradeMarket: (_) {},
      ),
    );
    await pumpSettleCapped(tester);

    expect(find.byType(ProductionAvailableTradeCell), findsWidgets);

    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/production_available_opens_trade_360x640.png'),
    );
  });

  testWidgets(
    'golden: Market row highlighted from Production inbound (#4581)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey('trade_highlight_from_production_golden');
      final Game game = buildTradeTestGame(
        stockpile: tradeableStockpileFilled(10),
      );
      final Player player = game.players.first;

      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(360, 640),
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
          width: 360,
          height: 640,
          child: TradeScreen(
            game: game,
            player: player,
            highlightCommodityId: 'timber',
          ),
        ),
      );
      await pumpSettleCapped(tester);

      expect(
        find.byKey(MarketCommodityRowHighlight.highlightKey('timber')),
        findsOneWidget,
      );

      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile(
          'goldens/trade_highlight_from_production_360x640.png',
        ),
      );
    },
  );
}
