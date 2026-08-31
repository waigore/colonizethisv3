// Layout breakpoint tests for VictoryScreenBody. SPEC/ui/victory-panel.md AC-12/AC-13.

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/screens/victory/victory_screen_body.dart';
import 'package:colonizethis_app/features/game/screens/victory/victory_screen_keys.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'panel_fixtures/core.dart';
import 'victory_panel_test_support.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  late Box<dynamic> gamesBox;

  setUpAll(() async {
    gamesBox = await openVictoryPanelTestHiveBox(
      suiteId: 'victory_screen_body_layout',
    );
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  Widget buildBody({
    required Size viewport,
  }) {
    final game = buildVictoryPanelMapTestGame();
    return buildAppShell(
      viewport: viewport,
      overrides: [
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
        gameServiceProvider.overrideWith(
          (ref) => VictoryPanelMapGameService(gamesBox, GameSaveAdapter()),
        ),
      ],
      child: Scaffold(
        body: VictoryScreenBody(
          game: game,
          humanPlayerId: kPanelTestHumanPlayerId,
        ),
      ),
    );
  }

  testWidgets('wide viewport with map data uses side-by-side layout', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildBody(viewport: const Size(kNarrowBreakpoint, 700)),
    );
    await pumpSettleCapped(tester);

    expect(find.byKey(VictoryScreenKeys.standingsMinimapWideRowKey), findsOneWidget);
    expect(find.byKey(VictoryScreenKeys.standingsMinimapNarrowColumnKey), findsNothing);
    expect(find.byKey(VictoryScreenKeys.politicalMinimapSectionKey), findsOneWidget);
  });

  testWidgets('narrow viewport keeps stacked layout with map data', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildBody(viewport: const Size(kNarrowBreakpoint - 1, 700)),
    );
    await pumpSettleCapped(tester);

    expect(find.byKey(VictoryScreenKeys.standingsMinimapNarrowColumnKey), findsOneWidget);
    expect(find.byKey(VictoryScreenKeys.standingsMinimapWideRowKey), findsNothing);
    expect(find.byKey(VictoryScreenKeys.politicalMinimapSectionKey), findsOneWidget);
  });
}
