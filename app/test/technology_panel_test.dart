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

  testWidgets(
    'TechnologyPanel builds and omits the dev-only header block (Refs #3510)',
    (WidgetTester tester) async {
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
    // SPEC/ui/technology-panel.md § Slots tab — section ordering: the body
    // MUST NOT render the legacy dev-only header block (per-player title
    // `Technology - {name}` or `Research slots: N` count line). Refs #3510.
    expect(find.textContaining('Technology - '), findsNothing);
    expect(find.textContaining('Research slots:'), findsNothing);
    // Body opens directly with the Researched Techs section heading, rendered
    // via the mockup-faithful TechSectionHeading (normal case). Refs #3510.
    expect(find.text('Researched Techs'), findsOneWidget);
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
    // Dark theme heading (mockup-faithful TechSectionHeading, normal case)
    // + three custom chip primitives (Refs #2864 S2 / #3510).
    expect(find.text('Researched Techs'), findsOneWidget);
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

  testWidgets(
    'TechnologyPanel omits the research-slot count line even at 4 slots (Refs #3510)',
    (WidgetTester tester) async {
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
    // The dev-only count line is removed regardless of slot count; with
    // 4 active slots there is also no locked placeholder. Refs #3510.
    expect(find.textContaining('Research slots:'), findsNothing);
    expect(find.byType(ResearchSlotCard), findsNWidgets(4));
    expect(find.byType(LockedResearchSlotCard), findsNothing);
  });

  testWidgets(
    'Locked Slot 4 renders the same width as the active slot cards (Refs #3510)',
    (WidgetTester tester) async {
    final withLockedSlot = player.copyWith(researchSlots: 3);
    final gameWithLockedSlot = game.copyWith(
      players: [withLockedSlot, ...game.players.skip(1)],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: TechnologyPanel(
                game: gameWithLockedSlot,
                player: withLockedSlot,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ResearchSlotCard), findsNWidgets(3));
    expect(find.byType(LockedResearchSlotCard), findsOneWidget);

    final double lockedWidth =
        tester.getSize(find.byType(LockedResearchSlotCard)).width;
    final List<double> activeWidths = <double>[
      for (final element in find.byType(ResearchSlotCard).evaluate())
        tester.getSize(find.byWidget(element.widget)).width,
    ];
    expect(activeWidths, isNotEmpty);
    for (final double activeWidth in activeWidths) {
      expect(
        (lockedWidth - activeWidth).abs(),
        lessThanOrEqualTo(1.0),
        reason:
            'SPEC/ui/technology-panel.md § Slot behaviour > Locked slot 4: '
            'the locked Slot 4 card must render at the same width as the '
            'active slot cards (Refs #3510).',
      );
    }
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
    // Scroll the button into view first: SPEC/ui/technology-panel.md §
    // Slots tab — section ordering (Refs #2864 S0/S6) places the
    // Researched Techs grid above the Research Slots block, and with
    // every tech unlocked the chip grid pushes the first slot card's
    // "Choose tech" button below the default 800×600 test viewport.
    final chooseTech = find.text('Choose tech').first;
    await tester.ensureVisible(chooseTech);
    await tester.pumpAndSettle();
    await tester.tap(chooseTech);
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
