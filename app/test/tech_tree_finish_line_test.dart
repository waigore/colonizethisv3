// Widget tests for the Tree-opened finish-time line (Refs #4511).
//
// SPEC: SPEC/ui/tech-tree-widget.md § Description dialog (Finish-time).

import 'package:colonizethis_app/features/game/widgets/technology/tech_definition_detail_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_tree_finish_line.dart';
import 'package:colonizethis_app/features/game/widgets/technology/tech_tree_widget.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

Player _seatedPlayer(
  Player base, {
  int progress = 40,
  int treasury = 2000,
  ResearchFundingLevel funding = ResearchFundingLevel.medium,
}) {
  return base.copyWith(
    treasury: treasury,
    researchSlots: 3,
    researchSlotAssignments: {
      0: ResearchSlotAssignment(techId: kTechIdSawMill, funding: funding),
    },
    researchProgressByTechId: {kTechIdSawMill: progress},
  );
}

Game _gameWith(Player player, Game base) {
  return base.copyWith(players: [player, ...base.players.skip(1)]);
}

Future<void> _pumpTree(
  WidgetTester tester, {
  required Game game,
  required Player player,
  Orders orders = const Orders(),
  void Function(Orders orders)? onOrdersChanged,
  Size size = const Size(420, 700),
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    buildAppShell(
      child: MediaQuery(
        data: MediaQueryData(size: size),
        child: Scaffold(
          body: TechTreeWidget(
            game: game,
            player: player,
            currentOrders: orders,
            onOrdersChanged: onOrdersChanged,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openSawMill(WidgetTester tester) async {
  final node = find.text(techDisplayName(kTechIdSawMill)).first;
  await tester.ensureVisible(node);
  await tester.tap(node);
  await tester.pumpAndSettle();
  expect(find.byType(CtDialogShell), findsOneWidget);
}

void main() {
  suppressLogsForTests();

  late Game baseGame;
  late Player basePlayer;

  setUpAll(() {
    baseGame = buildTechnologyPanelTestGame();
    basePlayer = baseGame.players.first;
  });

  testWidgets(
    'positive: remaining RP covered this turn shows Completes next turn',
    (tester) async {
      final player = _seatedPlayer(basePlayer, progress: 1600);
      await _pumpTree(
        tester,
        game: _gameWith(player, baseGame),
        player: player,
        onOrdersChanged: (_) {},
      );
      await _openSawMill(tester);
      expect(find.byKey(TechTreeFinishLine.lineKey), findsOneWidget);
      expect(find.textContaining('Completes next turn'), findsOneWidget);
    },
  );

  testWidgets(
    'positive: remaining RP above this-turn RP shows Finishes in N turns',
    (tester) async {
      final player = _seatedPlayer(basePlayer, progress: 40);
      await _pumpTree(
        tester,
        game: _gameWith(player, baseGame),
        player: player,
        onOrdersChanged: (_) {},
      );
      await _openSawMill(tester);
      expect(find.byKey(TechTreeFinishLine.lineKey), findsOneWidget);
      expect(find.textContaining('Finishes in 6 turns'), findsOneWidget);
    },
  );

  testWidgets('negative: funding None omits the finish-time line', (
    tester,
  ) async {
    final player = _seatedPlayer(
      basePlayer,
      funding: ResearchFundingLevel.none,
    );
    await _pumpTree(
      tester,
      game: _gameWith(player, baseGame),
      player: player,
      onOrdersChanged: (_) {},
    );
    await _openSawMill(tester);
    expect(find.byKey(TechTreeFinishLine.lineKey), findsNothing);
  });

  testWidgets('negative: debt-blocked seat omits the finish-time line', (
    tester,
  ) async {
    final player = _seatedPlayer(basePlayer, treasury: 0);
    await _pumpTree(
      tester,
      game: _gameWith(player, baseGame),
      player: player,
      onOrdersChanged: (_) {},
    );
    await _openSawMill(tester);
    expect(find.byKey(TechTreeFinishLine.lineKey), findsNothing);
  });

  testWidgets(
    'negative: Choose-tech Details shared dialog omits the finish-time line',
    (tester) async {
      final player = _seatedPlayer(basePlayer, progress: 1600);
      final game = _gameWith(player, baseGame);
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
                      tech: techById(kTechIdSawMill)!,
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
      expect(find.byKey(TechTreeFinishLine.lineKey), findsNothing);
    },
  );

  testWidgets(
    'positive: observe-only Tree dialog still shows the finish-time line',
    (tester) async {
      final player = _seatedPlayer(basePlayer, progress: 1600);
      await _pumpTree(
        tester,
        game: _gameWith(player, baseGame),
        player: player,
      );
      await _openSawMill(tester);
      expect(find.byKey(TechTreeFinishLine.lineKey), findsOneWidget);
      expect(find.textContaining('Completes next turn'), findsOneWidget);
    },
  );

  testWidgets('positive: 320 dp viewport wrap does not overflow', (
    tester,
  ) async {
    final player = _seatedPlayer(basePlayer, progress: 40);
    await _pumpTree(
      tester,
      game: _gameWith(player, baseGame),
      player: player,
      onOrdersChanged: (_) {},
      size: const Size(320, 640),
    );
    await _openSawMill(tester);
    expect(find.byKey(TechTreeFinishLine.lineKey), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
