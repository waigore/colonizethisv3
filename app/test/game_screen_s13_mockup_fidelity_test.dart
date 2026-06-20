// Pins the issue #2861 S13 mockup-fidelity contract on the live in-game
// `GameScreen` composite (mockup `SPEC/ui/mockups/GAME10001-game-screen.html`):
//
//  * M2 — when the map shell is active (`mapViewData != null`), the
//    enclosing `CtScreenShell` is constructed with `showTitleBar: false`
//    so no secondary "Game" (`game_screenTitle`) `CtTopBar` band paints
//    above `GameTopBar` (SPEC/ui/game-screen.md § In-game shell title band).
//  * M4 — when the wide news feed card is open and the players bar is
//    visible, the `GameMapPlayersBar` paints BELOW the
//    `PlayerTurnEventFeedCard` (mockup z-order: news card 7 > players bar
//    5), verified by pre-order element traversal of the map `Stack`
//    (earlier child = painted first = lower z).
//
// Reuses the live Riverpod fixture pattern from
// `game_screen_320dp_min_viewport_test.dart` so the pins exercise the real
// shell composite rather than a hand-built mock.

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_screen.dart'
    show GameScreen, kPlayerTurnFeedToggleButtonKey;
import 'package:colonizethis_app/features/game/widgets/game_map_players_bar.dart';
import 'package:colonizethis_app/features/game/widgets/player_turn_event_feed.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/home_fleet_cargo_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/providers/treasury_summary_provider.dart';
import 'package:colonizethis_app/widgets/ct_screen_shell.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart' show InitGameMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

const Size _kWideViewport = Size(1024, 768);

/// Returns the elements rooted at [root] in pre-order (depth-first, child
/// order preserved). For a `Stack`, children are visited in their list
/// order — which is also the paint order — so an earlier index means the
/// element paints below later ones.
List<Element> _preorder(Element root) {
  final List<Element> result = <Element>[];
  void visit(Element element) {
    result.add(element);
    element.visitChildren(visit);
  }

  visit(root);
  return result;
}

void main() {
  suppressLogsForTests();

  late InitGameResult debugResult;
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    debugResult = getDebugInitGameResult();
    Hive.init('./.dart_tool/test_hive_game_screen_s13');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  gameShellOverrides({
    required Game game,
    required InitGameMapViewData? mapViewData,
  }) => [
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
      () => GameIdsWithIntroShownNotifier({game.id}),
    ),
    appEventBusProvider.overrideWith((ref) {
      final bus = AppEventBus.create();
      ref.onDispose(bus.dispose);
      return bus;
    }),
    homeFleetCargoSummaryProvider.overrideWith(
      (ref) => const HomeFleetCargoSummary(used: 0, capacity: 0),
    ),
    treasurySummaryProvider.overrideWith(
      (ref) => const TreasurySummary(treasury: 12345),
    ),
  ];

  Future<void> pumpGameScreen(
    WidgetTester tester, {
    required Size size,
  }) async {
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.binding.setSurfaceSize(size);
    await tester.pumpWidget(
      ProviderScope(
        overrides: gameShellOverrides(
          game: debugResult.game,
          mapViewData: debugResult.mapViewData,
        ),
        child: AppEventHandlerScope(
          child: MaterialApp(
            navigatorKey: appNavigatorKey,
            theme: AppThemes.editorialMonocle,
            home: MediaQuery(
              data: MediaQueryData(size: size),
              child: const GameScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('GameScreen S13 mockup fidelity (Refs #2861)', () {
    testWidgets(
      'M2: map shell active -> CtScreenShell omits the title band',
      (WidgetTester tester) async {
        await pumpGameScreen(tester, size: _kWideViewport);

        expect(tester.takeException(), isNull);
        expect(find.byType(GameScreen), findsOneWidget);

        final CtScreenShell shell = tester.widget<CtScreenShell>(
          find.byType(CtScreenShell),
        );
        expect(
          shell.showTitleBar,
          isFalse,
          reason:
              'Issue #2861 M2: with the map shell active the in-game '
              'CtScreenShell must be built with showTitleBar: false so '
              'no secondary "Game" title band paints above GameTopBar.',
        );
        expect(
          find.descendant(
            of: find.byType(CtScreenShell),
            matching: find.byType(CtTopBar),
          ),
          findsNothing,
          reason:
              'The mockup .topbar is the only top chrome; the '
              'CtScreenShell title CtTopBar must not render on the map path.',
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'M4: open news feed card paints above the players bar (z-order)',
      (WidgetTester tester) async {
        await pumpGameScreen(tester, size: _kWideViewport);
        expect(tester.takeException(), isNull);

        // The players bar is wide-only and visible by default; the news
        // feed card is hidden until the player toggles it open.
        expect(find.byType(GameMapPlayersBar), findsOneWidget);
        expect(find.byType(PlayerTurnEventFeedCard), findsNothing);

        await tester.tap(find.byKey(kPlayerTurnFeedToggleButtonKey));
        await tester.pump();

        expect(
          find.byType(PlayerTurnEventFeedCard),
          findsOneWidget,
          reason:
              'Tapping the news toggle must open the wide floating feed '
              'card so the z-order contract can be asserted.',
        );

        final List<Element> order = _preorder(
          tester.element(find.byType(GameScreen)),
        );
        final int playersBarIndex = order.indexWhere(
          (Element e) => e.widget is GameMapPlayersBar,
        );
        final int feedCardIndex = order.indexWhere(
          (Element e) => e.widget is PlayerTurnEventFeedCard,
        );

        expect(playersBarIndex, greaterThanOrEqualTo(0));
        expect(feedCardIndex, greaterThanOrEqualTo(0));
        expect(
          playersBarIndex,
          lessThan(feedCardIndex),
          reason:
              'Issue #2861 M4: GameMapPlayersBar must appear earlier in '
              'the map Stack (painted first / lower z) than the '
              'PlayerTurnEventFeedCard so the open feed card is never '
              'obscured by player chips (mockup z-order: news 7 > bar 5).',
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}
