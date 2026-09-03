// In-game shell Android back exit confirmation (Refs #4720 Slice G).
// SPEC/ui/in-game-shell-narrow.md.

import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen.dart';
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
import 'app_test_hive_harness.dart';

void main() {
  suppressLogsForTests();

  // Refs #3656: the narrow in-game shell assertions read only chrome; the map
  // canvas just needs *a* mapViewData to mount.
  final Game baseGame = buildPlayersBarTestGame();
  final InitGameMapViewData lightMapViewData = buildLightweightMapViewData();
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(
      suiteId: 'game_screen_narrow_android_back',
    );
  });

  Widget buildShellToGameFlow({
    required double width,
    required double height,
    TargetPlatform platform = TargetPlatform.android,
  }) => buildGameScreenShellToGameFlow(
    gamesBox: gamesBox,
    game: baseGame,
    mapViewData: lightMapViewData,
    width: width,
    height: height,
    platform: platform,
  );

  group('GameScreen — Android back exit confirmation', () {
    testWidgets(
      'AC: pressing back shows pixel-style confirm dialog',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildShellToGameFlow(width: 800, height: 600));
        await tester.pump();

        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.text('Exit game?'), findsOneWidget);
        expect(
          find.text('Your current progress will be lost if not saved.'),
          findsOneWidget,
        );
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Exit'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: tapping Cancel dismisses dialog and stays on game',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildShellToGameFlow(width: 800, height: 600));
        await tester.pump();

        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.text('Cancel'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(CtDialogShell), findsNothing);
        expect(find.byType(GameScreen), findsOneWidget);
        expect(find.text('Main Menu'), findsNothing);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: tapping outside dialog dismisses and stays on game',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildShellToGameFlow(width: 800, height: 600));
        await tester.pump();

        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tapAt(const Offset(4, 4));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(CtDialogShell), findsNothing);
        expect(find.byType(GameScreen), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: tapping Exit navigates to main menu route',
      (WidgetTester tester) async {
        await tester.pumpWidget(buildShellToGameFlow(width: 800, height: 600));
        await tester.pump();

        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(find.text('Exit'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.text('Main Menu'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );

    testWidgets(
      'AC: Android back (platform-configured) shows exit confirm before leaving game',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          buildShellToGameFlow(
            width: 800,
            height: 600,
            platform: TargetPlatform.android,
          ),
        );
        await tester.pump();

        await tester.binding.handlePopRoute();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.text('Exit game?'), findsOneWidget);
        expect(find.text('Cancel'), findsOneWidget);
        expect(find.text('Exit'), findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 20)),
    );
  });
}
