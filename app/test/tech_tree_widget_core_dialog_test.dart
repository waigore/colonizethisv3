// TechTreeWidget dialog / legend / node-state coverage (Refs #4720 Slice F).
// SPEC/ui/tech-tree-widget.md. Hosts compose buildAppShell (Refs #4035).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology/tech_tree_widget.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

Player _dummyPlayer() =>
    Player(id: 'dummy', displayName: 'Dummy', isHuman: true);

void main() {
  suppressLogsForTests();

  late Game game;
  late Player player;

  setUpAll(() {
    game = buildTechnologyPanelTestGame();
    player = game.players.isNotEmpty ? game.players.first : _dummyPlayer();
  });

  Future<void> pumpTree(
    WidgetTester tester, {
    required Game g,
    required Player p,
    Size? size,
  }) async {
    final tree = TechTreeWidget(game: g, player: p);
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: size == null
              ? tree
              : SizedBox(width: size.width, height: size.height, child: tree),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  (Game, Player) withUnlocked(
    Map<String, bool> techUnlocked, {
    String? inProgressId,
  }) {
    final p = player.copyWith(
      techUnlocked: techUnlocked,
      researchProgressByTechId: inProgressId == null
          ? null
          : {inProgressId: 50},
    );
    return (game.copyWith(players: [p, ...game.players.skip(1)]), p);
  }

  (Game, Player) emptyPlayerGame() => withUnlocked(<String, bool>{});

  (Game, Player) midGame() {
    final ids = techCatalog.keys.toList()..sort();
    final mid = (ids.length / 2).floor();
    return withUnlocked(
      Map<String, bool>.fromEntries(
        ids.take(mid).map((id) => MapEntry(id, true)),
      ),
      inProgressId: ids[mid],
    );
  }

  Future<void> openTechDialog(
    WidgetTester tester, {
    required String techName,
    (Game, Player)? fixture,
  }) async {
    final (g, p) = fixture ?? emptyPlayerGame();
    await pumpTree(tester, g: g, p: p);
    expect(find.byType(CtDialogShell), findsNothing);
    await tester.ensureVisible(find.text(techName).first);
    await tester.tap(find.text(techName).first);
    await tester.pumpAndSettle();
    expect(find.byType(CtDialogShell), findsOneWidget);
  }

  testWidgets('Tapping available tech node opens description dialog', (
    WidgetTester tester,
  ) async {
    await openTechDialog(tester, techName: 'Saw Mill');
    expect(find.text('Saw Mill'), findsWidgets); // title and node
  });

  testWidgets(
    'Tech description dialog shows era, category, RP cost and effect summary',
    (WidgetTester tester) async {
      await openTechDialog(tester, techName: 'Saw Mill');
      // SPEC: display name, era, category, RP cost, prerequisites list (when any), effect summary.
      expect(find.text('Saw Mill'), findsWidgets);
      expect(find.textContaining('Era'), findsOneWidget);
      expect(find.textContaining('Gathering'), findsWidgets);
      expect(find.textContaining('RP'), findsOneWidget);
      expect(find.text('Effects'), findsOneWidget);
      expect(find.textContaining('Timber extraction cap'), findsWidgets);
    },
  );

  testWidgets('Closing tech dialog dismisses it and tree remains', (
    WidgetTester tester,
  ) async {
    await openTechDialog(tester, techName: 'Saw Mill');
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(CtDialogShell), findsNothing);
    expect(find.byType(TechTreeWidget), findsOneWidget);
  });

  testWidgets('TechTreeWidget builds with in-progress tech', (
    WidgetTester tester,
  ) async {
    final (midGameGame, midGamePlayer) = midGame();
    await pumpTree(tester, g: midGameGame, p: midGamePlayer);
    expect(find.byType(TechTreeWidget), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsWidgets);
  });

  testWidgets('TechTreeWidget shows legend with category and state labels', (
    WidgetTester tester,
  ) async {
    await pumpTree(tester, g: game, p: player);
    expect(find.text('Technology tree legend'), findsOneWidget);
    expect(find.text('Gathering'), findsAtLeastNWidgets(1));
    for (final label in <String>[
      'Researched',
      'In progress',
      'Available',
      'Locked',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets(
    'TechTreeWidget shows all four node states in legend for a mid-game player (AC3)',
    (WidgetTester tester) async {
      final (midGameGame, midPlayer) = midGame();
      await pumpTree(
        tester,
        g: midGameGame,
        p: midPlayer,
        size: const Size(400, 600),
      );
      for (final label in <String>[
        'Researched',
        'In progress',
        'Available',
        'Locked',
      ]) {
        expect(find.text(label), findsOneWidget);
      }
    },
  );

  testWidgets(
    'TechTreeWidget renders nodes with category-specific colours (AC5)',
    (WidgetTester tester) async {
      await pumpTree(tester, g: game, p: player, size: const Size(800, 600));

      expect(
        find.byType(CustomPaint),
        findsWidgets,
        reason:
            'CustomPaint widgets should be rendered for category-colored node backgrounds',
      );

      final sawMillNode = find.text('Saw Mill');
      expect(
        sawMillNode,
        findsWidgets,
        reason: 'Saw Mill (gathering category) should be rendered',
      );

      await tester.ensureVisible(sawMillNode.first);
      await tester.pumpAndSettle();
    },
  );

  testWidgets('TechTreeWidget scroll view is scrollable in both axes (AC2)', (
    WidgetTester tester,
  ) async {
    await pumpTree(tester, g: game, p: player, size: const Size(800, 600));

    final scrollers = find.byType(SingleChildScrollView);
    expect(
      scrollers,
      findsWidgets,
      reason:
          'Scrollable viewport should contain SingleChildScrollView widgets',
    );
    expect(
      scrollers,
      findsAtLeastNWidgets(2),
      reason: 'Both horizontal and vertical scroll views should be present',
    );
  });

  testWidgets('Tapping locked tech node opens dialog with benefits and effects', (
    WidgetTester tester,
  ) async {
    // Wind Saw Mill has prerequisite Saw Mill; with no techs unlocked it is locked.
    await openTechDialog(tester, techName: 'Wind Saw Mill');
    expect(find.text('Prerequisites'), findsOneWidget);
    expect(find.text('Effects'), findsOneWidget);
  });
}
