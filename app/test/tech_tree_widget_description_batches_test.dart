// Tests for TechTreeWidget and TechnologyScreen. SPEC/ui/tech-tree-widget.md.

import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology/tech_tree_widget.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';
import 'tech_tree_widget_description_batches_cases.dart';

Future<void> _pumpEmptyTechTree(
  WidgetTester tester, {
  required Game game,
  required Player player,
}) async {
  final emptyPlayer = player.copyWith(techUnlocked: <String, bool>{});
  final gameWithEmptyPlayer = game.copyWith(
    players: [emptyPlayer, ...game.players.skip(1)],
  );
  await tester.pumpWidget(
    buildAppShell(
      child: Scaffold(
        body: TechTreeWidget(game: gameWithEmptyPlayer, player: emptyPlayer),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _expectBatchDescriptions(
  WidgetTester tester, {
  required Map<String, String> expectedByTech,
  required List<String> forbiddenFragments,
}) async {
  for (final entry in expectedByTech.entries) {
    final techNode = find.text(entry.key).first;
    await tester.ensureVisible(techNode);
    await tester.tap(techNode);
    await tester.pumpAndSettle();

    expect(find.byType(CtDialogShell), findsOneWidget);
    expect(find.textContaining(entry.value), findsOneWidget);
    for (final fragment in forbiddenFragments) {
      expect(find.textContaining(fragment), findsNothing);
    }

    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
  }
}

void main() {
  suppressLogsForTests();

  late Game game;
  late Player player;

  setUpAll(() {
    game = buildTechnologyPanelTestGame();
    player = game.players.isNotEmpty
        ? game.players.first
        : Player(id: 'dummy', displayName: 'Dummy', isHuman: true);
  });

  for (final batch in techTreeDescriptionBatches) {
    testWidgets(batch.name, (WidgetTester tester) async {
      await _pumpEmptyTechTree(tester, game: game, player: player);
      await _expectBatchDescriptions(
        tester,
        expectedByTech: batch.expectedByTech,
        forbiddenFragments: batch.forbiddenFragments,
      );
    });
  }
}
