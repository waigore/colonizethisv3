import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/core/services/game_service.dart';
import 'package:colonizethis_app/features/game/flame/game_screen.dart';
import 'package:colonizethis_app/features/game/flame/game_side_menu.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_map/colonizethis_map.dart' show InitGameMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'support/map_view_test_fixtures.dart';
import 'support/panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  // Refs #3656: the side-menu toggle assertions only read the in-game side menu
  // chrome (Debug log entry, scrim token); the map canvas just needs *a*
  // mapViewData to mount. The lightweight game + minimal mapViewData replace the
  // ~7-11s getDebugInitGameResult() map generation.
  final Game baseGame = buildSideMenuTestGame();
  final InitGameMapViewData mapViewData = buildLightweightMapViewData();
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    Hive.init('./.dart_tool/test_hive_game_screen_side_menu');
    gamesBox = await Hive.openBox<dynamic>(HiveBoxNames.games);
  });

  Widget buildGameScreen({required double width, required double height}) {
    return ProviderScope(
      overrides: [
        gamesBoxProvider.overrideWith((ref) => gamesBox),
        gameServiceProvider.overrideWith(
          (ref) => GameService(gamesBox, GameSaveAdapter()),
        ),
        currentGameProvider.overrideWith(
          () => CurrentGameNotifier(baseGame),
        ),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
        mapViewDataProvider.overrideWith((ref) => mapViewData),
        gameIdsWithIntroShownProvider.overrideWith(
          () => GameIdsWithIntroShownNotifier({baseGame.id}),
        ),
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

  testWidgets('GameScreen taps menu icon to open/close side menu', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(buildGameScreen(width: 399, height: 700));
    await tester.pump(const Duration(milliseconds: 200));

    // In this layout (mapViewData != null) the visible menu icon is GameMapControls,
    // which toggles the side menu (not the pause menu).
    await tester.tap(find.byIcon(Icons.menu).first);
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Debug log'), findsOneWidget);
    expect(find.text('Production'), findsNothing);
    // SPEC: in-game-shell-narrow.md § Modal behaviour — the scrim resolves
    // to the canonical EditorialMonoclePalette.dialogScrim token (no
    // Colors.black54 literal). The host extracts the layer as
    // GameSideMenuScrim so we can also exercise the dismiss callback via
    // its stable surface key.
    final overlayTapTarget = find.byKey(GameSideMenuScrim.surfaceKey);
    expect(overlayTapTarget, findsOneWidget);
    final Container scrim = tester.widget<Container>(overlayTapTarget);
    expect(scrim.color, EditorialMonoclePalette.dialogScrim);

    await tester.tap(overlayTapTarget, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Debug log'), findsNothing);
  });
}

