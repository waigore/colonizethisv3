// In-game shell chrome. SPEC/ui/in-game-shell-narrow.md, empire-buttons.md.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'game_screen_narrow_shell_chrome_support.dart';
import 'game_screen_test_support.dart';
import 'map_view_test_fixtures.dart';
import 'panel_test_fixtures.dart';
import 'app_test_hive_harness.dart';

void main() {
  suppressLogsForTests();

  final baseGame = buildPlayersBarTestGame();
  final lightMapViewData = buildLightweightMapViewData();
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'game_screen_narrow_shell_chrome');
  });

  group('GameScreen — SPEC/ui/in-game-shell-narrow.md', () {
    testWidgets(
      'AC: cargo hold indicator appears beside region tabs in used/capacity format (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        await pumpGameScreenNarrowShellChrome(
          tester,
          gamesBox: gamesBox,
          baseGame: baseGame,
          lightMapViewData: lightMapViewData,
          bindWide: true,
        );

        final indicator = find.byKey(kCargoHoldIndicatorKey);
        expect(indicator, findsOneWidget);
        expect(
          find.descendant(
            of: indicator,
            matching: find.textContaining(RegExp(r'^\d+/\d+$')),
          ),
          findsOneWidget,
        );
        expect(
          strictAssetIconPathUnder(tester, indicator),
          'assets/icons/32/ui_icon_cargo_hold.png',
        );
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    // Treasury ACs: game_screen_narrow_shell_treasury_test.dart

    testWidgets(
      'AC: top bar shows hamburger menu and turn counter; empire buttons NOT in top bar',
      (WidgetTester tester) async {
        for (final width in <double?>[1500, 399]) {
          await pumpGameScreenNarrowShellChrome(
            tester,
            gamesBox: gamesBox,
            baseGame: baseGame,
            lightMapViewData: lightMapViewData,
            bindWide: width == 1500,
            width: width ?? 1500,
          );
          expect(find.textContaining('Next turn'), findsOneWidget);
          expect(find.byIcon(Icons.menu), findsOneWidget);
          expect(find.text('Production'), findsNothing);
          expect(find.byKey(kEmpireProductionButtonKey), findsOneWidget);
          if (width == 1500) {
            expect(find.text('Civilian Units'), findsNothing);
            expect(find.text('Technology'), findsNothing);
            expect(find.byKey(kEmpireTechnologyButtonKey), findsOneWidget);
          }
        }
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: base layer cycle button is visible on map; tap cycles mode (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        await pumpGameScreenNarrowShellChrome(
          tester,
          gamesBox: gamesBox,
          baseGame: baseGame,
          lightMapViewData: lightMapViewData,
          bindWide: true,
        );
        final buttonFinder = find.byKey(kBaseLayerCycleButtonKey);
        expect(buttonFinder, findsOneWidget);
        for (var i = 0; i < 4; i++) {
          await tester.tap(buttonFinder);
          await tester.pump();
        }
        expect(buttonFinder, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );

    testWidgets(
      'AC: home-to-capital button is visible beside base layer button and tappable (SPEC/ui/empire-overview.md)',
      (WidgetTester tester) async {
        await pumpGameScreenNarrowShellChrome(
          tester,
          gamesBox: gamesBox,
          baseGame: baseGame,
          lightMapViewData: lightMapViewData,
          bindWide: true,
        );
        final homeButtonFinder = find.byKey(kHomeToCapitalButtonKey);
        expect(find.byKey(kBaseLayerCycleButtonKey), findsOneWidget);
        expect(homeButtonFinder, findsOneWidget);
        await tester.tap(homeButtonFinder);
        await tester.pump();
        expect(homeButtonFinder, findsOneWidget);
      },
      timeout: const Timeout(Duration(seconds: 15)),
    );
    // Map display options ACs: game_screen_narrow_shell_map_options_test.dart
  });
}