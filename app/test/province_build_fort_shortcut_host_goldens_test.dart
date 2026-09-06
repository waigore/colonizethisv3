// Golden + widget checks for MAP20001 Build fort Engineer shortcut (Refs #4280).
// Pump harness: province_shortcut_host_golden_test_support.dart.

import 'package:colonizethis_app/features/game/widgets/units/civilian/build_fort_payoff_gist_line.dart';
import 'package:colonizethis_app/widgets/ct_icon_action.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_test_hive_harness.dart';
import 'province_build_fort_shortcut_host_golden_fixtures.dart';
import 'province_shortcut_host_golden_test_support.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openAppTestHiveBox(suiteId: 'province_bf_golden');
  });

  testWidgets(
    'golden: wide province side panel shows enabled Build fort shortcut (Refs #4280)',
    (WidgetTester tester) async {
      final game = goldenBuildFortGame();
      final topology = buildFortGoldenCombinedTopology();
      await pumpProvinceShortcutGoldenWideHost(
        tester,
        gamesBox: gamesBox,
        game: game,
        region: goldenBuildFortRegion(),
        topology: topology,
        boundaryKey: const ValueKey('province_bf_shortcut_wide_golden'),
        tileKey: kBuildFortGoldenTileKey,
        gameId: kBuildFortGoldenGameId,
      );
      await expectLater(
        find.byKey(const ValueKey('province_bf_shortcut_wide_golden')),
        matchesGoldenFile('goldens/province_build_fort_wide_panel.png'),
      );
    },
  );

  testWidgets(
    'narrow detail overlay shows enabled Build fort shortcut (Refs #4280)',
    (WidgetTester tester) async {
      final game = goldenBuildFortGame();
      final topology = buildFortGoldenCombinedTopology();
      await pumpProvinceShortcutGoldenNarrowHost(
        tester,
        gamesBox: gamesBox,
        game: game,
        region: goldenBuildFortRegion(),
        topology: topology,
        boundaryKey: const ValueKey('province_bf_shortcut_narrow_golden'),
        tileKey: kBuildFortGoldenTileKey,
        gameId: kBuildFortGoldenGameId,
        afterTileTap: revealProvinceShortcutGoldenNarrowMilitaryTab,
      );
      final buildFortShortcut = find.byWidgetPredicate(
        (Widget w) =>
            w is CtIconAction && w.onPressed != null && w.icon == Icons.castle,
      );
      expect(buildFortShortcut, findsOneWidget);
      expect(find.byKey(kBuildFortPayoffGistKey), findsOneWidget);
    },
  );
}
