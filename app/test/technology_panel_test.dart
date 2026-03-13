// Tests for TechnologyPanel. UXD 03k — research slots and researched techs.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology_panel.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Player player;

  setUpAll(() {
    final result = getDebugInitGameResult();
    game = result.game;
    player = game.players.isNotEmpty ? game.players.first : _dummyPlayer();
  });

  testWidgets('TechnologyPanel builds and shows player name and research slots', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TechnologyPanel(game: game, player: player),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TechnologyPanel), findsOneWidget);
    expect(find.textContaining(player.displayName), findsOneWidget);
    expect(find.textContaining('Research slots:'), findsOneWidget);
    expect(find.text('Researched (0):'), findsOneWidget);
  });

  testWidgets('TechnologyPanel shows None yet when no researched techs', (WidgetTester tester) async {
    final emptyPlayer = player.copyWith(techUnlocked: <String, bool>{});
    final gameWithEmpty = game.copyWith(
      players: [emptyPlayer, ...game.players.skip(1)],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TechnologyPanel(game: gameWithEmpty, player: emptyPlayer),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('None yet'), findsOneWidget);
    expect(find.byType(Chip), findsNothing);
  });

  testWidgets('TechnologyPanel shows researched tech chips when player has techs', (WidgetTester tester) async {
    final ids = techCatalog.keys.take(3).toList();
    final techUnlocked = {for (final id in ids) id: true};
    final withTechs = player.copyWith(techUnlocked: techUnlocked);
    final gameWithTechs = game.copyWith(
      players: [withTechs, ...game.players.skip(1)],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TechnologyPanel(game: gameWithTechs, player: withTechs),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Researched (3):'), findsOneWidget);
    expect(find.byType(Chip), findsNWidgets(3));
  });

  testWidgets('TechnologyPanel shows in progress section when player has research progress', (WidgetTester tester) async {
    final techId = techCatalog.keys.first;
    final withProgress = player.copyWith(
      researchProgressByTechId: {techId: 50},
    );
    final gameWithProgress = game.copyWith(
      players: [withProgress, ...game.players.skip(1)],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TechnologyPanel(game: gameWithProgress, player: withProgress),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('In progress:'), findsOneWidget);
    expect(find.textContaining('pts'), findsOneWidget);
  });

  testWidgets('TechnologyPanel shows custom research slots when set', (WidgetTester tester) async {
    const slots = 4;
    final withSlots = player.copyWith(researchSlots: slots);
    final gameWithSlots = game.copyWith(
      players: [withSlots, ...game.players.skip(1)],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TechnologyPanel(game: gameWithSlots, player: withSlots),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Research slots: $slots'), findsOneWidget);
  });
}

Player _dummyPlayer() {
  return Player(
    id: 'dummy',
    displayName: 'Dummy',
    isHuman: true,
  );
}
