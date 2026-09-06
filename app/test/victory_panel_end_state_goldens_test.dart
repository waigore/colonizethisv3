// End-state and calendar-halt goldens for GAME70001 (Refs #4165, #4734 Slice J).
import 'package:colonizethis_app/features/game/screens/victory/victory_screen_body.dart';
import 'package:colonizethis_app/features/game/screens/victory/victory_screen_keys.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'panel_fixtures/core.dart';
import 'victory_panel_goldens_test_support.dart';

void main() {
  suppressLogsForTests();

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
}
