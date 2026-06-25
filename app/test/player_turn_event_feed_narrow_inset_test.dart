// Pins the narrow-layout "no inset" contract for the floating
// `PlayerTurnEventFeedCard` (issue #2870 S3 / Req 11).
//
// SPEC: `SPEC/ui/player-turn-event-feed.md` § Acceptance criteria
// — the two new narrow-layout `Positioned.right == kMapOverlayEdgeInset`
// ACs added under issue #2870 S3 / Req 11. Source: `SPEC/ui/mockups/
// GAME10001-game-screen.html` `.news-feed-card` rule + the narrow
// province bottom-sheet contract in `SPEC/ui/mobile-adaptation.md` § 4
// (Province / sea detail row — narrow panel attaches to the bottom, not
// the right, so the wide `gameMapWideOverlayRightInset` MUST NOT apply
// on narrow viewports).
//
// Pins (mirrors the wide-layout `_feedCardPositionedRight` pin in
// `game_map_area_region_minimap_test.dart` so the regression sentinel is
// symmetric across breakpoints):
//
//  1. Positive — narrow + feed visible + province panel CLOSED: the
//     enclosing `Positioned.right` equals `kMapOverlayEdgeInset` (0).
//  2. Positive — narrow + feed visible + province panel OPEN: the
//     enclosing `Positioned.right` still equals `kMapOverlayEdgeInset`
//     (no wide inset added when the bottom-sheet province panel opens).
//  3. Negative — narrow + feed visible + province panel OPEN: the
//     enclosing `Positioned.right` does NOT equal
//     `gameMapWideOverlayRightInset(provincePanelOpen: true)` (which
//     would be `8 + 320 = 328`). This guards against an accidental
//     reuse of the wide inset helper on the narrow code path.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_map_area.dart';
import 'package:colonizethis_app/features/game/flame/game_screen_shared.dart'
    show gameMapWideOverlayRightInset, kMapOverlayEdgeInset;
import 'package:colonizethis_app/features/game/widgets/player_turn_event_feed.dart';
import 'package:colonizethis_app/l10n/l10n.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_province_panel_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_map/colonizethis_map.dart'
    show InitGameMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/map_view_test_fixtures.dart';
import 'support/panel_test_fixtures.dart';

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
const Size _kNarrowViewport = Size(599, 800);

