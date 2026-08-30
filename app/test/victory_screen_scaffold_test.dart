// Widget tests for VictoryScreen scaffold. SPEC/ui/victory-panel.md.

import 'package:colonizethis_app/app.dart';
import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/config/route_paths.dart';
import 'package:colonizethis_app/config/routes.dart';
import 'package:colonizethis_app/config/ui_screen_ids.dart';
import 'package:colonizethis_app/core/services/app_event_handler/app_event_handler_scope.dart';
import 'package:colonizethis_app/core/services/game_service/game_service.dart';
import 'package:colonizethis_app/features/game/flame/controls/controls.dart';
import 'package:colonizethis_app/features/game/screens/game/game_screen_shared.dart';
import 'package:colonizethis_app/features/game/screens/victory/victory_screen.dart';
import 'package:colonizethis_app/features/game/screens/victory/victory_screen_keys.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_box_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/providers/game_service_provider.dart';
import 'package:colonizethis_app/widgets/ct_top_bar.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_save/colonizethis_save.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'app_shell_harness.dart';
import 'panel_fixtures/core.dart';
import 'widget_test_pumps.dart';
import 'app_test_hive_harness.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Player humanPlayer;
  late Box<dynamic> gamesBox;

  setUpAll(() async {
    game = buildPanelTestGame(
      players: [
        const Player(id: 'gp1', displayName: 'England', isHuman: true),
        const Player(id: 'gp2', displayName: 'France', isHuman: false),
      ],
      oldWorldProvinces: [
        const Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
        const Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp2'),
      ],
    );
    humanPlayer = game.players.first;
    gamesBox = await openAppTestHiveBox(suiteId: 'victory_screen');
  });

  tearDownAll(() async {
    await gamesBox.close();
  });

  List<Override> baseOverrides() => [
    gamesBoxProvider.overrideWith((ref) => gamesBox),
    gameServiceProvider.overrideWith(
      (ref) => GameService(gamesBox, GameSaveAdapter()),
    ),
    currentGameProvider.overrideWith(() => CurrentGameNotifier(game)),
    appEventBusProvider.overrideWith((ref) {
      final bus = AppEventBus.create();
      ref.onDispose(bus.dispose);
      return bus;
    }),
  ];

  Widget buildLeftRailHost() {
    return buildAppShell(
      overrides: baseOverrides(),
      navigatorKey: appNavigatorKey,
      onGenerateRoute: Routes.generate,
      shellWrapper: (app) => AppEventHandlerScope(child: app),
      child: Scaffold(
        body: Stack(
          children: [
            Positioned(
              left: 20,
              top: 0,
              child: GameMapEmpireLeftRail(
                game: game,
                humanPlayerId: humanPlayer.id,
              ),
            ),
          ],
        ),
      ),
    );
  }

  test('UiScreenIds.victoryScreen is GAME70001', () {
    expect(UiScreenIds.victoryScreen, 'GAME70001');
    expect(VictoryScreen.screenId, 'GAME70001');
    expect(RoutePaths.victory, '/game/victory');
  });

  testWidgets('rail exposes Victory button last after Technology', (
    tester,
  ) async {
    await tester.pumpWidget(buildLeftRailHost());
    await pumpSettleCapped(tester);

    final victory = find.byKey(kEmpireVictoryButtonKey);
    final technology = find.byKey(kEmpireTechnologyButtonKey);
    expect(victory, findsOneWidget);
    expect(technology, findsOneWidget);
    expect(
      tester.getTopLeft(victory).dy,
      greaterThan(tester.getTopLeft(technology).dy),
    );
  });

  testWidgets('tapping Victory navigates to VictoryScreen', (tester) async {
    await tester.pumpWidget(buildLeftRailHost());
    await pumpSettleCapped(tester);

    await tester.tap(find.byKey(kEmpireVictoryButtonKey));
    await pumpSettleCapped(tester);

    expect(find.byType(VictoryScreen), findsOneWidget);
    expect(find.byKey(VictoryScreenKeys.topBarKey), findsOneWidget);
    expect(find.text('Victory'), findsOneWidget);
    expect(find.byKey(VictoryScreenKeys.conditionsSectionKey), findsOneWidget);
    expect(find.byKey(VictoryScreenKeys.standingsSectionKey), findsOneWidget);
    expect(find.textContaining('31 or more Old World provinces'), findsOneWidget);
    expect(find.text('England'), findsWidgets);
  });

  testWidgets('route host pushes VictoryScreen with Map back chrome', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildAppShell(
        overrides: baseOverrides(),
        onGenerateRoute: Routes.generate,
        shellWrapper: (app) => AppEventHandlerScope(child: app),
        child: Builder(
          builder: (context) {
            return ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  RoutePaths.victory,
                  arguments: {
                    'game': game,
                    'humanPlayerId': humanPlayer.id,
                  },
                );
              },
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await pumpSettleCapped(tester);

    expect(find.byType(CtTopBar), findsOneWidget);
    expect(find.text('Map'), findsOneWidget);
  });
}
