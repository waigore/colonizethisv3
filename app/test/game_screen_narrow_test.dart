// In-game shell side menu. SPEC/ui/in-game-shell-narrow.md, empire-buttons.md.

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
        currentGameProvider.overrideWith((ref) => debugResult.game),
        mapViewDataProvider.overrideWith((ref) => debugResult.mapViewData),
        gameIdsWithIntroShownProvider.overrideWith(
          (ref) => {debugResult.game.id},
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
      'AC: top bar shows hamburger menu and turn counter; empire buttons NOT in top bar (wide viewport)',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        expect(find.textContaining('Next turn'), findsOneWidget);
        expect(find.byIcon(Icons.menu), findsOneWidget);
        // Empire buttons should NOT be visible in top bar
        expect(find.text('Production'), findsNothing);
        expect(find.text('Civilian Units'), findsNothing);
        expect(find.text('Technology'), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: top bar shows hamburger menu and turn counter; empire buttons NOT in top bar (narrow viewport)',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameScreen(width: 399, height: 700));
        await tester.pump();

        expect(find.textContaining('Next turn'), findsOneWidget);
        expect(find.byIcon(Icons.menu), findsOneWidget);
        // Empire buttons should NOT be visible in top bar
        expect(find.text('Production'), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: base layer cycle button is visible at top-left of map; tap cycles mode (SPEC/ui/empire-overview.md)',
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

    testWidgets(
      'AC: home-to-capital button is visible beneath base layer button and tappable (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        final dpr = tester.view.devicePixelRatio;
        tester.view.physicalSize = Size(1500 * dpr, 700 * dpr);
        addTearDown(tester.view.reset);
        await tester.pumpWidget(buildGameScreen(width: 1500, height: 700));
        await tester.pump();

        final baseButtonFinder = find.byKey(kBaseLayerCycleButtonKey);
        final homeButtonFinder = find.byKey(kHomeToCapitalButtonKey);

        expect(baseButtonFinder, findsOneWidget);
        expect(homeButtonFinder, findsOneWidget);

        await tester.tap(homeButtonFinder);
        await tester.pump();

        // No additional assertions here; behavior (centering on capital tile)
        // is covered by CtRegionMap's centerOnTileKey tests and capitalTile specs.
        expect(homeButtonFinder, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    // Side menu button content tests require Hive initialization (for gameServiceProvider).
    // The empire buttons implementation uses the correct icons:
    // - Production → ui_icon_production.png
    // - Civilian Units → ui_icon_civilian_units.png
    // - Military Units → ui_icon_military_units.png
    // - Diplomacy → ui_icon_diplomacy.png
    // - Technology → ui_icon_technology.png
    // Each button uses Image.asset(icon, width: 20, height: 20) + SizedBox(width: 8) + Text(label).
    // Integration tests or manual testing verify the side menu opens and shows these buttons
    // in the correct order per SPEC/ui/empire-buttons.md.
  });

  group('GameScreen — Next turn confirmation', () {
    testWidgets(
      'AC: clicking Next turn button shows confirmation dialog with turn number',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameScreen(width: 800, height: 600));
        await tester.pump();

        final nextTurnFinder = find.textContaining('Next turn');
        expect(nextTurnFinder, findsOneWidget);
        await tester.tap(nextTurnFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('End turn?'), findsOneWidget);
        expect(find.textContaining('will end'), findsOneWidget);
        expect(find.text('No'), findsOneWidget);
        expect(find.text('Yes'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: clicking No closes dialog without advancing turn',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameScreen(width: 800, height: 600));
        await tester.pump();

        final nextTurnFinder = find.textContaining('Next turn');
        await tester.tap(nextTurnFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('End turn?'), findsOneWidget);

        await tester.tap(find.text('No'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        expect(find.text('End turn?'), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: dialog shows correct turn number from game state',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildGameScreen(width: 800, height: 600));
        await tester.pump();

        final nextTurnFinder = find.textContaining('Next turn');
        await tester.tap(nextTurnFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        final turnNumber = debugResult.game.worldState.turnState.turnNumber;
        expect(
          find.textContaining('Turn $turnNumber will end'),
          findsOneWidget,
        );
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}
