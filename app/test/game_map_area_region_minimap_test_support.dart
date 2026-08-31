// Pump/fixture helpers for GameMapArea region minimap tests (Refs #4305).

import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
import 'package:colonizethis_app/features/game/flame/minimap/minimap.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart'
    show
        gameMapWideOverlayRightInset,
        kGameMapWideStackRightGutter,
        kPlayerTurnFeedToggleButtonKey,
        kRegionMinimapCustomPaintKey;
import 'package:colonizethis_app/features/game/widgets/shell/player_turn_event_feed.dart';
import 'package:colonizethis_app_l10n/l10n/l10n.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_map/colonizethis_map.dart'
    show InitGameMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'game_fixture.dart';
import 'map_view_fixture.dart';

/// Loads the committed seed-42 `Game` + map-view fixtures instead of paying the
/// ~7-11s `getDebugInitGameResult()` procedural map generation per isolate. This
/// suite mounts the minimap chrome and reads only structural map data
/// (`tileKeysByRegionAndProvince`, region geometry), so the cheap decode is
/// sufficient (Refs #3656).
({Game game, InitGameMapViewData mapViewData}) loadMapAreaMinimapFixture() => (
  game: loadSeed42Game(),
  mapViewData: loadSeed42MapViewData(),
);

/// Avoid open-ended [pumpAndSettle] (animations/shell work can hang tests).
Future<void> pumpUntilMinimapPaintVisible(WidgetTester tester) async {
  const step = Duration(milliseconds: 50);
  const maxSteps = 80;
  for (var i = 0; i < maxSteps; i++) {
    await tester.pump(step);
    if (find.byKey(kRegionMinimapCustomPaintKey).evaluate().isNotEmpty) {
      return;
    }
  }
  fail(
    'Minimap not visible within ${maxSteps * step.inMilliseconds}ms — '
    'check GameMapArea / map stack.',
  );
}

String firstOldWorldTileKeyForMinimap(Game game) {
  final m = game.worldState.tileKeysByRegionAndProvince['oldWorld'];
  if (m == null) {
    throw StateError('missing tileKeysByRegionAndProvince.oldWorld');
  }
  for (final keys in m.values) {
    if (keys.isNotEmpty) return keys.first;
  }
  throw StateError('no tile keys under oldWorld');
}

/// [Positioned] wrapping [GameRegionMinimap] in [GameMapArea] (see `game_map_area.dart`).
double? minimapPositionedRight(WidgetTester tester) {
  final ctx = tester.element(find.byType(GameRegionMinimap));
  return ctx.findAncestorWidgetOfExactType<Positioned>()?.right;
}

double? feedCardPositionedRight(WidgetTester tester) {
  final ctx = tester.element(find.byType(PlayerTurnEventFeedCard));
  return ctx.findAncestorWidgetOfExactType<Positioned>()?.right;
}

Future<({Game game, InitGameMapViewData mapViewData, AppEventBus bus})>
pumpMapAreaWithMinimap(
  WidgetTester tester, {
  required Box<dynamic> gamesBox,
  Game? game,
  Size? surfaceSize,
}) async {
  if (surfaceSize != null) {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(surfaceSize);
  }
  final init = loadMapAreaMinimapFixture();
  final resolvedGame = game ?? init.game;
  final bus = AppEventBus.create();
  addTearDown(bus.dispose);
  // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
  await tester.pumpWidget(
    buildAppShell(
      overrides: [
        appEventBusProvider.overrideWith((ref) => bus),
        currentGameProvider.overrideWith(
          () => CurrentGameNotifier(resolvedGame),
        ),
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith(
          (ref) => GameService(gamesBox, GameSaveAdapter()),
        ),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
        mapViewDataProvider.overrideWith((ref) => init.mapViewData),
      ],
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      child: Scaffold(
        body: GameMapArea(
          game: resolvedGame,
          mapViewData: init.mapViewData,
        ),
      ),
    ),
  );
  await pumpUntilMinimapPaintVisible(tester);
  return (game: resolvedGame, mapViewData: init.mapViewData, bus: bus);
}
