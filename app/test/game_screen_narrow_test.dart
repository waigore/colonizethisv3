// In-game shell narrow viewport and side menu. SPEC/ui/in-game-shell-narrow.md, empire-buttons.md.

import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/flame/game_screen.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/map_view_provider.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  late InitGameResult debugResult;

  setUpAll(() {
    debugResult = getDebugInitGameResult();
  });

  Widget buildGameScreen({required double width, required double height}) {
    return ProviderScope(
      overrides: [
        currentGameProvider.overrideWith(
          (ref) => debugResult.game,
        ),
        mapViewDataProvider.overrideWith(
          (ref) => debugResult.mapViewData,
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

  group('GameScreen — SPEC/ui/in-game-shell-narrow.md', () {
    testWidgets(
      'AC: viewport >= 600 dp shows empire buttons in top bar',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        expect(find.text('Production'), findsOneWidget);
        expect(find.text('Civilian Units'), findsOneWidget);
        expect(find.text('Technology'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: viewport < 600 dp shows only hamburger and turn counter in top bar',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameScreen(width: 399, height: 700));
        await tester.pump();

        expect(find.textContaining('Next turn'), findsOneWidget);
        expect(find.byIcon(Icons.menu), findsOneWidget);
        expect(find.text('Production'), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: base layer cycle button (r) is visible at top-left of map; tap cycles mode (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        final buttonFinder = find.byKey(kBaseLayerCycleButtonKey);
        expect(buttonFinder, findsOneWidget);
        await tester.tap(buttonFinder);
        await tester.pump();
        await tester.tap(buttonFinder);
        await tester.pump();
        await tester.tap(buttonFinder);
        await tester.pump();
        expect(buttonFinder, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    // ACs for opening side menu (swipe/hamburger) and close (swipe/×) are covered by
    // manual testing or integration tests; opening the menu in widget test requires
    // gameServiceProvider which depends on Hive (not available in widget test).
  });
}
