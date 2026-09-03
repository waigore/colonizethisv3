// Wide regression sentinel for the in-game `GameScreen` 320 dp pin.
// Narrow chrome + measurement pins live in
// `game_screen_320dp_min_viewport_test.dart`.
//
// SPEC: `SPEC/ui/mobile-adaptation.md` § 7 and § 4 In-game shell.
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

  final Game baseGame = buildPlayersBarTestGame();
  final InitGameMapViewData lightMapViewData = buildLightweightMapViewData();
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'game_screen_320dp_wide');
  });

  group('SPEC/ui/mobile-adaptation.md § 7 — GameScreen @ 320 dp (Refs #2870 '
      'S10 + Req 6)', () {
    testWidgets('Negative control: GameScreen @ 1024×768 also pumps without '
        'exception, left-rail chrome still renders, players bar '
        'reappears at wide widths (Req 6 wide-side contrast)', (
      WidgetTester tester,
    ) async {
      await pumpGameScreen320(
        tester,
        size: kGameScreen320WideViewport,
        gamesBox: gamesBox,
        game: baseGame,
        mapViewData: lightMapViewData,
      );

      expect(
        tester.takeException(),
        isNull,
        reason:
            'Regression sentinel: the same GameScreen fixture '
            'must pump without exception at a comfortably wide '
            'viewport (1024 × 768). Without this contrast a '
            'future refactor that broke the host overflow contract '
            'upstream of GameScreen itself would silently invalidate '
            'the 320 dp positive pin above.',
      );

      expect(find.byType(GameScreen), findsOneWidget);

      expect(
        find.byKey(kEmpireProductionButtonKey),
        findsOneWidget,
        reason:
            'Wide layout must still mount the empire production '
            'rail button — the contrast keeps the narrow pin '
            'honest about exercising the same shell composite.',
      );

      expect(
        tester.getSize(find.byKey(kEmpireProductionButtonKey)),
        const Size(
          GameMapEmpireLeftRail.buttonSize,
          GameMapEmpireLeftRail.buttonSize,
        ),
        reason:
            'Refs #2870 Req 8 wide-side contrast: at viewport width '
            '≥ the 600 dp shell breakpoint each left-rail empire '
            'button renders at the default '
            '${GameMapEmpireLeftRail.buttonSize} × '
            '${GameMapEmpireLeftRail.buttonSize} dp, so the narrow '
            '26 × 26 dp assertion above pins the breakpoint '
            'comparator direction rather than a static size.',
      );

      expect(
        tester.getSize(find.byKey(kBaseLayerCycleButtonKey)),
        const Size(
          GameMapCornerControls.buttonSize,
          GameMapCornerControls.buttonSize,
        ),
        reason:
            'Refs #2870 Req 9 wide-side contrast: at viewport width '
            '≥ the 600 dp shell breakpoint each corner-control '
            'button renders at the default '
            '${GameMapCornerControls.buttonSize} × '
            '${GameMapCornerControls.buttonSize} dp, keeping the '
            'narrow 24 × 24 dp assertion meaningful.',
      );

      expect(
        find.byKey(kGameMapPlayersBarKey),
        findsOneWidget,
        reason:
            'Refs #2870 Requirement 6 wide-side contrast: at '
            'viewport width ≥ shell breakpoint (600 dp) the '
            '`GameMapPlayersBar` floating chip column reappears '
            'in the widget tree (per the `!isNarrow` gate in '
            '`game_map_area_build.dart`). The wide control '
            'pinning its presence is what keeps the narrow '
            '`findsNothing` assertion above meaningful.',
      );
    }, timeout: const Timeout(Duration(seconds: 20)));
  });
}
