// Slot-card and section-ordering ACs split from headings (Refs #4734 Slice F).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology/research_slot_turn_preview_view.dart';
import 'package:colonizethis_app/widgets/ct_progress_bar.dart';

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
  }) async {
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
        expect(researchedHeadingY, lessThan(slotsHeadingY));
      });
    }
  });
}
