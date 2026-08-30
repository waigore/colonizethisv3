// Flame lifecycle + repeated mount/unmount for Development panel (Refs #4687).

import 'package:colonizethis_app/features/game/flame/region_map/region_map.dart'
    show CtMapVisibilityMode;
import 'package:colonizethis_app/features/game/flame/region_map/ct_region_map_game.dart';
import 'package:colonizethis_app/features/game/screens/development/development_panel_keys.dart';
import 'package:colonizethis_app/features/game/screens/development/development_screen.dart';
import 'package:colonizethis_app/features/game/screens/development/development_screen_body.dart';
import 'package:colonizethis_app/features/game/screens/development/development_shell_map_pause_scope.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/shell_main_map_pause_provider.dart';
import 'package:colonizethis_app/widgets/ct_region_map.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_world/colonizethis_world.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'ct_region_map_test_support_core.dart';
import 'development_panel_test_support.dart';
import 'panel_fixtures/core.dart';

int _countRegionMapGameWidgets(WidgetTester tester) {
  return tester
      .widgetList(
        find.byWidgetPredicate(
          (w) => w.runtimeType.toString().startsWith('GameWidget<'),
        ),
      )
      .length;
}

CtRegionMapGame _singleRegionMapGame(WidgetTester tester) {
  final finder = find.byWidgetPredicate(
    (w) => w.runtimeType.toString().startsWith('GameWidget<'),
  );
  expect(finder, findsOneWidget);
  final gameWidget = tester.widget(finder);
  return (gameWidget as dynamic).game as CtRegionMapGame;
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openDevelopmentPanelTestHiveBox(suiteId: 'lifecycle');
    await warmCtRegionMapCachesForTests();
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  List<Override> _developmentOverrides(Game game) => [
    gamesBoxProvider.overrideWith((ref) => gamesBox),
    gameServiceProvider.overrideWith(
      (ref) => DevelopmentPanelMapGameService(gamesBox, GameSaveAdapter()),
    ),
    currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
    currentOrdersProvider.overrideWith(() => CurrentOrdersNotifier(const Orders())),
  ];

  testWidgets(
    'ten DevelopmentScreenBody mount/unmount cycles leave no stacked panel map engines (Refs #4687)',
    (WidgetTester tester) async {
      final game = buildDevelopmentPanelGoldenGame();

      for (var cycle = 0; cycle < 10; cycle++) {
        await tester.pumpWidget(
          buildAppShell(
            child: SizedBox(
              width: 900,
              height: 760,
              child: DevelopmentScreenBody(
                game: game,
                humanPlayerId: kPanelTestHumanPlayerId,
              ),
            ),
            overrides: _developmentOverrides(game),
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        );
        await pumpDevelopmentPanelReady(tester);
        expect(
          find.byKey(DevelopmentPanelKeys.panelMapKeyForRegion(kRegionOldWorld)),
          findsOneWidget,
        );
        expect(_countRegionMapGameWidgets(tester), 1);

        await tester.pumpWidget(
          buildAppShell(
            child: const SizedBox.shrink(),
            overrides: _developmentOverrides(game),
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
          ),
        );
        await tester.pump();
        expect(_countRegionMapGameWidgets(tester), 0);
      }
    },
  );

  testWidgets(
    'DevelopmentShellMapPauseScope acquires and releases shell map pause hold (Refs #4687)',
    (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(shellMainMapPauseHoldProvider), 0);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const DevelopmentShellMapPauseScope(
            child: SizedBox.shrink(),
          ),
        ),
      );
      await tester.pump();
      expect(container.read(shellMainMapPauseHoldProvider), 1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const SizedBox.shrink(),
        ),
      );
      await tester.pump();
      expect(container.read(shellMainMapPauseHoldProvider), 0);
    },
  );

  testWidgets(
    'shell CtRegionMap pauses while shellMainMapPauseHoldProvider is held (Refs #4687)',
    (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: SizedBox(
            width: 400,
            height: 300,
            child: CtRegionMap(
              region: ctRegionMapTestOldWorldRegion(),
              visibilityMode: CtMapVisibilityMode.playerConstrained,
              playerViewForResources: ctRegionMapTestPlayerView,
              enginePaused: container.read(shellMainMapPauseHoldProvider) > 0,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final runningGame = _singleRegionMapGame(tester);
      expect(runningGame.paused, isFalse);

      container.read(shellMainMapPauseHoldProvider.notifier).acquire();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: SizedBox(
            width: 400,
            height: 300,
            child: CtRegionMap(
              region: ctRegionMapTestOldWorldRegion(),
              visibilityMode: CtMapVisibilityMode.playerConstrained,
              playerViewForResources: ctRegionMapTestPlayerView,
              enginePaused: container.read(shellMainMapPauseHoldProvider) > 0,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(_singleRegionMapGame(tester).paused, isTrue);

      container.read(shellMainMapPauseHoldProvider.notifier).release();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: SizedBox(
            width: 400,
            height: 300,
            child: CtRegionMap(
              region: ctRegionMapTestOldWorldRegion(),
              visibilityMode: CtMapVisibilityMode.playerConstrained,
              playerViewForResources: ctRegionMapTestPlayerView,
              enginePaused: container.read(shellMainMapPauseHoldProvider) > 0,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(_singleRegionMapGame(tester).paused, isFalse);
    },
  );

  testWidgets(
    'DevelopmentScreen wraps body with shell map pause scope (Refs #4687)',
    (WidgetTester tester) async {
      final game = buildDevelopmentPanelGoldenGame();
      final container = ProviderContainer(
        overrides: _developmentOverrides(game),
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates:
                AppLocalizationsBinding.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: DevelopmentScreen(
              game: game,
              humanPlayerId: kPanelTestHumanPlayerId,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(container.read(shellMainMapPauseHoldProvider), 1);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: SizedBox.shrink()),
        ),
      );
      await tester.pump();
      expect(container.read(shellMainMapPauseHoldProvider), 0);
    },
  );
}
