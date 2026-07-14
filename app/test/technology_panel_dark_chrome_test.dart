// Dark editorial-monocle visual ACs for TechnologyPanel.
// Shared pump + table-driven slot/heading cases densify mid-size suite
// (Refs #4021).
//
// Refs #2864 — S0 locked-slot rule + S2 researched-chip grid + S3 slot
// cards with locked slot 4 dim. SPEC/ui/technology-panel.md § Slot
// behaviour + § Layout / wireframe.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_action_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/chrome/ct_danger_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/technology/research_slot_turn_preview_view.dart';
import 'package:colonizethis_app/features/game/widgets/technology/technology_panel.dart';
import 'package:colonizethis_app_ui_chrome/widgets/ct_brass_divider.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_progress_bar.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';

import 'support/panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Player basePlayer;

  setUpAll(() {
    game = buildTechnologyPanelTestGame();
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
    final localGame = game.copyWith(
      players: [player, ...game.players.skip(1)],
    );
    final panelPlayer = researchProgressByTechId != null
        ? localGame.players.first
        : player;
    await tester.pumpWidget(host(localGame, panelPlayer, orders: orders));
    await tester.pumpAndSettle();
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
    for (final c in <({
      String name,
      int? slots,
      int active,
      Matcher locked,
      Matcher slot4,
      Matcher slot4University,
      Matcher? requiresUniversity,
    })>[
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
        name: 'researchSlots = null still renders four-card grid (locked slot 4)',
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
    testWidgets(
      'locked slot card opacity is exactly 0.45',
      (WidgetTester tester) async {
        await pumpPlayer(tester);
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
    for (final c in <({
      String name,
      Map<String, bool> unlocked,
    })>[
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
        final researchedHeadingY =
            tester.getTopLeft(find.text('Researched Techs')).dy;
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

  group('Mockup-faithful canonical heading style (Refs #3510)', () {
    Future<void> pumpWithTwoTechs(WidgetTester tester) {
      final ids = techCatalog.keys.take(2).toList();
      return pumpPlayer(
        tester,
        techUnlocked: {for (final id in ids) id: true},
      );
    }

    testWidgets(
      'positive: both canonical headings render via TechSectionHeading with '
      'accent Cinzel display style and literal (non-upper-cased) text',
      (WidgetTester tester) async {
        await pumpWithTwoTechs(tester);

        expect(find.byType(TechSectionHeading), findsNWidgets(2));
        for (final label in <String>['Researched Techs', 'Research Slots']) {
          final Text headingText = tester.widget<Text>(
            find.descendant(
              of: find.widgetWithText(TechSectionHeading, label),
              matching: find.text(label),
            ),
          );
          final style = headingText.style;
          expect(style, isNotNull);
          expect(style!.color, EditorialMonoclePalette.accent);
          expect(style.fontFamily, editorialMonocleDisplayFontFamily);
          expect(style.fontWeight, FontWeight.w600);
          expect(headingText.data, label);
        }
      },
    );

    testWidgets(
      'negative: neither canonical heading renders via CtSectionLabel',
      (WidgetTester tester) async {
        await pumpWithTwoTechs(tester);

        expect(find.text('RESEARCHED TECHS'), findsNothing);
        expect(find.text('RESEARCH SLOTS'), findsNothing);
        expect(find.byType(CtSectionLabel), findsNothing);
      },
    );
  });

  group('Compact slot action controls (Refs #3510)', () {
    testWidgets(
      'positive: Choose tech uses CtActionTextButton and Cancel uses '
      'CtDangerTextButton (no heavy nine-patch chrome on slot actions)',
      (WidgetTester tester) async {
        final techId = techCatalog.keys.first;
        final player = basePlayer.copyWith(researchSlots: 3);
        await pumpPlayer(
          tester,
          orders: mediumOrder(player, techId),
        );

        expect(find.byType(CtActionTextButton), findsWidgets);
        expect(find.byType(CtDangerTextButton), findsOneWidget);
        expect(find.byType(CtNinePatchButton), findsNothing);
        expect(find.text('Choose tech'), findsWidgets);
        expect(find.text('Cancel'), findsOneWidget);
      },
    );

    testWidgets(
      'mobile (360 dp): each slot action control reports a >= 44 dp tap target',
      (WidgetTester tester) async {
        final techId = techCatalog.keys.first;
        final player = basePlayer.copyWith(researchSlots: 3);
        await pumpPlayer(
          tester,
          viewSize: const Size(360, 1200),
          orders: mediumOrder(player, techId),
        );

        for (final Element element in <Element>[
          ...find.byType(CtActionTextButton).evaluate(),
          ...find.byType(CtDangerTextButton).evaluate(),
        ]) {
          final Size size = tester.getSize(find.byWidget(element.widget));
          expect(size.width, greaterThanOrEqualTo(kMinTouchTargetSize));
          expect(size.height, greaterThanOrEqualTo(kMinTouchTargetSize));
        }
      },
    );

    testWidgets(
      'desktop (>= 600 dp): compact slot action controls stay below 44 dp',
      (WidgetTester tester) async {
        await pumpPlayer(
          tester,
          techUnlocked: <String, bool>{},
          viewSize: const Size(1000, 1200),
        );

        final Size chooseSize =
            tester.getSize(find.byType(CtActionTextButton).first);
        expect(chooseSize.height, lessThan(kMinTouchTargetSize));
      },
    );
  });

  group('Slot card chrome (Refs #2864 AC S3)', () {
    testWidgets(
      'editable assigned slot uses the dual-segment turn preview and the '
      'canonical RP label format (Refs #3512)',
      (WidgetTester tester) async {
        final techId = techCatalog.keys.first;
        final techCost = techCatalog[techId]!.cost;
        final player = basePlayer.copyWith(researchSlots: 3);
        await pumpPlayer(
          tester,
          researchProgressByTechId: {techId: 17},
          orders: mediumOrder(player, techId),
        );

        expect(find.byType(ResearchSlotTurnPreviewView), findsOneWidget);
        expect(find.byType(CtProgressBar), findsNothing);
        expect(find.text('17 / $techCost RP'), findsOneWidget);
      },
    );

    testWidgets(
      'empty slot shows "No tech assigned" italic muted line and no progress bar',
      (WidgetTester tester) async {
        await pumpPlayer(tester, techUnlocked: <String, bool>{});

        expect(find.text('No tech assigned'), findsNWidgets(3));
        expect(find.byType(CtProgressBar), findsNothing);
      },
    );
  });
}
