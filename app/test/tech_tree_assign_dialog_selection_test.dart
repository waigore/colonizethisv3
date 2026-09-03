// Tree node dialog assignment selection / reason coverage (Refs #4498 / #4720).
// SPEC/ui/tech-tree-widget.md.

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
      final known = player.copyWith(techUnlocked: {kTechIdCropRotation: true});
      final g = game.copyWith(players: [known, ...game.players.skip(1)]);
      await pumpTree(tester, g: g, p: known, onOrdersChanged: (_) {});
      await openNode(tester, techDisplayName(kTechIdCropRotation));
      expect(find.byKey(const Key('techTreeResearchThis')), findsNothing);
      expect(find.text('You already know this technology.'), findsOneWidget);
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
      expect(find.text('Already researching in Slot 1.'), findsOneWidget);
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

  testWidgets('AC: after Research this, rebuilt Tree node is In progress', (
    tester,
  ) async {
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
  });

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
