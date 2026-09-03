// Narrow-layout PlayerTurnEventFeedCard inset pump helpers (Refs #4720 Slice G).
// SPEC: `SPEC/ui/player-turn-event-feed.md` § Acceptance criteria.

import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/map_state/map_state.dart';
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
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

/// Narrow viewport surface size — under `kNarrowBreakpoint` (600 dp) so
/// `GameMapArea` selects its narrow branch and mounts the
/// `if (isNarrow && shell.showPlayerChrome && showPlayerTurnEventsFeed)`
/// `PlayerTurnEventFeedCard` site. Width is set to 599 (one less than
/// the breakpoint) so the in-game top bar's existing 360 dp minimum
/// chrome lays out without RenderFlex overflow under this fixture
/// (the top bar's narrow-width adaptation lives outside this issue's
/// scope; see `SPEC/ui/in-game-shell-narrow.md` § Top bar). The
/// `Positioned.right` contract under test is independent of the
/// chosen narrow width — what matters is that `isNarrow == true`.
const Size kPlayerTurnEventFeedNarrowViewport = Size(599, 800);

/// Waits up to ~4 s for the [PlayerTurnEventFeedCard] to mount under the
/// running [GameMapArea] tree. The shell builds asynchronously (Flame
/// canvas, MediaQuery rebuilds); we avoid open-ended `pumpAndSettle` in
/// favor of bounded retries — mirrors the helper pattern used in
/// `game_map_area_region_minimap_test.dart`.
Future<void> pumpUntilPlayerTurnEventFeedCardVisible(
  WidgetTester tester,
) async {
  const step = Duration(milliseconds: 50);
  const maxSteps = 80;
  for (var i = 0; i < maxSteps; i++) {
    await tester.pump(step);
    if (find.byType(PlayerTurnEventFeedCard).evaluate().isNotEmpty) {
      return;
    }
  }
  fail(
    'PlayerTurnEventFeedCard not visible within ${maxSteps * step.inMilliseconds}'
    'ms — check GameMapArea narrow branch / showPlayerTurnEventsFeed wiring.',
  );
}

/// Pull the `Positioned.right` from the ancestor wrapping the narrow
/// feed card on the map stack (`game_map_area_build.dart`).
double? playerTurnEventFeedCardPositionedRight(WidgetTester tester) {
  final ctx = tester.element(find.byType(PlayerTurnEventFeedCard));
  return ctx.findAncestorWidgetOfExactType<Positioned>()?.right;
}

/// Lightweight feed-enabled game for the narrow-inset suite: the shared
/// fixture with `mapViewState.showPlayerTurnEventsFeed` toggled on so the
/// narrow `PlayerTurnEventFeedCard` mounts (Refs #3656).
Game playerTurnEventFeedEnabledGame() {
  final base = buildEventFeedNarrowInsetTestGame();
  return base.copyWith(
    mapViewState: base.mapViewState.copyWith(showPlayerTurnEventsFeed: true),
  );
}

String firstOldWorldTileKey(Game game) {
  final byProv = game.worldState.tileKeysByRegionAndProvince['oldWorld'];
  if (byProv == null) {
    throw StateError('missing tileKeysByRegionAndProvince.oldWorld');
  }
  for (final keys in byProv.values) {
    if (keys.isNotEmpty) return keys.first;
  }
  throw StateError('no tile keys under oldWorld');
}

List<Override> playerTurnEventFeedMapAreaOverrides({
  required AppEventBus bus,
  required Box<dynamic> gamesBox,
  required Game game,
  required InitGameMapViewData mapViewData,
}) => [
  appEventBusProvider.overrideWith((ref) => bus),
  currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
  gamesBoxProvider.overrideWith((ref) => gamesBox),
  gameServiceProvider.overrideWith(
    (ref) => GameService(gamesBox, GameSaveAdapter()),
  ),
  currentOrdersProvider.overrideWith(
    () => CurrentOrdersNotifier(const Orders()),
  ),
  mapViewDataProvider.overrideWith((ref) => mapViewData),
];

Future<void> pumpNarrowPlayerTurnEventFeedGameMapArea(
  WidgetTester tester, {
  required Box<dynamic> gamesBox,
  required Game game,
  required InitGameMapViewData mapViewData,
  required AppEventBus bus,
}) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(kPlayerTurnEventFeedNarrowViewport);

  await tester.pumpWidget(
    buildAppShell(
      overrides: playerTurnEventFeedMapAreaOverrides(
        bus: bus,
        gamesBox: gamesBox,
        game: game,
        mapViewData: mapViewData,
      ),
      localizationsDelegates: AppLocalizationsBinding.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      viewport: kPlayerTurnEventFeedNarrowViewport,
      child: Scaffold(
        body: GameMapArea(game: game, mapViewData: mapViewData),
      ),
    ),
  );
  await pumpUntilPlayerTurnEventFeedCardVisible(tester);
}
