// Smoke tests for shared GameScreen shell hosts (Refs #4013).

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen.dart';
import 'package:colonizethis_map/colonizethis_map.dart'
    show InitGameMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/game_screen_test_support.dart';
import 'support/map_view_test_fixtures.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  late Box<dynamic> gamesBox;
  late Game game;
  late InitGameMapViewData mapViewData;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_game_screen_support');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
    game = buildPlayersBarTestGame();
    mapViewData = buildLightweightMapViewData();
  });

  testWidgets('buildGameScreenHost mounts GameScreen', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildGameScreenHost(
        gamesBox: gamesBox,
        game: game,
        mapViewData: mapViewData,
        width: 800,
        height: 600,
      ),
    );
    await tester.pump();
    expect(find.byType(GameScreen), findsOneWidget);
  });

  testWidgets(
    'buildGameScreenShellToGameFlow mounts GameScreen on game route',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildGameScreenShellToGameFlow(
          gamesBox: gamesBox,
          game: game,
          mapViewData: mapViewData,
          width: 800,
          height: 600,
        ),
      );
      await tester.pump();
      expect(find.byType(GameScreen), findsOneWidget);
    },
  );

  testWidgets(
    'buildGameScreenHost accepts custom home without GameScreen',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        buildGameScreenHost(
          gamesBox: gamesBox,
          game: game,
          mapViewData: null,
          width: 400,
          height: 300,
          wrapAppEventHandler: false,
          includeHomeFleetCargo: false,
          includeTreasury: false,
          home: const SizedBox(key: Key('extra-home')),
        ),
      );
      await tester.pump();
      expect(find.byKey(const Key('extra-home')), findsOneWidget);
      expect(find.byType(GameScreen), findsNothing);
    },
  );
}
