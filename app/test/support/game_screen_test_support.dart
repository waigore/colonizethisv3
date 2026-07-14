// Shared GameScreen shell overrides + hosts for in-game chrome widget tests
// (Refs #4013). Collapses duplicated `gameShellOverrides` / `buildGameScreen`
// clones across `game_screen_*` and players-bar suites.

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/home_fleet_cargo_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/providers/treasury_summary_provider.dart';
import 'package:colonizethis_map/colonizethis_map.dart'
    show InitGameMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:hive/hive.dart';

/// Canonical Riverpod overrides for mounting [GameScreen] with a Hive games
/// box, current game, orders, map view, and optional chrome summaries.
List<Override> buildGameScreenShellOverrides({
  required Box<dynamic> gamesBox,
  required Game game,
  required InitGameMapViewData? mapViewData,
  TreasurySummary treasurySummary = const TreasurySummary(treasury: 12345),
  Set<String>? introShownIds,
  HomeFleetCargoSummary homeFleetCargo = const HomeFleetCargoSummary(
    used: 0,
    capacity: 0,
  ),
  bool includeAppEventBus = true,
  bool includeHomeFleetCargo = true,
  bool includeTreasury = true,
}) {
  final Set<String> shownIds = introShownIds ?? {game.id};
  final List<Override> overrides = <Override>[
    gamesBoxProvider.overrideWith((ref) => gamesBox),
    gameServiceProvider.overrideWith(
      (ref) => GameService(gamesBox, GameSaveAdapter()),
    ),
    currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
    currentOrdersProvider.overrideWith(
      () => CurrentOrdersNotifier(const Orders()),
    ),
    mapViewDataProvider.overrideWith((ref) => mapViewData),
    gameIdsWithIntroShownProvider.overrideWith(
      () => GameIdsWithIntroShownNotifier(shownIds),
    ),
  ];
  if (includeAppEventBus) {
    overrides.add(
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
    );
  }
  if (includeHomeFleetCargo) {
    overrides.add(
      homeFleetCargoSummaryProvider.overrideWith((ref) => homeFleetCargo),
    );
  }
  if (includeTreasury) {
    overrides.add(
      treasurySummaryProvider.overrideWith((ref) => treasurySummary),
    );
  }
  return overrides;
}

/// Hosts [GameScreen] under [ProviderScope] + optional [AppEventHandlerScope]
/// at an explicit logical [width]×[height] (caller sets binding surface size).
Widget buildGameScreenHost({
  required Box<dynamic> gamesBox,
  required Game game,
  required InitGameMapViewData? mapViewData,
  required double width,
  required double height,
  ThemeData? theme,
  TargetPlatform? platform,
  GlobalKey<NavigatorState>? navigatorKey,
  Set<String>? introShownIds,
  TreasurySummary treasurySummary = const TreasurySummary(treasury: 12345),
  bool includeAppEventBus = true,
  bool includeHomeFleetCargo = true,
  bool includeTreasury = true,
  bool wrapAppEventHandler = true,
}) {
  final ThemeData resolved = theme ?? AppThemes.colonial;
  final ThemeData appTheme = platform == null
      ? resolved
      : resolved.copyWith(platform: platform);
  final Widget materialApp = MaterialApp(
    navigatorKey: navigatorKey,
    theme: appTheme,
    home: MediaQuery(
      data: MediaQueryData(size: Size(width, height)),
      child: const GameScreen(),
    ),
  );
  return ProviderScope(
    overrides: buildGameScreenShellOverrides(
      gamesBox: gamesBox,
      game: game,
      mapViewData: mapViewData,
      treasurySummary: treasurySummary,
      introShownIds: introShownIds,
      includeAppEventBus: includeAppEventBus,
      includeHomeFleetCargo: includeHomeFleetCargo,
      includeTreasury: includeTreasury,
    ),
    child: wrapAppEventHandler
        ? AppEventHandlerScope(child: materialApp)
        : materialApp,
  );
}

/// Shell→game route stack used by Android back / exit confirmation ACs.
Widget buildGameScreenShellToGameFlow({
  required Box<dynamic> gamesBox,
  required Game game,
  required InitGameMapViewData? mapViewData,
  required double width,
  required double height,
  TargetPlatform platform = TargetPlatform.android,
  ThemeData? theme,
  TreasurySummary treasurySummary = const TreasurySummary(treasury: 12345),
}) {
  final ThemeData resolved = (theme ?? AppThemes.colonial).copyWith(
    platform: platform,
  );
  return ProviderScope(
    overrides: buildGameScreenShellOverrides(
      gamesBox: gamesBox,
      game: game,
      mapViewData: mapViewData,
      treasurySummary: treasurySummary,
    ),
    child: AppEventHandlerScope(
      child: MaterialApp(
        navigatorKey: appNavigatorKey,
        theme: resolved,
        routes: {
          Routes.shell: (_) =>
              const Scaffold(body: Center(child: Text('Main Menu'))),
          Routes.game: (_) => MediaQuery(
            data: MediaQueryData(size: Size(width, height)),
            child: const GameScreen(),
          ),
        },
        initialRoute: Routes.game,
      ),
    ),
  );
}
