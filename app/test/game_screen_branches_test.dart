import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/widgets/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'game_screen_test_support.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Game baseGame;
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    // Refs #3656: these specs assert only GameScreen chrome (victory overlay,
    // pause-menu modal, game-start intro overlay) — none of which read
    // generated map/topology data. They pump GameScreen with
    // `mapViewDataProvider` overridden to null (no map canvas mounted), so the
    // shared lightweight fixture replaces the ~7-11s `getDebugInitGameResult()`
    // map generator.
    baseGame = buildGameScreenSpecsTestGame();
    Hive.init('./.dart_tool/test_hive_game_screen_branches');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  Widget buildGameScreen({
    required double width,
    required double height,
    required Game game,
    required InitGameMapViewData? mapViewData,
    required Set<String> introShownIds,
  }) => buildGameScreenHost(
    gamesBox: gamesBox,
    game: game,
    mapViewData: mapViewData,
    width: width,
    height: height,
    navigatorKey: appNavigatorKey,
    introShownIds: introShownIds,
    includeHomeFleetCargo: false,
    includeTreasury: false,
  );

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
        mapViewData: null,
        introShownIds: {victoryGame.id},
      ),
    );
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('MILITARY VICTORY'), findsOneWidget);
    expect(find.textContaining('wins on turn 7'), findsOneWidget);
  });

  testWidgets('GameScreen shows pause menu modal when menu icon is tapped', (
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

    expect(find.text('Game Paused'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
    expect(find.text('Exit to Main Menu'), findsOneWidget);
    expect(find.text('Debug log'), findsNothing);
  });

  testWidgets(
    'GameScreen wraps content in GameStartIntroOverlay when not shown',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildGameScreen(
          width: 800,
          height: 600,
          game: baseGame,
          mapViewData: null,
          introShownIds: const <String>{},
        ),
      );
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(GameStartIntroOverlay), findsOneWidget);
    },
  );
}
