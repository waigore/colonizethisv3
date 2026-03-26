import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/game_screen.dart';
import 'package:colonizethis_app/features/game/flame/game_side_menu.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  suppressLogsForTests();

  late InitGameResult debugResult;

  setUpAll(() async {
    debugResult = getDebugInitGameResult();

    Hive.init('./.dart_tool/test_hive_game_screen_side_menu');
    await Hive.openBox<dynamic>('games');
  });

  Widget buildGameScreen({required double width, required double height}) {
    return ProviderScope(
      overrides: [
        currentGameProvider.overrideWith((ref) => debugResult.game),
        mapViewDataProvider.overrideWith((ref) => debugResult.mapViewData),
        gameIdsWithIntroShownProvider.overrideWith(
          () => GameIdsWithIntroShownNotifier({debugResult.game.id}),
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

    expect(find.text('Production'), findsOneWidget);
    final overlayTapTarget = find.byWidgetPredicate(
      (w) => w is Container && w.color == Colors.black54,
    );
    expect(overlayTapTarget, findsOneWidget);

    await tester.tap(overlayTapTarget.first, warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 800));

    expect(find.text('Production'), findsNothing);
  });
}

