// Pin the 320 dp minimum-viewport contract for the in-game `GameScreen`
// shell composite — narrow chrome + measurement pins.
// Wide regression sentinel lives in
// `game_screen_320dp_min_viewport_wide_test.dart`.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 and § 4 In-game shell.
// SPEC: `SPEC/ui/empire-overview.md`; `SPEC/ui/in-game-shell-narrow.md`.
// Refs #2870 S10 + Req 6/8/9.

import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen.dart';
import 'package:colonizethis_map/colonizethis_map.dart'
    show InitGameMapViewData;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'game_screen_320dp_min_viewport_support.dart';
import 'game_screen_test_support.dart';
import 'map_view_test_fixtures.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  // Refs #3656: lightweight game + minimal mapViewData replace the
  // ~7-11s getDebugInitGameResult() map generation.
  final Game baseGame = buildPlayersBarTestGame();
  final InitGameMapViewData lightMapViewData = buildLightweightMapViewData();
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'game_screen_320dp');
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — GameScreen @ 320 dp (Refs #2870 '
      'S10 + Req 6)', () {
    testWidgets('AC (positive) GameScreen @ 320×640: narrow top bar + '
        'left-rail chrome renders end-to-end without overflow, '
        'players bar is hidden (Req 6)', (WidgetTester tester) async {
      await pumpGameScreen320(
        tester,
        size: kGameScreen320MinViewport,
        gamesBox: gamesBox,
        game: baseGame,
        mapViewData: lightMapViewData,
      );

      expect(
        tester.takeException(),
        isNull,
        reason:
            'SPEC/ui/mobile-adaptation.md § 7: at kMinViewportWidth '
            '(320 dp) the live GameScreen composite must pump without '
            'a RenderFlex overflow exception. The narrow GameTopBar '
            'layout (hamburger + trailing Next-turn button only) '
            'closes the prior ~116 px top-bar overflow gap.',
      );

      expect(
        find.byType(GameScreen),
        findsOneWidget,
        reason:
            'GameScreen must mount end-to-end so the 320 dp pin '
            'actually exercises the live in-game shell composite '
            'rather than the test fixture failing earlier in the '
            'pumpWidget chain.',
      );

      expect(
        find.byIcon(Icons.menu),
        findsOneWidget,
        reason:
            'SPEC/ui/in-game-shell-narrow.md § Top bar: the '
            'hamburger menu icon must remain visible at the '
            'minimum supported viewport (320 dp); the narrow top '
            'bar shows only the hamburger and turn counter.',
      );

      expect(
        find.textContaining('Next turn'),
        findsOneWidget,
        reason:
            'SPEC/ui/in-game-shell-narrow.md § Top bar: the turn '
            'counter (rendered through the "Next turn" label) '
            'must remain visible at the minimum supported '
            'viewport (320 dp) alongside the hamburger control.',
      );

      expect(
        find.byKey(kEmpireProductionButtonKey),
        findsOneWidget,
        reason:
            'SPEC/ui/empire-overview.md § Left rail: the empire '
            'production rail button must remain mounted at the '
            'minimum supported viewport (320 dp) so the narrow '
            'left rail (Refs #2870 Req 8, 26 × 26 dp) still '
            'exposes empire navigation.',
      );

      expect(
        find.byKey(kEmpireTechnologyButtonKey),
        findsOneWidget,
        reason:
            'SPEC/ui/empire-overview.md § Left rail: the empire '
            'technology rail button must remain mounted at the '
            'minimum supported viewport (320 dp), pairing with '
            'the production button above.',
      );

      expect(
        find.byKey(kGameMapPlayersBarKey),
        findsOneWidget,
        reason:
            'Issue #3898: at 320 dp with fixture showPlayersBar=true '
            '(model/legacy default; new-game setup uses false per #3986), '
            'the players bar mounts below the news-feed anchor on narrow.',
      );
    }, timeout: const Timeout(Duration(seconds: 20)));

    testWidgets('AC (positive) GameScreen @ 320×640: left-rail empire buttons '
        'render at 26 × 26 dp and corner-control buttons at 24 × 24 dp '
        '(Refs #2870 Req 8 / 9, S3)', (WidgetTester tester) async {
      await pumpGameScreen320(
        tester,
        size: kGameScreen320MinViewport,
        gamesBox: gamesBox,
        game: baseGame,
        mapViewData: lightMapViewData,
      );

      expect(
        tester.takeException(),
        isNull,
        reason:
            'SPEC/ui/mobile-adaptation.md § 4 In-game shell: the '
            'narrow chrome must lay out without exception before its '
            'measurements are asserted.',
      );

      expect(
        tester.getSize(find.byKey(kEmpireProductionButtonKey)),
        const Size(
          GameMapEmpireLeftRail.narrowButtonSize,
          GameMapEmpireLeftRail.narrowButtonSize,
        ),
        reason:
            'Refs #2870 Req 8 / SPEC/ui/mobile-adaptation.md § 4 '
            'In-game shell: below the 600 dp shell breakpoint each '
            'left-rail empire button compresses to '
            '${GameMapEmpireLeftRail.narrowButtonSize} × '
            '${GameMapEmpireLeftRail.narrowButtonSize} dp '
            '(mockup `.empire-btn @media (max-width:600px)`).',
      );

      expect(
        tester.getSize(find.byKey(kBaseLayerCycleButtonKey)),
        const Size(
          GameMapCornerControls.narrowButtonSize,
          GameMapCornerControls.narrowButtonSize,
        ),
        reason:
            'Refs #2870 Req 9 / SPEC/ui/mobile-adaptation.md § 4 '
            'In-game shell: below the 600 dp shell breakpoint each '
            'bottom-left corner-control button compresses to '
            '${GameMapCornerControls.narrowButtonSize} × '
            '${GameMapCornerControls.narrowButtonSize} dp '
            '(mockup `.corner-btn @media (max-width:600px)`).',
      );
    }, timeout: const Timeout(Duration(seconds: 20)));
  });
}
