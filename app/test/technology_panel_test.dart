// Tests for TechnologyPanel. UXD 03k — research slots and researched techs.

import 'package:colonizethis_data/colonizethis_data.dart';
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
            child: TechnologyPanel(
              game: game,
              player: player,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TechnologyPanel), findsOneWidget);
    expect(find.textContaining(player.displayName), findsOneWidget);
    expect(find.textContaining('Research slots:'), findsOneWidget);
    // Dark theme uses an explicit section heading, not a count line, for
    // the researched-techs grid (Refs #2864 S2).
    expect(find.text('RESEARCHED TECHS'), findsOneWidget);
    expect(find.text('None yet'), findsOneWidget);
  });

  testWidgets('TechnologyPanel hides edit controls when onOrdersChanged is null',
      (WidgetTester tester) async {
    final techId = techCatalog.keys.first;
    final withTech = player.copyWith(techUnlocked: {techId: true});
    final gameWithTechs = game.copyWith(
      players: [withTech, ...game.players.skip(1)],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TechnologyPanel(
              game: gameWithTechs,
              player: withTech,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Choose tech'), findsNothing);
    expect(find.text('Cancel'), findsNothing);
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
            child: TechnologyPanel(
              game: gameWithEmpty,
              player: emptyPlayer,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('None yet'), findsOneWidget);
    // No Material Chip on the dark-theme researched grid; no
    // ResearchedTechChip primitive rendered in the empty state either
    // (Refs #2864 S2).
    expect(find.byType(Chip), findsNothing);
    expect(find.byType(ResearchedTechChip), findsNothing);
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
            child: TechnologyPanel(
              game: gameWithTechs,
              player: withTechs,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Dark theme heading + three custom chip primitives (Refs #2864 S2).
    expect(find.text('RESEARCHED TECHS'), findsOneWidget);
    expect(find.byType(ResearchedTechChip), findsNWidgets(3));
    // Material `Chip` is banned by the Ct-* catalog.
    expect(find.byType(Chip), findsNothing);
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
            child: TechnologyPanel(
              game: gameWithProgress,
              player: withProgress,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // CtSectionLabel renders the heading in upper case (Refs #2864 S2).
    expect(find.text('IN PROGRESS:'), findsOneWidget);
    expect(find.textContaining('RP'), findsOneWidget);
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
            child: TechnologyPanel(
              game: gameWithSlots,
              player: withSlots,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Research slots: $slots'), findsOneWidget);
  });

  testWidgets('TechnologyPanel "Choose tech" shows no-techs modal when none available',
      (WidgetTester tester) async {
    final fullyUnlocked = player.copyWith(
      techUnlocked: {for (final id in techCatalog.keys) id: true},
    );
    final gameWithFullyUnlocked = game.copyWith(
      players: [fullyUnlocked, ...game.players.skip(1)],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TechnologyPanel(
              game: gameWithFullyUnlocked,
              player: fullyUnlocked,
              onOrdersChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Choose tech is rendered for each slot when editing is enabled.
    await tester.tap(find.text('Choose tech').first);
    await tester.pumpAndSettle();

    expect(find.text('No techs available to research'), findsOneWidget);
  });

  testWidgets('TechnologyPanel slot Cancel removes the slot order and shows snackbar',
      (WidgetTester tester) async {
    final techId = techCatalog.keys.first;
    final withOrder = player.copyWith(
      techUnlocked: <String, bool>{}, // ensures bottom sheet can be "no techs"
    );
    final gameWithEmptyUnlocked = game.copyWith(
      players: [withOrder, ...game.players.skip(1)],
    );

    final orders = Orders(
      researchOrdersByPlayerId: {
        withOrder.id: [
          ResearchOrder(
            slotIndex: 0,
            techId: techId,
            funding: ResearchFundingLevel.low,
          ),
        ],
      },
    );

    Orders? captured;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: TechnologyPanel(
              game: gameWithEmptyUnlocked,
              player: withOrder,
              currentOrders: orders,
              onOrdersChanged: (next) => captured = next,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Cancel shown for slots that currently have a tech assigned.
    await tester.tap(find.text('Cancel').first);
    await tester.pump(); // allow scaffoldMessenger snack bar to schedule
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    expect(find.text('Research slot cancelled'), findsOneWidget);
    expect(captured, isNotNull);
    expect(
      captured!.researchOrdersByPlayerId[withOrder.id],
      isEmpty,
    );
  });
}

Player _dummyPlayer() {
  return Player(
    id: 'dummy',
    displayName: 'Dummy',
    isHuman: true,
  );
}
