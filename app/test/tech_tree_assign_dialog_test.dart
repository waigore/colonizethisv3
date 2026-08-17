// Tree node dialog assignment (Refs #4498). SPEC/ui/tech-tree-widget.md.

import 'package:colonizethis_app/features/game/widgets/technology/tech_definition_detail_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_tree_widget.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_tree_widget_nodes.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Player player;

  setUpAll(() {
    game = buildTechnologyPanelTestGame();
    player = game.players.first;
  });

  Future<void> pumpTree(
    WidgetTester tester, {
    required Game g,
    required Player p,
    Orders orders = const Orders(),
    void Function(Orders orders)? onOrdersChanged,
  }) async {
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: TechTreeWidget(
            game: g,
            player: p,
            currentOrders: orders,
            onOrdersChanged: onOrdersChanged,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> openNode(WidgetTester tester, String displayName) async {
    final node = find.text(displayName).first;
    await tester.ensureVisible(node);
    await tester.tap(node);
    await tester.pumpAndSettle();
    expect(find.byType(CtDialogShell), findsOneWidget);
  }

  testWidgets(
    'AC: Research this assigns lowest empty seat at Medium and closes dialog',
    (tester) async {
      Orders? captured;
      final empty = player.copyWith(techUnlocked: <String, bool>{});
      final g = game.copyWith(players: [empty, ...game.players.skip(1)]);
      await pumpTree(
        tester,
        g: g,
        p: empty,
        onOrdersChanged: (o) => captured = o,
      );
      await openNode(tester, techDisplayName(kTechIdCropRotation));
      expect(find.byKey(const Key('techTreeResearchThis')), findsOneWidget);
      await tester.tap(find.byKey(const Key('techTreeResearchThis')));
      await tester.pumpAndSettle();
      expect(find.byType(CtDialogShell), findsNothing);
      expect(captured, isNotNull);
      final orders = captured!.researchOrdersByPlayerId[empty.id]!;
      expect(orders, hasLength(1));
      expect(orders.single.slotIndex, 0);
      expect(orders.single.techId, kTechIdCropRotation);
      expect(orders.single.funding, ResearchFundingLevel.medium);
    },
  );

  testWidgets(
    'AC: all seats full shows replace list; dismiss forfeit leaves orders unchanged',
    (tester) async {
      Orders? captured;
      final withPrereq = player.copyWith(
        techUnlocked: {kTechIdCropRotation: true},
        researchSlots: 3,
        researchSlotAssignments: {
          0: const ResearchSlotAssignment(
            techId: kTechIdSawMill,
            funding: ResearchFundingLevel.medium,
          ),
          1: const ResearchSlotAssignment(
            techId: kTechIdLandEnclosure,
            funding: ResearchFundingLevel.medium,
          ),
          2: const ResearchSlotAssignment(
            techId: kTechIdIronMining,
            funding: ResearchFundingLevel.medium,
          ),
        },
        researchProgressByTechId: {kTechIdSawMill: 40},
      );
      final g2 = game.copyWith(players: [withPrereq, ...game.players.skip(1)]);
      await pumpTree(
        tester,
        g: g2,
        p: withPrereq,
        onOrdersChanged: (o) => captured = o,
      );
      await openNode(tester, techDisplayName(kTechIdSheepRanching));
      expect(find.byKey(const Key('techTreeResearchThis')), findsNothing);
      expect(find.byKey(const Key('techTreeReplaceSeat_0')), findsOneWidget);
      await tester.tap(find.byKey(const Key('techTreeReplaceSeat_0')));
      await tester.pumpAndSettle();
      expect(find.text('Forfeit research progress?'), findsOneWidget);
      await tester.tap(find.text('Keep researching'));
      await tester.pumpAndSettle();
      expect(captured, isNull);
      expect(find.byType(CtDialogShell), findsWidgets);
    },
  );

  testWidgets(
    'AC: replace seat with forfeit confirm reassigns via applyAssignTechToSlot',
    (tester) async {
      Orders? captured;
      final withPrereq = player.copyWith(
        techUnlocked: {kTechIdCropRotation: true},
        researchSlots: 3,
        researchSlotAssignments: {
          0: const ResearchSlotAssignment(
            techId: kTechIdSawMill,
            funding: ResearchFundingLevel.medium,
          ),
          1: const ResearchSlotAssignment(
            techId: kTechIdLandEnclosure,
            funding: ResearchFundingLevel.medium,
          ),
          2: const ResearchSlotAssignment(
            techId: kTechIdIronMining,
            funding: ResearchFundingLevel.medium,
          ),
        },
        researchProgressByTechId: {kTechIdSawMill: 40},
      );
      final g = game.copyWith(players: [withPrereq, ...game.players.skip(1)]);
      await pumpTree(
        tester,
        g: g,
        p: withPrereq,
        onOrdersChanged: (o) => captured = o,
      );
      await openNode(tester, techDisplayName(kTechIdSheepRanching));
      await tester.tap(find.byKey(const Key('techTreeReplaceSeat_0')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Forfeit'));
      await tester.pumpAndSettle();
      expect(find.byType(CtDialogShell), findsNothing);
      expect(captured, isNotNull);
      final order = captured!.researchOrdersByPlayerId[withPrereq.id]!
          .firstWhere((o) => o.slotIndex == 0);
      expect(order.techId, kTechIdSheepRanching);
    },
  );

  testWidgets(
    'AC: locked tech shows waiting-on reason without Research this',
    (tester) async {
      final empty = player.copyWith(techUnlocked: <String, bool>{});
      final g = game.copyWith(players: [empty, ...game.players.skip(1)]);
      await pumpTree(tester, g: g, p: empty, onOrdersChanged: (_) {});
      await openNode(tester, techDisplayName(kTechIdSheepRanching));
      expect(find.byKey(const Key('techTreeResearchThis')), findsNothing);
      expect(find.byKey(const Key('techTreeAssignReason')), findsOneWidget);
      expect(find.textContaining('Waiting on:'), findsOneWidget);
    },
  );

  testWidgets(
    'AC: observe-only (null onOrdersChanged) shows refusal, no assign control',
    (tester) async {
      final empty = player.copyWith(techUnlocked: <String, bool>{});
      final g = game.copyWith(players: [empty, ...game.players.skip(1)]);
      await pumpTree(tester, g: g, p: empty);
      await openNode(tester, techDisplayName(kTechIdCropRotation));
      expect(find.byKey(const Key('techTreeResearchThis')), findsNothing);
      expect(
        find.text('Research seats cannot be changed while observing.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'AC: already unlocked tech shows known reason without Research this',
    (tester) async {
      final known = player.copyWith(
        techUnlocked: {kTechIdCropRotation: true},
      );
      final g = game.copyWith(players: [known, ...game.players.skip(1)]);
      await pumpTree(tester, g: g, p: known, onOrdersChanged: (_) {});
      await openNode(tester, techDisplayName(kTechIdCropRotation));
      expect(find.byKey(const Key('techTreeResearchThis')), findsNothing);
      expect(
        find.text('You already know this technology.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'AC: already seated tech shows slot reason without Research this',
    (tester) async {
      final seated = player.copyWith(
        techUnlocked: <String, bool>{},
        researchSlotAssignments: {
          0: const ResearchSlotAssignment(
            techId: kTechIdCropRotation,
            funding: ResearchFundingLevel.medium,
          ),
        },
      );
      final g = game.copyWith(players: [seated, ...game.players.skip(1)]);
      await pumpTree(tester, g: g, p: seated, onOrdersChanged: (_) {});
      await openNode(tester, techDisplayName(kTechIdCropRotation));
      expect(find.byKey(const Key('techTreeResearchThis')), findsNothing);
      expect(
        find.text('Already researching in Slot 1.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'AC: discovery-blocked tech shows discovery reason without Research this',
    (tester) async {
      final empty = player.copyWith(techUnlocked: <String, bool>{});
      final g = game.copyWith(players: [empty, ...game.players.skip(1)]);
      await pumpTree(tester, g: g, p: empty, onOrdersChanged: (_) {});
      await openNode(tester, techDisplayName(kTechIdDiscoveryOfSugar));
      expect(find.byKey(const Key('techTreeResearchThis')), findsNothing);
      expect(
        find.text('Requires discovering a related resource first.'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'AC: after Research this, rebuilt Tree node is In progress',
    (tester) async {
      var current = const Orders();
      final empty = player.copyWith(techUnlocked: <String, bool>{});
      final g = game.copyWith(players: [empty, ...game.players.skip(1)]);
      await tester.pumpWidget(
        buildAppShell(
          child: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: TechTreeWidget(
                  game: g,
                  player: empty,
                  currentOrders: current,
                  onOrdersChanged: (o) {
                    current = o;
                    setState(() {});
                  },
                ),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await openNode(tester, techDisplayName(kTechIdCropRotation));
      await tester.tap(find.byKey(const Key('techTreeResearchThis')));
      await tester.pumpAndSettle();
      expect(find.byType(CtDialogShell), findsNothing);
      final name = techDisplayName(kTechIdCropRotation);
      final node = tester.widget<TechTreeNode>(
        find.ancestor(of: find.text(name), matching: find.byType(TechTreeNode)),
      );
      expect(node.state.inProgress, isTrue);
    },
  );

  testWidgets(
    'AC: Choose-tech Details shared dialog has no Tree assign section',
    (tester) async {
      // showTechDefinitionDetailDialog without treeAssign — mount via helper.
      await tester.pumpWidget(
        buildAppShell(
          child: Builder(
            builder: (context) {
              return Scaffold(
                body: TextButton(
                  onPressed: () {
                    showTechDefinitionDetailDialog(
                      context,
                      game: game,
                      player: player,
                      tech: techById(kTechIdCropRotation)!,
                    );
                  },
                  child: const Text('Open details'),
                ),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('Open details'));
      await tester.pumpAndSettle();
      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.byKey(const Key('techTreeResearchThis')), findsNothing);
      expect(find.byKey(const Key('techTreeAssignReason')), findsNothing);
    },
  );
}
