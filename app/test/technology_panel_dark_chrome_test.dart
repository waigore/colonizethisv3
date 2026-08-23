// Dark editorial-monocle visual ACs for TechnologyPanel.
// (Refs #4021).
// Refs #2864 — S0 locked-slot rule + S2 researched-chip grid + S3 slot
// cards with locked slot 4 dim. SPEC/ui/technology-panel.md § Slot
// behaviour + § Layout / wireframe.
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_danger_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/technology/technology_panel.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';

import 'panel_test_fixtures.dart';
import 'technology_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Player basePlayer;

  setUpAll(() {
    game = buildTechnologyPanelTestGame();
    basePlayer = game.players.first;
  });

  Future<(Game, Player)> pumpPlayer(
    WidgetTester tester, {
    int? researchSlots = 3,
    Map<String, bool>? techUnlocked,
    Orders orders = const Orders(),
    Map<String, int>? researchProgressByTechId,
    Size? viewSize,
  }) async {
    if (viewSize != null) {
      tester.view.physicalSize = viewSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }
    var player = basePlayer.copyWith(
      researchSlots: researchSlots,
      techUnlocked: techUnlocked,
    );
    if (researchProgressByTechId != null) {
      player = player.copyWith(
        researchProgressByTechId: researchProgressByTechId,
      );
    }
    final localGame = game.copyWith(players: [player, ...game.players.skip(1)]);
    final panelPlayer = researchProgressByTechId != null
        ? localGame.players.first
        : player;
    await pumpTechnologyPanel(
      tester,
      game: localGame,
      player: panelPlayer,
      currentOrders: orders,
      onOrdersChanged: (_) {},
      wrapInScrollView: true,
    );
    return (localGame, panelPlayer);
  }

  Orders mediumOrder(Player p, String techId) => Orders(
    researchOrdersByPlayerId: {
      p.id: [
        ResearchOrder(
          slotIndex: 0,
          techId: techId,
          funding: ResearchFundingLevel.medium,
        ),
      ],
    },
  );

  group('Slots tab always renders four slot cards (Refs #2864 AC always-4)', () {
    for (final c
        in <
          ({
            String name,
            int? slots,
            int active,
            Matcher locked,
            Matcher slot4,
            Matcher slot4University,
            Matcher? requiresUniversity,
          })
        >[
          (
            name: 'researchSlots = 3 renders three active + one locked',
            slots: 3,
            active: 3,
            locked: findsOneWidget,
            slot4: findsNothing,
            slot4University: findsOneWidget,
            requiresUniversity: null,
          ),
          (
            name: 'researchSlots = 4 renders four active, no locked',
            slots: 4,
            active: 4,
            locked: findsNothing,
            slot4: findsOneWidget,
            slot4University: findsNothing,
            requiresUniversity: findsNothing,
          ),
          (
            name:
                'researchSlots = null still renders four-card grid (locked slot 4)',
            slots: null,
            active: 3,
            locked: findsOneWidget,
            slot4: findsNothing,
            slot4University: findsNothing,
            requiresUniversity: null,
          ),
        ]) {
      testWidgets(c.name, (WidgetTester tester) async {
        await pumpPlayer(tester, researchSlots: c.slots);
        expect(find.byType(ResearchSlotCard), findsNWidgets(c.active));
        expect(find.byType(LockedResearchSlotCard), c.locked);
        if (c.slots == 3) {
          expect(find.text('Slot 4'), c.slot4);
          expect(find.text('Slot 4 (University)'), c.slot4University);
        } else if (c.slots == 4) {
          expect(find.text('Slot 4'), c.slot4);
          expect(find.text('Slot 4 (University)'), c.slot4University);
          expect(find.text('Requires University tech'), c.requiresUniversity!);
        }
      });
    }
  });

  group('Locked slot 4 rule (Refs #2864 AC locked-slot)', () {
    testWidgets('locked slot card opacity is exactly 0.45', (
      WidgetTester tester,
    ) async {
      await pumpPlayer(tester);
      final opacity = tester.widget<Opacity>(
        find.descendant(
          of: find.byType(LockedResearchSlotCard),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, kTechnologyLockedSlotOpacity);
      expect(kTechnologyLockedSlotOpacity, 0.45);
    });

    testWidgets(
      'locked slot 4 shows footnote and no Cancel / Choose tech buttons',
      (WidgetTester tester) async {
        await pumpPlayer(tester);
        expect(find.text('Requires University tech'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(LockedResearchSlotCard),
            matching: find.byType(CtActionTextButton),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(LockedResearchSlotCard),
            matching: find.byType(CtDangerTextButton),
          ),
          findsNothing,
        );
        expect(
          find.descendant(
            of: find.byType(LockedResearchSlotCard),
            matching: find.byType(CtNinePatchButton),
          ),
          findsNothing,
        );
        expect(find.text('Choose tech'), findsWidgets);
      },
    );

    testWidgets(
      'negative: at researchSlots = 4, no locked footnote / locked card chrome',
      (WidgetTester tester) async {
        await pumpPlayer(tester, researchSlots: 4);
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
        await pumpPlayer(
          tester,
          techUnlocked: {for (final id in ids) id: true},
        );

        expect(find.byType(ResearchedTechChip), findsNWidgets(2));
        expect(find.byType(TechSectionHeading), findsNWidgets(2));
        expect(find.text('Researched Techs'), findsOneWidget);
        expect(find.text('Research Slots'), findsOneWidget);
        expect(find.text('RESEARCHED TECHS'), findsNothing);
        expect(find.text('RESEARCH SLOTS'), findsNothing);
      },
    );

    testWidgets(
      'negative: no Material `Chip` and no Material `Divider` on the dark surface',
      (WidgetTester tester) async {
        final ids = techCatalog.keys.take(3).toList();
        await pumpPlayer(
          tester,
          techUnlocked: {for (final id in ids) id: true},
        );

        expect(find.byType(Chip), findsNothing);
        expect(find.byType(Divider), findsNothing);
        expect(find.byType(CtBrassDivider), findsOneWidget);
      },
    );
  });

  group('Slots-tab section ordering (Refs #2864 S0/S6 ordering AC)', () {
    for (final c in <({String name, Map<String, bool> unlocked})>[
      (
        name:
            'Researched Techs heading renders strictly above Research Slots heading',
        unlocked: {for (final id in techCatalog.keys.take(2)) id: true},
      ),
      (
        name:
            'ordering holds with zero researched techs (empty-state precedes slots)',
        unlocked: <String, bool>{},
      ),
    ]) {
      testWidgets(c.name, (WidgetTester tester) async {
        await pumpPlayer(tester, techUnlocked: c.unlocked);
        final researchedHeadingY = tester
            .getTopLeft(find.text('Researched Techs'))
            .dy;
        final slotsHeadingY = tester.getTopLeft(find.text('Research Slots')).dy;
        expect(
          researchedHeadingY,
          lessThan(slotsHeadingY),
          reason:
              'SPEC/ui/technology-panel.md § Slots tab — section ordering '
              '(Refs #2864 S0/S6) requires the Researched Techs heading to '
              'render strictly above the Research Slots heading.',
        );
      });
    }
  });
}
