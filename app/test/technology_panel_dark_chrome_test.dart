// Dark editorial-monocle visual ACs for TechnologyPanel.
//
// Refs #2864 — S0 locked-slot rule + S2 researched-chip grid + S3 slot
// cards with locked slot 4 dim. SPEC/ui/technology-panel.md § Slot
// behaviour + § Layout / wireframe.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology_panel.dart';
import 'package:colonizethis_app/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_progress_bar.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Player basePlayer;

  setUpAll(() {
    final result = getDebugInitGameResult();
    game = result.game;
    basePlayer = game.players.first;
  });

  Widget host(Game g, Player p, {Orders orders = const Orders()}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TechnologyPanel(
            game: g,
            player: p,
            currentOrders: orders,
            onOrdersChanged: (_) {},
          ),
        ),
      ),
    );
  }

  group('Slots tab always renders four slot cards (Refs #2864 AC always-4)', () {
    testWidgets('player.researchSlots = 3 renders three active + one locked', (
      WidgetTester tester,
    ) async {
      final player = basePlayer.copyWith(researchSlots: 3);
      final localGame = game.copyWith(
        players: [player, ...game.players.skip(1)],
      );
      await tester.pumpWidget(host(localGame, player));
      await tester.pumpAndSettle();

      expect(find.byType(ResearchSlotCard), findsNWidgets(3));
      expect(find.byType(LockedResearchSlotCard), findsOneWidget);
      // Sanity: the active slot label is "Slot 4" only when slots >= 4.
      expect(find.text('Slot 4'), findsNothing);
      expect(find.text('Slot 4 (University)'), findsOneWidget);
    });

    testWidgets('player.researchSlots = 4 renders four active, no locked', (
      WidgetTester tester,
    ) async {
      final player = basePlayer.copyWith(researchSlots: 4);
      final localGame = game.copyWith(
        players: [player, ...game.players.skip(1)],
      );
      await tester.pumpWidget(host(localGame, player));
      await tester.pumpAndSettle();

      expect(find.byType(ResearchSlotCard), findsNWidgets(4));
      expect(find.byType(LockedResearchSlotCard), findsNothing);
      expect(find.text('Slot 4'), findsOneWidget);
      expect(find.text('Slot 4 (University)'), findsNothing);
      expect(find.text('Requires University tech'), findsNothing);
    });

    testWidgets(
      'player.researchSlots = null still renders the four-card grid (locked slot 4)',
      (WidgetTester tester) async {
        final player = basePlayer.copyWith(researchSlots: null);
        final localGame = game.copyWith(
          players: [player, ...game.players.skip(1)],
        );
        await tester.pumpWidget(host(localGame, player));
        await tester.pumpAndSettle();

        expect(find.byType(ResearchSlotCard), findsNWidgets(3));
        expect(find.byType(LockedResearchSlotCard), findsOneWidget);
      },
    );
  });

  group('Locked slot 4 rule (Refs #2864 AC locked-slot)', () {
    testWidgets(
      'locked slot card opacity is exactly 0.45',
      (WidgetTester tester) async {
        final player = basePlayer.copyWith(researchSlots: 3);
        final localGame = game.copyWith(
          players: [player, ...game.players.skip(1)],
        );
        await tester.pumpWidget(host(localGame, player));
        await tester.pumpAndSettle();

        final opacity = tester.widget<Opacity>(
          find.descendant(
            of: find.byType(LockedResearchSlotCard),
            matching: find.byType(Opacity),
          ),
        );
        expect(opacity.opacity, kTechnologyLockedSlotOpacity);
        expect(kTechnologyLockedSlotOpacity, 0.45);
      },
    );

    testWidgets(
      'locked slot 4 shows footnote and no Cancel / Choose tech buttons',
      (WidgetTester tester) async {
        final player = basePlayer.copyWith(researchSlots: 3);
        final localGame = game.copyWith(
          players: [player, ...game.players.skip(1)],
        );
        await tester.pumpWidget(host(localGame, player));
        await tester.pumpAndSettle();

        expect(find.text('Requires University tech'), findsOneWidget);
        // Verify the locked card itself contains no action buttons.
        expect(
          find.descendant(
            of: find.byType(LockedResearchSlotCard),
            matching: find.byType(CtNinePatchButton),
          ),
          findsNothing,
        );
        // Sanity: the active slots still have a Choose tech button.
        expect(find.text('Choose tech'), findsWidgets);
      },
    );

    testWidgets(
      'negative: at researchSlots = 4, no locked footnote / locked card chrome',
      (WidgetTester tester) async {
        final player = basePlayer.copyWith(researchSlots: 4);
        final localGame = game.copyWith(
          players: [player, ...game.players.skip(1)],
        );
        await tester.pumpWidget(host(localGame, player));
        await tester.pumpAndSettle();

        expect(find.byType(LockedResearchSlotCard), findsNothing);
        expect(find.text('Requires University tech'), findsNothing);
      },
    );
  });

  group('Researched-tech chip grid (Refs #2864 AC S2)', () {
    testWidgets(
      'positive: renders ResearchedTechChip per researched tech under dark heading',
      (WidgetTester tester) async {
        final ids = techCatalog.keys.take(2).toList();
        final unlocked = {for (final id in ids) id: true};
        final player = basePlayer.copyWith(techUnlocked: unlocked);
        final localGame = game.copyWith(
          players: [player, ...game.players.skip(1)],
        );
        await tester.pumpWidget(host(localGame, player));
        await tester.pumpAndSettle();

        expect(find.byType(ResearchedTechChip), findsNWidgets(2));
        expect(find.byType(CtSectionLabel), findsWidgets);
        expect(find.text('RESEARCHED TECHS'), findsOneWidget);
        expect(find.text('RESEARCH SLOTS'), findsOneWidget);
      },
    );

    testWidgets(
      'negative: no Material `Chip` and no Material `Divider` on the dark surface',
      (WidgetTester tester) async {
        final ids = techCatalog.keys.take(3).toList();
        final unlocked = {for (final id in ids) id: true};
        final player = basePlayer.copyWith(techUnlocked: unlocked);
        final localGame = game.copyWith(
          players: [player, ...game.players.skip(1)],
        );
        await tester.pumpWidget(host(localGame, player));
        await tester.pumpAndSettle();

        expect(find.byType(Chip), findsNothing);
        expect(find.byType(Divider), findsNothing);
        expect(find.byType(CtBrassDivider), findsOneWidget);
      },
    );
  });

  group('Slots-tab section ordering (Refs #2864 S0/S6 ordering AC)', () {
    testWidgets(
      'positive: RESEARCHED TECHS heading renders strictly above RESEARCH SLOTS heading (Offset.dy)',
      (WidgetTester tester) async {
        // Mix of researched techs (drives the chip grid) and at least
        // one in-progress tech (exercises the auxiliary section without
        // disturbing the primary ordering invariant).
        final ids = techCatalog.keys.take(2).toList();
        final unlocked = {for (final id in ids) id: true};
        final player = basePlayer.copyWith(
          researchSlots: 3,
          techUnlocked: unlocked,
        );
        final localGame = game.copyWith(
          players: [player, ...game.players.skip(1)],
        );
        await tester.pumpWidget(host(localGame, player));
        await tester.pumpAndSettle();

        final researchedHeadingY =
            tester.getTopLeft(find.text('RESEARCHED TECHS')).dy;
        final slotsHeadingY =
            tester.getTopLeft(find.text('RESEARCH SLOTS')).dy;
        expect(
          researchedHeadingY,
          lessThan(slotsHeadingY),
          reason:
              'SPEC/ui/technology-panel.md § Slots tab — section ordering '
              '(Refs #2864 S0/S6) requires the Researched Techs heading to '
              'render strictly above the Research Slots heading; matches '
              'mockup .researched-heading precedes .slots-heading.',
        );
      },
    );

    testWidgets(
      'positive: ordering holds even when the player has zero researched techs '
      '(empty-state line still precedes the slots heading)',
      (WidgetTester tester) async {
        final player = basePlayer.copyWith(
          researchSlots: 3,
          techUnlocked: <String, bool>{},
        );
        final localGame = game.copyWith(
          players: [player, ...game.players.skip(1)],
        );
        await tester.pumpWidget(host(localGame, player));
        await tester.pumpAndSettle();

        final researchedHeadingY =
            tester.getTopLeft(find.text('RESEARCHED TECHS')).dy;
        final slotsHeadingY =
            tester.getTopLeft(find.text('RESEARCH SLOTS')).dy;
        expect(researchedHeadingY, lessThan(slotsHeadingY));
      },
    );
  });

  group('Slot card chrome (Refs #2864 AC S3)', () {
    testWidgets(
      'assigned slot uses CtProgressBar and the canonical RP label format',
      (WidgetTester tester) async {
        final techId = techCatalog.keys.first;
        final techCost = techCatalog[techId]!.cost;
        final player = basePlayer.copyWith(researchSlots: 3);
        final localGame = game.copyWith(
          players: [
            player.copyWith(researchProgressByTechId: {techId: 17}),
            ...game.players.skip(1),
          ],
        );
        final orders = Orders(
          researchOrdersByPlayerId: {
            player.id: [
              ResearchOrder(
                slotIndex: 0,
                techId: techId,
                funding: ResearchFundingLevel.medium,
              ),
            ],
          },
        );
        await tester.pumpWidget(host(localGame, localGame.players.first, orders: orders));
        await tester.pumpAndSettle();

        expect(find.byType(CtProgressBar), findsOneWidget);
        expect(find.text('17 / $techCost RP'), findsOneWidget);
      },
    );

    testWidgets(
      'empty slot shows "No tech assigned" italic muted line and no progress bar',
      (WidgetTester tester) async {
        final player = basePlayer.copyWith(
          researchSlots: 3,
          techUnlocked: <String, bool>{},
        );
        final localGame = game.copyWith(
          players: [player, ...game.players.skip(1)],
        );
        await tester.pumpWidget(host(localGame, player));
        await tester.pumpAndSettle();

        // All three active slots are unassigned → all show "No tech
        // assigned" and no progress bar exists.
        expect(find.text('No tech assigned'), findsNWidgets(3));
        expect(find.byType(CtProgressBar), findsNothing);
      },
    );
  });
}
