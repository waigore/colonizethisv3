import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/ct_game_feature_screen_shell.dart';
import 'package:colonizethis_app/widgets/game_to_ui_bus_listener.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/panel_test_fixtures.dart';
import 'support/widget_test_assets.dart';

void main() {
  suppressLogsForTests();

  late Game routeGame;
  late Game liveSameIdGame;
  late Game differentIdGame;

  setUpAll(() async {
    await setUpNinePatchAssets();
    // Lightweight fixture (Refs #3656): the shell only reads `game.id` (for the
    // current-vs-route id match) and `players.first.displayName` (rendered by
    // the test body builder); no generated map/topology data is needed.
    final base = buildPanelTestGame();
    final first = base.players.first;
    routeGame = base.copyWith(
      players: [
        first.copyWith(displayName: 'Route Player'),
        ...base.players.skip(1),
      ],
    );
    liveSameIdGame = routeGame.copyWith(
      players: [
        routeGame.players.first.copyWith(displayName: 'Live Player'),
        ...routeGame.players.skip(1),
      ],
    );
    differentIdGame = routeGame.copyWith(
      id: '${routeGame.id}_other',
      players: [
        routeGame.players.first.copyWith(displayName: 'Other Player'),
        ...routeGame.players.skip(1),
      ],
    );
  });

  Widget buildShell({
    required Game game,
    required Game? currentGame,
    required bool attachGameToUiListener,
  }) {
    return ProviderScope(
      overrides: [
        currentGameProvider.overrideWith(
          () => CurrentGameNotifier(currentGame),
        ),
        appEventBusProvider.overrideWith((ref) {
          final bus = AppEventBus.create();
          ref.onDispose(bus.dispose);
          return bus;
        }),
      ],
      child: MaterialApp(
        home: CtGameFeatureScreenShell(
          game: game,
          title: 'Test Title',
          attachGameToUiListener: attachGameToUiListener,
          bodyBuilder: (context, ref, displayGame) {
            return Text(displayGame.players.first.displayName);
          },
        ),
      ),
    );
  }

  testWidgets('uses currentGameProvider game when ids match', (tester) async {
    await tester.pumpWidget(
      buildShell(
        game: routeGame,
        currentGame: liveSameIdGame,
        attachGameToUiListener: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Live Player'), findsOneWidget);
  });

  testWidgets('uses route game when current game id differs', (tester) async {
    await tester.pumpWidget(
      buildShell(
        game: routeGame,
        currentGame: differentIdGame,
        attachGameToUiListener: true,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Route Player'), findsOneWidget);
    expect(find.text('Other Player'), findsNothing);
  });

  testWidgets('attachGameToUiListener toggles GameToUIBusListener', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildShell(
        game: routeGame,
        currentGame: liveSameIdGame,
        attachGameToUiListener: true,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GameToUIBusListener), findsOneWidget);

    await tester.pumpWidget(
      buildShell(
        game: routeGame,
        currentGame: liveSameIdGame,
        attachGameToUiListener: false,
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(GameToUIBusListener), findsNothing);
  });
}
