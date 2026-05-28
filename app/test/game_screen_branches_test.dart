import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/core/services/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/features/game/flame/game_screen.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  suppressLogsForTests();

  late InitGameResult debugResult;
  late Game baseGame;
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    debugResult = getDebugInitGameResult();
    baseGame = debugResult.game;
    Hive.init('./.dart_tool/test_hive_game_screen_branches');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  Widget buildGameScreen({
    required double width,
    required double height,
    required Game game,
    required InitGameMapViewData? mapViewData,
    required Set<String> introShownIds,
  }) {
    return ProviderScope(
      overrides: [
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
          () => GameIdsWithIntroShownNotifier(introShownIds),
        ),
        appEventBusProvider.overrideWith((ref) {
          final bus = AppEventBus.create();
          ref.onDispose(bus.dispose);
          return bus;
        }),
      ],
      child: AppEventHandlerScope(
        child: MaterialApp(
          navigatorKey: appNavigatorKey,
          theme: AppThemes.colonial,
          home: MediaQuery(
            data: MediaQueryData(size: Size(width, height)),
            child: const GameScreen(),
          ),
        ),
      ),
    );
  }

  testWidgets('GameScreen shows VictoryOverlay when game.victory is set', (
    WidgetTester tester,
  ) async {
    final winner = baseGame.players.first;
    final victoryGame = baseGame.copyWith(
      victory: VictoryState(
        winnerPlayerId: winner.id,
        type: VictoryType.military,
        turnNumber: 7,
      ),
    );

    await tester.pumpWidget(
      buildGameScreen(
        width: 900,
        height: 650,
        game: victoryGame,
        mapViewData: debugResult.mapViewData,
        introShownIds: {victoryGame.id},
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('MILITARY VICTORY'), findsOneWidget);
    expect(find.textContaining('wins on turn 7'), findsOneWidget);
  });

  testWidgets('GameScreen shows pause menu and opens bottom sheet', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildGameScreen(
        width: 800,
        height: 600,
        game: baseGame,
        mapViewData: null,
        introShownIds: {baseGame.id},
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Next turn'), findsOneWidget);
    expect(find.byIcon(Icons.menu), findsOneWidget);

    await tester.tap(find.byIcon(Icons.menu));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Debug log'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
  });

  testWidgets(
    'GameScreen wraps content in GameStartIntroOverlay when not shown',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildGameScreen(
          width: 800,
          height: 600,
          game: baseGame,
          mapViewData: debugResult.mapViewData,
          introShownIds: const <String>{},
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(GameStartIntroOverlay), findsOneWidget);
    },
  );
}
