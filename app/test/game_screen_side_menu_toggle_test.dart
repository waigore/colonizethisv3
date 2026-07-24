import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/features/game/flame/controls/game_side_menu.dart';
import 'package:colonizethis_map/colonizethis_map.dart'
    show InitGameMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'game_screen_test_support.dart';
import 'map_view_test_fixtures.dart';
import 'panel_test_fixtures.dart';

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

  Widget buildGameScreen({required double width, required double height}) =>
      buildGameScreenHost(
        gamesBox: gamesBox,
        game: baseGame,
        mapViewData: mapViewData,
        width: width,
        height: height,
        includeAppEventBus: false,
        includeHomeFleetCargo: false,
        includeTreasury: false,
        wrapAppEventHandler: false,
      );

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
