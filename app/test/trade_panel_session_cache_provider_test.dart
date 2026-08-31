// Session-cache reuse for Trade panel providers (Refs #4688 Slice 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/core/services/game_service/game_service_types.dart';
import 'package:colonizethis_app/features/game/widgets/shell/shell_player_context.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/production_allocation_provider.dart';
import 'package:colonizethis_app/providers/trade_panel_session_cache_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'trade_screen_test_support.dart';

class _TradePanelSessionCacheTestGameService extends GameService {
  _TradePanelSessionCacheTestGameService(super.box, super.adapter);

  @override
  GameMapData? getMapData(String gameId) {
    return (
      combinedTopology: MapTopology(),
      tileMapByRegion: const {},
      topologyByRegion: const {},
      warpLinks: null,
    );
  }
}

List<Override> tradePanelSessionCacheProviderOverrides(
  Game game,
  Box<dynamic> gamesBox,
) {
  return [
    currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
    currentOrdersProvider.overrideWith(
      () => CurrentOrdersNotifier(const Orders()),
    ),
    productionDesiredOutputProvider.overrideWith(
      ProductionDesiredOutputNotifier.new,
    ),
    shellPlayerContextProvider.overrideWithValue(
      tradeTestShellPlayerContext(player: game.players.first),
    ),
    gameServiceProvider.overrideWith(
      (ref) => _TradePanelSessionCacheTestGameService(
        gamesBox,
        GameSaveAdapter(),
      ),
    ),
  ];
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'trade_panel_cache');
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  test(
    'tradePanelSessionCacheProvider resets on clearActiveGameSession (Refs #4688 Slice 3)',
    () {
      final game = buildTradeTestGame(
        stockpile: tradeableStockpileFilled(50),
      );
      final container = ProviderContainer(
        overrides: tradePanelSessionCacheProviderOverrides(game, gamesBox),
      );
      addTearDown(container.dispose);

      container.listen(
        tradePanelTradeCounselHighlightsProvider,
        (_, __) {},
      );
      expect(
        container.read(tradePanelSessionCacheProvider).state.highlightsByCommodityId,
        isNotNull,
      );

      container.read(tradePanelSessionCacheProvider).reset();
      expect(
        container.read(tradePanelSessionCacheProvider).state.highlightsByCommodityId,
        isNull,
      );
      expect(
        container.read(tradePanelSessionCacheProvider).state.revision,
        isNull,
      );
    },
  );

  test(
    'tradePanelTradeCounselHighlightsProvider reuses session cache after autoDispose teardown (Refs #4688 Slice 3)',
    () {
      final game = buildTradeTestGame(
        stockpile: tradeableStockpileFilled(50),
      );
      final container = ProviderContainer(
        overrides: tradePanelSessionCacheProviderOverrides(game, gamesBox),
      );
      addTearDown(container.dispose);

      final listener = container.listen(
        tradePanelTradeCounselHighlightsProvider,
        (_, __) {},
      );
      final highlightsFirst = container.read(
        tradePanelTradeCounselHighlightsProvider,
      );
      expect(highlightsFirst, isNotNull);

      listener.close();
      final highlightsSecond = container.read(
        tradePanelTradeCounselHighlightsProvider,
      );
      expect(identical(highlightsFirst, highlightsSecond), isTrue);
    },
  );
}
