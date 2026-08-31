// Widget tests for VictoryScreenBody variants. SPEC/ui/victory-panel.md.

import 'package:colonizethis_app/features/game/screens/victory/victory_screen_body.dart';
import 'package:colonizethis_app/features/game/screens/victory/victory_screen_keys.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'panel_fixtures/core.dart';
import 'widget_test_pumps.dart';

void main() {
  suppressLogsForTests();

  Widget buildBody(Game game) {
    return buildAppShell(
      overrides: [
        currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
      ],
      child: Scaffold(
        body: VictoryScreenBody(
          game: game,
          humanPlayerId: kPanelTestHumanPlayerId,
        ),
      ),
    );
  }

  testWidgets('shows infinite-mode bypass copy when infiniteMode is true', (
    tester,
  ) async {
    final game = buildPanelTestGame().copyWith(infiniteMode: true);
    await tester.pumpWidget(buildBody(game));
    await pumpSettleCapped(tester);

    expect(
      find.textContaining('Infinite mode is on'),
      findsOneWidget,
    );
    expect(
      find.textContaining('calendar halt is bypassed'),
      findsOneWidget,
    );
  });

  testWidgets('shows province-count win end-state banner', (tester) async {
    final game = buildPanelTestGame(
      players: [panelTestHumanPlayer(displayName: 'England')],
    ).copyWith(
      victory: const VictoryState(
        winnerPlayerId: 'gp1',
        type: VictoryType.military,
        turnNumber: 42,
      ),
    );
    await tester.pumpWidget(buildBody(game));
    await pumpSettleCapped(tester);

    expect(find.byKey(VictoryScreenKeys.endStateBannerKey), findsOneWidget);
    expect(
      find.textContaining(
        'England won on turn 42 by controlling enough Old World provinces',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('military victory'), findsNothing);
  });

  testWidgets('shows calendar halt declared-winner banner', (tester) async {
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
    await tester.pumpWidget(buildBody(game));
    await pumpSettleCapped(tester);

    expect(find.byKey(VictoryScreenKeys.endStateBannerKey), findsOneWidget);
    expect(
      find.textContaining('strongest overall realm when play stopped'),
      findsOneWidget,
    );
  });

  testWidgets('shows calendar halt tie banner when no unique leader', (
    tester,
  ) async {
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
    await tester.pumpWidget(buildBody(game));
    await pumpSettleCapped(tester);

    expect(
      find.textContaining('tied overall strength'),
      findsOneWidget,
    );
  });

  testWidgets('standings show helper and OW progress labels', (tester) async {
    final game = buildPanelTestGame(
      players: [
        panelTestHumanPlayer(displayName: 'England'),
        const Player(id: 'gp2', displayName: 'France', isHuman: false),
      ],
      oldWorldProvinces: const [
        Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
        Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp2'),
      ],
    );
    await tester.pumpWidget(buildBody(game));
    await pumpSettleCapped(tester);

    expect(find.byKey(VictoryScreenKeys.standingsHelperKey), findsOneWidget);
    expect(find.textContaining('/ 31 Old World provinces'), findsWidgets);
    expect(
      find.byKey(VictoryScreenKeys.standingProgressKey('gp1')),
      findsOneWidget,
    );
  });

  testWidgets('row body select does not expand power breakdown', (tester) async {
    final game = buildPanelTestGame(
      players: [
        panelTestHumanPlayer(displayName: 'England'),
        const Player(id: 'gp2', displayName: 'France', isHuman: false),
      ],
      oldWorldProvinces: const [
        Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
        Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp2'),
      ],
    );
    await tester.pumpWidget(buildBody(game));
    await pumpSettleCapped(tester);

    await tester.tap(find.byKey(VictoryScreenKeys.standingSelectKey('gp2')));
    await pumpSyncFrames(tester);

    expect(
      find.byKey(VictoryScreenKeys.powerBreakdownKey('gp2')),
      findsNothing,
    );
  });

  testWidgets('expanding a GP row reveals power-score breakdown', (
    tester,
  ) async {
    final game = buildPanelTestGame(
      players: [
        panelTestHumanPlayer(displayName: 'England'),
        const Player(id: 'gp2', displayName: 'France', isHuman: false),
      ],
      oldWorldProvinces: const [
        Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
        Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp2'),
      ],
    );
    await tester.pumpWidget(buildBody(game));
    await pumpSettleCapped(tester);

    expect(
      find.byKey(VictoryScreenKeys.powerBreakdownKey('gp1')),
      findsNothing,
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
  });
}
