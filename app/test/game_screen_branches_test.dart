import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/game_screen.dart';
import 'package:colonizethis_app/features/game/dialogue/game_start_intro_overlay.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_map/colonizethis_map.dart';
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  late InitGameResult debugResult;
  late ct_models.Game baseGame;

  setUpAll(() {
    debugResult = getDebugInitGameResult();
    baseGame = debugResult.game;
  });

  Widget buildGameScreen({
    required double width,
    required double height,
    required ct_models.Game game,
    required InitGameMapViewData? mapViewData,
    required Set<String> introShownIds,
  }) {
    return ProviderScope(
      overrides: [
        currentGameProvider.overrideWith((ref) => game),
        mapViewDataProvider.overrideWith((ref) => mapViewData),
        gameIdsWithIntroShownProvider.overrideWith((ref) => introShownIds),
      ],
      child: MaterialApp(
        theme: AppThemes.colonial,
        home: MediaQuery(
          data: MediaQueryData(size: Size(width, height)),
          child: const GameScreen(),
        ),
      ),
    );
  }

  testWidgets('GameScreen shows VictoryOverlay when game.victory is set',
      (WidgetTester tester) async {
    final winner = baseGame.players.first;
    final victoryGame = baseGame.copyWith(
      victory: ct_models.VictoryState(
        winnerPlayerId: winner.id,
        type: ct_models.VictoryType.military,
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

    expect(find.text('Military victory'), findsOneWidget);
    expect(find.textContaining('wins on turn 7'), findsOneWidget);
  });

  testWidgets('GameScreen shows pause menu and opens bottom sheet',
      (WidgetTester tester) async {
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
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Debug log'), findsOneWidget);
    expect(find.text('Resume'), findsOneWidget);
  });

  testWidgets('GameScreen wraps content in GameStartIntroOverlay when not shown',
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

    // Just verifying presence is enough to cover the GameScreen branch.
    expect(find.byType(GameStartIntroOverlay), findsOneWidget);
  });
}

