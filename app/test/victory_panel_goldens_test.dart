// Widget goldens for GAME70001 (Refs #4165). Baselines: `app/test/goldens/`.
// SPEC: SPEC/ui/victory-panel.md § Acceptance criteria.
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/features/game/screens/victory/victory_screen_body.dart';
import 'package:colonizethis_app/features/game/screens/victory/victory_screen_keys.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'golden_capture_harness.dart';
import 'panel_fixtures/core.dart';
import 'victory_panel_goldens_test_support.dart';
import 'victory_panel_test_support.dart';
import 'widget_test_pumps.dart';

late Box<dynamic> _victoryGoldenGamesBox;

void main() {
  suppressLogsForTests();

  setUpAll(() async {
    _victoryGoldenGamesBox = await openVictoryPanelTestHiveBox(
      suiteId: 'victory_panel_goldens',
    );
  });

  tearDownAll(() async {
    await _victoryGoldenGamesBox.close();
  });

  testWidgets(
    'golden: conditions and GP standings default (Refs #4165 AC-2/AC-3)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('victoryPanelDefaultGolden');
      await pumpVictoryPanelBodyGolden(
        tester,
        boundaryKey: boundaryKey,
        game: victoryPanelGoldenStandingsGame(),
      );

      expect(
        find.byKey(VictoryScreenKeys.conditionsSectionKey),
        findsOneWidget,
      );
      expect(find.byKey(VictoryScreenKeys.standingsSectionKey), findsOneWidget);
      expect(
        find.textContaining('31 or more Old World provinces'),
        findsOneWidget,
      );
      expect(find.textContaining('This year is 1582'), findsOneWidget);
      expect(find.textContaining('last campaign year is 1800'), findsOneWidget);
      expect(
        find.textContaining('218 years remain (159 full turns)'),
        findsOneWidget,
      );
      expect(find.textContaining('near 1800 (turn 201)'), findsNothing);
      expect(find.textContaining('military victory'), findsNothing);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/victory_panel_default.png'),
      );
    },
  );

  testWidgets('golden: infinite-mode conditions variant (Refs #4165 AC-2)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('victoryPanelInfiniteGolden');
    await pumpVictoryPanelBodyGolden(
      tester,
      boundaryKey: boundaryKey,
      game: victoryPanelGoldenStandingsGame().copyWith(infiniteMode: true),
    );

    expect(find.byKey(VictoryScreenKeys.conditionsSectionKey), findsOneWidget);
    expect(find.textContaining('Infinite mode is on'), findsOneWidget);
    expect(find.textContaining('calendar halt is bypassed'), findsOneWidget);
    expect(find.textContaining('years remain'), findsNothing);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/victory_panel_infinite_mode.png'),
    );
  });

  testWidgets('golden: last campaign year remaining 0 (Refs #4597)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('victoryPanelLastYearGolden');
    await pumpVictoryPanelBodyGolden(
      tester,
      boundaryKey: boundaryKey,
      game: victoryPanelGoldenStandingsGame().copyWith(
        worldState: victoryPanelGoldenStandingsGame().worldState.copyWith(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 201),
        ),
      ),
    );

    expect(find.textContaining('last campaign year (1800)'), findsOneWidget);
    expect(find.textContaining('No years remain'), findsOneWidget);
    expect(find.textContaining('218 years remain'), findsNothing);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/victory_panel_last_year.png'),
    );
  });

  testWidgets('golden: expanded power-score breakdown (Refs #4165 AC-4)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('victoryPanelExpandedGolden');
    await pumpVictoryPanelBodyGolden(
      tester,
      boundaryKey: boundaryKey,
      game: victoryPanelGoldenStandingsGame(),
    );

    await tester.tap(find.byKey(VictoryScreenKeys.standingExpandKey('gp1')));
    await pumpSyncFrames(tester);

    expect(
      find.byKey(VictoryScreenKeys.powerBreakdownKey('gp1')),
      findsOneWidget,
    );
    expect(
      find.textContaining('calendar end without a province-count winner'),
      findsOneWidget,
    );
    expect(find.textContaining('×'), findsNothing);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/victory_panel_expanded_power.png'),
    );
  });

  testWidgets(
    'golden: province-count win end-state banner (Refs #4165 AC-7, #4198)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('victoryPanelMilitaryEndGolden');
      final game = victoryPanelGoldenStandingsGame().copyWith(
        victory: const VictoryState(
          winnerPlayerId: 'gp1',
          type: VictoryType.military,
          turnNumber: 42,
        ),
      );
      await pumpVictoryPanelBodyGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
      );

      expect(find.byKey(VictoryScreenKeys.endStateBannerKey), findsOneWidget);
      expect(
        find.textContaining(
          'England won on turn 42 by controlling enough Old World provinces',
        ),
        findsOneWidget,
      );
      expect(find.textContaining('military victory'), findsNothing);
      expect(find.textContaining('218 years remain'), findsNothing);
      expect(
        find.textContaining('Remaining years are not shown'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/victory_panel_military_end.png'),
      );
    },
  );

  testWidgets(
    'golden: calendar halt declared-winner banner (Refs #4165 AC-7)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('victoryPanelCalendarWinnerGolden');
      final game = buildPanelTestGame(
        players: [
          panelTestHumanPlayer(id: 'gp1', displayName: 'England'),
          const Player(id: 'gp2', displayName: 'France', isHuman: false),
        ],
        oldWorldProvinces: const [
          Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
          Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp1'),
          Province(id: 'oldWorld|p3', regionId: 'oldWorld', ownerId: 'gp1'),
          Province(id: 'oldWorld|p4', regionId: 'oldWorld', ownerId: 'gp2'),
        ],
      ).copyWith(calendarCampaignHalted: true);
      await pumpVictoryPanelBodyGolden(
        tester,
        boundaryKey: boundaryKey,
        game: game,
      );

      expect(find.byKey(VictoryScreenKeys.endStateBannerKey), findsOneWidget);
      expect(
        find.textContaining('strongest overall realm when play stopped'),
        findsOneWidget,
      );
      expect(find.textContaining('218 years remain'), findsNothing);
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/victory_panel_calendar_winner.png'),
      );
    },
  );

  testWidgets('golden: calendar halt tie banner (Refs #4165 AC-7)', (
    WidgetTester tester,
  ) async {
    const boundaryKey = ValueKey<String>('victoryPanelCalendarTieGolden');
    final game = buildPanelTestGame(
      players: [
        panelTestHumanPlayer(id: 'gp1', displayName: 'England'),
        const Player(id: 'gp2', displayName: 'France', isHuman: false),
      ],
      oldWorldProvinces: const [
        Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
        Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp2'),
      ],
    ).copyWith(calendarCampaignHalted: true);
    await pumpVictoryPanelBodyGolden(
      tester,
      boundaryKey: boundaryKey,
      game: game,
    );

    expect(find.byKey(VictoryScreenKeys.endStateBannerKey), findsOneWidget);
    expect(find.textContaining('tied overall strength'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await expectLater(
      find.byKey(boundaryKey),
      matchesGoldenFile('goldens/victory_panel_calendar_tie.png'),
    );
  });

  testWidgets(
    'golden: wide side-by-side standings and minimap (Refs #4165 AC-12)',
    (WidgetTester tester) async {
      const boundaryKey = ValueKey<String>('victoryPanelWideLayoutGolden');
      final game = buildVictoryPanelMapTestGame();
      await pumpGoldenHost(
        tester,
        boundaryKey: boundaryKey,
        physicalSize: const Size(kNarrowBreakpoint, 700),
        includeLocalizations: true,
        wrapInProviderScope: true,
        center: false,
        overrides: [
          currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
          gameServiceProvider.overrideWith(
            (ref) => VictoryPanelMapGameService(
              _victoryGoldenGamesBox,
              GameSaveAdapter(),
            ),
          ),
        ],
        child: SizedBox(
          width: kNarrowBreakpoint,
          height: 700,
          child: VictoryScreenBody(
            game: game,
            humanPlayerId: kPanelTestHumanPlayerId,
          ),
        ),
      );

      expect(
        find.byKey(VictoryScreenKeys.standingsMinimapWideRowKey),
        findsOneWidget,
      );
      expect(
        find.byKey(VictoryScreenKeys.politicalMinimapSectionKey),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(boundaryKey),
        matchesGoldenFile('goldens/victory_panel_wide_layout.png'),
      );
    },
  );
}
