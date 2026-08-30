// Remaining TechnologyPanel heading/slot-action ACs (Refs #4606 Slice D).
// SPEC/ui/technology-panel.md. Host: technology_panel_dark_chrome_test.dart.
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/config/constants.dart';
import 'package:colonizethis_app_ui_chrome/config/editorial_monocle_palette.dart';
import 'package:colonizethis_app/config/themes.dart'
    show editorialMonocleDisplayFontFamily;
import 'package:colonizethis_app/widgets/ct_action_text_button.dart';
import 'package:colonizethis_app/widgets/ct_danger_text_button.dart';
import 'package:colonizethis_app/features/game/widgets/technology/research_slot_turn_preview_view.dart';
import 'package:colonizethis_app/features/game/widgets/technology/technology_panel.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_app/widgets/ct_progress_bar.dart';
import 'package:colonizethis_app/widgets/ct_section_label.dart';

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

  group('Mockup-faithful canonical heading style (Refs #3510)', () {
    Future<void> pumpWithTwoTechs(WidgetTester tester) {
      final ids = techCatalog.keys.take(2).toList();
      return pumpPlayer(tester, techUnlocked: {for (final id in ids) id: true});
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
    testWidgets('positive: Choose tech uses CtActionTextButton and Cancel uses '
        'CtDangerTextButton (no heavy nine-patch chrome on slot actions)', (
      WidgetTester tester,
    ) async {
      final techId = techCatalog.keys.first;
      final player = basePlayer.copyWith(researchSlots: 3);
      await pumpPlayer(tester, orders: mediumOrder(player, techId));

      expect(find.byType(CtActionTextButton), findsWidgets);
      expect(find.byType(CtDangerTextButton), findsOneWidget);
      expect(find.byType(CtNinePatchButton), findsNothing);
      expect(find.text('Choose tech'), findsWidgets);
      expect(find.text('Cancel'), findsOneWidget);
    });

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

        final Size chooseSize = tester.getSize(
          find.byType(CtActionTextButton).first,
        );
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