/// Waits up to ~4 s for the [PlayerTurnEventFeedCard] to mount under the
/// running [GameMapArea] tree. The shell builds asynchronously (Flame
/// canvas, MediaQuery rebuilds); we avoid open-ended `pumpAndSettle` in
/// favor of bounded retries — mirrors the helper pattern used in
/// `game_map_area_region_minimap_test.dart`.
Future<void> _pumpUntilFeedCardVisible(WidgetTester tester) async {
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
double? _feedCardPositionedRight(WidgetTester tester) {
  final ctx = tester.element(find.byType(PlayerTurnEventFeedCard));
  return ctx.findAncestorWidgetOfExactType<Positioned>()?.right;
}

/// Lightweight feed-enabled game for the narrow-inset suite: the shared
/// fixture with `mapViewState.showPlayerTurnEventsFeed` toggled on so the
/// narrow `PlayerTurnEventFeedCard` mounts (Refs #3656).
Game _feedEnabledGame() {
  final base = buildEventFeedNarrowInsetTestGame();
  return base.copyWith(
    mapViewState: base.mapViewState.copyWith(showPlayerTurnEventsFeed: true),
  );
}

String _firstOldWorldTileKey(Game game) {
  final byProv = game.worldState.tileKeysByRegionAndProvince['oldWorld'];
  if (byProv == null) {
    throw StateError('missing tileKeysByRegionAndProvince.oldWorld');
  }
  for (final keys in byProv.values) {
    if (keys.isNotEmpty) return keys.first;
  }
  throw StateError('no tile keys under oldWorld');
}

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_news_feed_narrow_inset');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  mapAreaProviderOverrides({
    required AppEventBus bus,
    required Game game,
    required InitGameMapViewData mapViewData,
  }) =>
      [
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

  Future<void> pumpNarrowGameMapArea(
    WidgetTester tester, {
    required Game game,
    required InitGameMapViewData mapViewData,
    required AppEventBus bus,
  }) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(_kNarrowViewport);

    await tester.pumpWidget(
      ProviderScope(
        overrides: mapAreaProviderOverrides(
          bus: bus,
          game: game,
          mapViewData: mapViewData,
        ),
        child: MaterialApp(
          localizationsDelegates:
              AppLocalizationsBinding.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: MediaQuery(
            data: const MediaQueryData(size: _kNarrowViewport),
            child: Scaffold(
              body: GameMapArea(game: game, mapViewData: mapViewData),
            ),
          ),
        ),
      ),
    );
    await _pumpUntilFeedCardVisible(tester);
  }

  group(
    'PlayerTurnEventFeedCard narrow Positioned.right (Refs #2870 S3 / Req 11)',
    () {
      testWidgets(
        'positive: narrow + feed visible + province panel CLOSED → '
        'Positioned.right equals kMapOverlayEdgeInset (no wide inset)',
        (WidgetTester tester) async {
          final game = _feedEnabledGame();
          final bus = AppEventBus.create();
          addTearDown(bus.dispose);

          await pumpNarrowGameMapArea(
            tester,
            game: game,
            mapViewData: buildLightweightMapViewData(),
            bus: bus,
          );

          expect(
            _feedCardPositionedRight(tester),
            kMapOverlayEdgeInset,
            reason:
                'SPEC/ui/player-turn-event-feed.md § Acceptance criteria — '
                'narrow + panel closed: the floating feed card sits at '
                'Positioned.right = kMapOverlayEdgeInset (no wide inset '
                'applies on narrow viewports per issue #2870 S3 / Req 11).',
          );
        },
      );

      testWidgets(
        'positive: narrow + feed visible + province panel OPEN → '
        'Positioned.right still equals kMapOverlayEdgeInset (narrow '
        'bottom sheet covers from below, not from the right)',
        (WidgetTester tester) async {
          final game = _feedEnabledGame();
          final bus = AppEventBus.create();
          addTearDown(bus.dispose);

          await pumpNarrowGameMapArea(
            tester,
            game: game,
            mapViewData: buildLightweightMapViewData(),
            bus: bus,
          );

          // Pre-condition: feed card already at narrow inset before the
          // province panel opens. Mirrors the wide test's two-phase
          // assertion in `game_map_area_region_minimap_test.dart` so a
          // regression in either the pre- or post-open state surfaces here.
          expect(
            _feedCardPositionedRight(tester),
            kMapOverlayEdgeInset,
            reason:
                'Pre-condition: narrow + feed visible (panel closed) must '
                'already use Positioned.right = kMapOverlayEdgeInset before '
                'the panel-open transition.',
          );

          final container = ProviderScope.containerOf(
            tester.element(find.byType(GameMapArea)),
          );
          container
              .read(mapProvincePanelProvider.notifier)
              .reportMapTileTapped(_firstOldWorldTileKey(game));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 16));

          expect(
            _feedCardPositionedRight(tester),
            kMapOverlayEdgeInset,
            reason:
                'SPEC/ui/player-turn-event-feed.md § Acceptance criteria — '
                'narrow + panel open: the floating feed card must keep '
                'Positioned.right = kMapOverlayEdgeInset. The narrow '
                'province bottom sheet covers the card from the BOTTOM '
                '(via GameMapNarrowDetailOverlaySlot at ~33 vh anchored '
                'to Alignment.bottomCenter), not from the right — so the '
                'wide gameMapWideOverlayRightInset MUST NOT apply on '
                'narrow viewports (issue #2870 S3 / Req 11).',
          );
        },
      );

      testWidgets(
        'negative: narrow + feed visible + province panel OPEN → '
        'Positioned.right does NOT receive '
        'gameMapWideOverlayRightInset(true) (regression guard against '
        'accidental reuse of the wide inset helper on the narrow path)',
        (WidgetTester tester) async {
          final game = _feedEnabledGame();
          final bus = AppEventBus.create();
          addTearDown(bus.dispose);

          await pumpNarrowGameMapArea(
            tester,
            game: game,
            mapViewData: buildLightweightMapViewData(),
            bus: bus,
          );

          final container = ProviderScope.containerOf(
            tester.element(find.byType(GameMapArea)),
          );
          container
              .read(mapProvincePanelProvider.notifier)
              .reportMapTileTapped(_firstOldWorldTileKey(game));
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 16));

          final wideInsetWhenPanelOpen = gameMapWideOverlayRightInset(
            provincePanelOpen: true,
          );
          expect(
            _feedCardPositionedRight(tester),
            isNot(wideInsetWhenPanelOpen),
            reason:
                'Regression guard: gameMapWideOverlayRightInset (= '
                '$wideInsetWhenPanelOpen) is the wide-layout right inset '
                'that clears the 320 dp province side panel column. The '
                'narrow code path mounts the province panel at the bottom '
                'instead (see game_map_area_build.dart `if (isNarrow) … '
                'Align(bottomCenter, GameMapNarrowDetailOverlaySlot)`) '
                'so the wide inset MUST NOT bleed onto the narrow news '
                'feed card.',
          );
        },
      );
    },
  );
}
