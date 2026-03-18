import 'package:colonizethis_app/features/game/flame/victory_overlay.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_models/colonizethis_models.dart' as ct_models;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  suppressLogsForTests();

  late ct_models.Game game;
  late String winnerPlayerId;

  setUp(() {
    game = getDebugInitGameResult().game;
    winnerPlayerId = game.players.first.id;
  });

  Widget buildVictoryRoute({
    required ct_models.VictoryState victory,
  }) {
    return Scaffold(
      body: Stack(
        children: [
          VictoryOverlay(
            game: game,
            victory: victory,
          ),
        ],
      ),
    );
  }

  testWidgets('VictoryOverlay renders victory label and winner sentence',
      (WidgetTester tester) async {
    final victory = ct_models.VictoryState(
      winnerPlayerId: winnerPlayerId,
      type: ct_models.VictoryType.military,
      turnNumber: 12,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: buildVictoryRoute(victory: victory),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Military victory'), findsOneWidget);
    expect(find.textContaining('wins on turn 12'), findsOneWidget);
  });

  testWidgets('VictoryOverlay "View final state" dismisses overlay',
      (WidgetTester tester) async {
    final victory = ct_models.VictoryState(
      winnerPlayerId: winnerPlayerId,
      type: ct_models.VictoryType.military,
      turnNumber: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: buildVictoryRoute(victory: victory),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Military victory'), findsOneWidget);
    await tester.tap(find.text('View final state'));
    await tester.pumpAndSettle();
    expect(find.text('Military victory'), findsNothing);
  });

  testWidgets('VictoryOverlay "Return to main menu" pops to first route',
      (WidgetTester tester) async {
    final victory = ct_models.VictoryState(
      winnerPlayerId: winnerPlayerId,
      type: ct_models.VictoryType.military,
      turnNumber: 3,
    );

    final navigatorKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(
      MaterialApp(
        navigatorKey: navigatorKey,
        initialRoute: '/',
        routes: {
          '/': (_) => const Scaffold(body: Text('Home')),
          '/victory': (_) => buildVictoryRoute(victory: victory),
        },
      ),
    );
    await tester.pumpAndSettle();

    navigatorKey.currentState!.pushNamed('/victory');
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsNothing);
    expect(find.text('Military victory'), findsOneWidget);

    await tester.tap(find.text('Return to main menu'));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Military victory'), findsNothing);
  });
}

