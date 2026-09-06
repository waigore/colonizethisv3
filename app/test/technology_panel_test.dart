// Tests for TechnologyPanel. UXD 03k — research slots and researched techs.
// Cancel/snackbar pin: technology_panel_cancel_snackbar_test.dart (Refs #4734 Slice F).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology/technology_panel.dart';

import 'panel_test_fixtures.dart';
import 'technology_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Player player;

  setUpAll(() {
    game = buildTechnologyPanelTestGame();
    player = game.players.isNotEmpty ? game.players.first : _dummyPlayer();
  });

  testWidgets(
    'TechnologyPanel builds and omits the dev-only header block (Refs #3510)',
    (WidgetTester tester) async {
      await pumpTechnologyPanel(
        tester,
        game: game,
        player: player,
        wrapInScrollView: true,
      );
      expect(find.byType(TechnologyPanel), findsOneWidget);
      expect(find.textContaining('Technology - '), findsNothing);
      expect(find.textContaining('Research slots:'), findsNothing);
      expect(find.text('Researched Techs'), findsOneWidget);
      expect(find.text('None yet'), findsOneWidget);
    },
  );

  testWidgets(
    'TechnologyPanel hides edit controls when onOrdersChanged is null',
    (WidgetTester tester) async {
      final techId = techCatalog.keys.first;
      final withTech = player.copyWith(techUnlocked: {techId: true});
      final gameWithTechs = game.copyWith(
        players: [withTech, ...game.players.skip(1)],
      );

      await pumpTechnologyPanel(
        tester,
        game: gameWithTechs,
        player: withTech,
        wrapInScrollView: true,
      );

      expect(find.text('Choose tech'), findsNothing);
      expect(find.text('Cancel'), findsNothing);
    },
  );

  testWidgets('TechnologyPanel shows None yet when no researched techs', (
    WidgetTester tester,
  ) async {
    final emptyPlayer = player.copyWith(techUnlocked: <String, bool>{});
    final gameWithEmpty = game.copyWith(
      players: [emptyPlayer, ...game.players.skip(1)],
    );
    await pumpTechnologyPanel(
      tester,
      game: gameWithEmpty,
      player: emptyPlayer,
      wrapInScrollView: true,
    );
    expect(find.text('None yet'), findsOneWidget);
    expect(find.byType(Chip), findsNothing);
    expect(find.byType(ResearchedTechChip), findsNothing);
  });

  testWidgets(
    'TechnologyPanel shows researched tech chips when player has techs',
    (WidgetTester tester) async {
      final ids = techCatalog.keys.take(3).toList();
      final techUnlocked = {for (final id in ids) id: true};
      final withTechs = player.copyWith(techUnlocked: techUnlocked);
      final gameWithTechs = game.copyWith(
        players: [withTechs, ...game.players.skip(1)],
      );
      await pumpTechnologyPanel(
        tester,
        game: gameWithTechs,
        player: withTechs,
        wrapInScrollView: true,
      );
      expect(find.text('Researched Techs'), findsOneWidget);
      expect(find.byType(ResearchedTechChip), findsNWidgets(3));
      expect(find.byType(Chip), findsNothing);
    },
  );

  testWidgets(
    'TechnologyPanel renders no standalone In-Progress block (Refs #3512)',
    (WidgetTester tester) async {
      final techId = techCatalog.keys.first;
      final withProgress = player.copyWith(
        researchProgressByTechId: {techId: 50},
      );
      final gameWithProgress = game.copyWith(
        players: [withProgress, ...game.players.skip(1)],
      );
      await pumpTechnologyPanel(
        tester,
        game: gameWithProgress,
        player: withProgress,
        wrapInScrollView: true,
      );
      expect(find.text('IN PROGRESS:'), findsNothing);
      expect(find.text('In progress:'), findsNothing);
    },
  );

  testWidgets(
    'TechnologyPanel omits the research-slot count line even at 4 slots (Refs #3510)',
    (WidgetTester tester) async {
      const slots = 4;
      final withSlots = player.copyWith(researchSlots: slots);
      final gameWithSlots = game.copyWith(
        players: [withSlots, ...game.players.skip(1)],
      );
      await pumpTechnologyPanel(
        tester,
        game: gameWithSlots,
        player: withSlots,
        wrapInScrollView: true,
      );
      expect(find.textContaining('Research slots:'), findsNothing);
      expect(find.byType(ResearchSlotCard), findsNWidgets(4));
      expect(find.byType(LockedResearchSlotCard), findsNothing);
    },
  );

  testWidgets(
    'Locked Slot 4 renders the same width as the active slot cards (Refs #3510)',
    (WidgetTester tester) async {
      final withLockedSlot = player.copyWith(researchSlots: 3);
      final gameWithLockedSlot = game.copyWith(
        players: [withLockedSlot, ...game.players.skip(1)],
      );
      await pumpTechnologyPanel(
        tester,
        game: gameWithLockedSlot,
        player: withLockedSlot,
        wrapInScrollView: true,
        bodyWidth: 600,
      );

      expect(find.byType(ResearchSlotCard), findsNWidgets(3));
      expect(find.byType(LockedResearchSlotCard), findsOneWidget);

      final double lockedWidth = tester
          .getSize(find.byType(LockedResearchSlotCard))
          .width;
      final List<double> activeWidths = <double>[
        for (final element in find.byType(ResearchSlotCard).evaluate())
          tester.getSize(find.byWidget(element.widget)).width,
      ];
      expect(activeWidths, isNotEmpty);
      for (final double activeWidth in activeWidths) {
        expect(
          (lockedWidth - activeWidth).abs(),
          lessThanOrEqualTo(1.0),
        );
      }
    },
  );
}

Player _dummyPlayer() {
  return Player(id: 'dummy', displayName: 'Dummy', isHuman: true);
}
