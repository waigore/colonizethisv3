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
///
/// Optional [gameService], [initialOrders], and [eventBus] replace the default
/// shell pins so callers do not redeclare the same providers in a second
/// override list (Riverpod forbids duplicate provider overrides).
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
  GameService? gameService,
  Orders initialOrders = const Orders(),
  AppEventBus? eventBus,
}) {
  final Set<String> shownIds = introShownIds ?? {game.id};
  final List<Override> overrides = <Override>[
    gamesBoxProvider.overrideWith((ref) => gamesBox),
    gameServiceProvider.overrideWith(
      (ref) => gameService ?? GameService(gamesBox, GameSaveAdapter()),
    ),
    currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
    currentOrdersProvider.overrideWith(
      () => CurrentOrdersNotifier(initialOrders),
    ),
    mapViewDataProvider.overrideWith((ref) => mapViewData),
    gameIdsWithIntroShownProvider.overrideWith(
      () => GameIdsWithIntroShownNotifier(shownIds),
    ),
  ];
  if (includeAppEventBus) {
    overrides.add(
      appEventBusProvider.overrideWith((ref) {
        if (eventBus != null) {
          return eventBus;
        }
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
///
/// [extraOverrides] are appended after the canonical shell overrides and MUST
/// not redeclare providers already in [buildGameScreenShellOverrides]
/// (Riverpod rejects duplicate overrides). Prefer [gameService],
/// [initialOrders], and [eventBus] for those pins (Refs #4035).
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
  GameService? gameService,
  Orders initialOrders = const Orders(),
  AppEventBus? eventBus,
  List<Override> extraOverrides = const <Override>[],
  Map<String, WidgetBuilder>? routes,
  String? initialRoute,
  Widget home = const GameScreen(),
}) {
  final ThemeData resolved = theme ?? AppThemes.colonial;
  final ThemeData appTheme = platform == null
      ? resolved
      : resolved.copyWith(platform: platform);
  final Widget sizedHome = MediaQuery(
    data: MediaQueryData(size: Size(width, height)),
    child: home,
  );
  final MaterialApp materialApp = MaterialApp(
    navigatorKey: navigatorKey,
    theme: appTheme,
    routes: routes ?? const <String, WidgetBuilder>{},
    initialRoute: initialRoute,
    home: initialRoute == null ? sizedHome : null,
  );
  return ProviderScope(
    overrides: <Override>[
      ...buildGameScreenShellOverrides(
        gamesBox: gamesBox,
        game: game,
        mapViewData: mapViewData,
        treasurySummary: treasurySummary,
        introShownIds: introShownIds,
        includeAppEventBus: includeAppEventBus,
        includeHomeFleetCargo: includeHomeFleetCargo,
        includeTreasury: includeTreasury,
        gameService: gameService,
        initialOrders: initialOrders,
        eventBus: eventBus,
      ),
      ...extraOverrides,
    ],
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
  return buildGameScreenHost(
    gamesBox: gamesBox,
    game: game,
    mapViewData: mapViewData,
    width: width,
    height: height,
    theme: theme,
    platform: platform,
    navigatorKey: appNavigatorKey,
    treasurySummary: treasurySummary,
    routes: {
      Routes.shell: (_) =>
          const Scaffold(body: Center(child: Text('Main Menu'))),
      Routes.game: (_) => MediaQuery(
        data: MediaQueryData(size: Size(width, height)),
        child: const GameScreen(),
      ),
    },
    initialRoute: Routes.game,
  );
}
