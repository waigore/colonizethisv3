// Tests for TechTreeWidget and TechnologyScreen. SPEC/ui/tech-tree-widget.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/tech_tree_widget.dart';
import 'package:colonizethis_app/features/game/widgets/technology_screen.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

void main() {
  suppressLogsForTests();

  late Game game;
  late Player player;

  setUpAll(() {
    final result = getDebugInitGameResult();
    game = result.game;
    player = game.players.isNotEmpty ? game.players.first : _dummyPlayer();
  });

  testWidgets('TechTreeWidget builds and shows scrollable content', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TechTreeWidget(game: game, player: player),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(find.byType(TechTreeWidget), findsOneWidget);
  });

  testWidgets('TechTreeWidget with mid-game player shows researched and available nodes', (WidgetTester tester) async {
    final half = (techCatalog.keys.length / 2).floor();
    final unlockedIds = techCatalog.keys.toList()..sort();
    final techUnlocked = Map<String, bool>.fromEntries(
      unlockedIds.take(half).map((id) => MapEntry(id, true)),
    );
    final midGamePlayer = player.copyWith(techUnlocked: techUnlocked);
    final midGame = game.copyWith(
      players: [midGamePlayer, ...game.players.skip(1)],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TechTreeWidget(game: midGame, player: midGamePlayer),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Road Construction'), findsOneWidget);
  });

  testWidgets('TechnologyScreen has Slots and Tree tabs', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TechnologyScreen(game: game, player: player),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Slots'), findsOneWidget);
    expect(find.text('Tree'), findsOneWidget);
    expect(find.text('Technology'), findsOneWidget);
  });

  testWidgets('TechnologyScreen Tree tab shows tech tree content', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TechnologyScreen(game: game, player: player),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tree'));
    await tester.pumpAndSettle();
    expect(find.byType(TechTreeWidget), findsOneWidget);
    expect(find.text('Road Construction'), findsOneWidget);
  });

  testWidgets('Tapping available tech node opens description dialog', (WidgetTester tester) async {
    // Player with no techs: root techs (e.g. Saw Mill) are available and tappable.
    // Use a root tech that has an effect summary (extraction cap) for dialog content.
    final emptyPlayer = player.copyWith(techUnlocked: <String, bool>{});
    final gameWithEmptyPlayer = game.copyWith(
      players: [emptyPlayer, ...game.players.skip(1)],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TechTreeWidget(game: gameWithEmptyPlayer, player: emptyPlayer),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CtDialogShell), findsNothing);
    await tester.ensureVisible(find.text('Saw Mill').first);
    await tester.tap(find.text('Saw Mill').first);
    await tester.pumpAndSettle();
    expect(find.byType(CtDialogShell), findsOneWidget);
    expect(find.text('Saw Mill'), findsWidgets); // title and node
  });

  testWidgets('Tech description dialog shows era, category, RP cost and effect summary', (WidgetTester tester) async {
    final emptyPlayer = player.copyWith(techUnlocked: <String, bool>{});
    final gameWithEmptyPlayer = game.copyWith(
      players: [emptyPlayer, ...game.players.skip(1)],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TechTreeWidget(game: gameWithEmptyPlayer, player: emptyPlayer),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Saw Mill').first);
    await tester.tap(find.text('Saw Mill').first);
    await tester.pumpAndSettle();
    // SPEC: display name, era, category, RP cost, effect summary; no prerequisites.
    expect(find.byType(CtDialogShell), findsOneWidget);
    expect(find.text('Saw Mill'), findsWidgets);
    expect(find.textContaining('Era'), findsOneWidget);
    expect(find.textContaining('Gathering'), findsWidgets);
    expect(find.textContaining('RP'), findsOneWidget);
    expect(find.text('Effects'), findsOneWidget);
    expect(find.textContaining('Prerequisite'), findsNothing);
  });

  testWidgets('Closing tech dialog dismisses it and tree remains', (WidgetTester tester) async {
    final emptyPlayer = player.copyWith(techUnlocked: <String, bool>{});
    final gameWithEmptyPlayer = game.copyWith(
      players: [emptyPlayer, ...game.players.skip(1)],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TechTreeWidget(game: gameWithEmptyPlayer, player: emptyPlayer),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Saw Mill').first);
    await tester.tap(find.text('Saw Mill').first);
    await tester.pumpAndSettle();
    expect(find.byType(CtDialogShell), findsOneWidget);
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.byType(CtDialogShell), findsNothing);
    expect(find.byType(TechTreeWidget), findsOneWidget);
  });

  testWidgets('TechTreeWidget builds with in-progress tech', (WidgetTester tester) async {
    final half = (techCatalog.keys.length / 2).floor();
    final unlockedIds = techCatalog.keys.toList()..sort();
    final techUnlocked = Map<String, bool>.fromEntries(
      unlockedIds.take(half).map((id) => MapEntry(id, true)),
    );
    final inProgressId = unlockedIds[half];
    final midGamePlayer = player.copyWith(
      techUnlocked: techUnlocked,
      researchProgressByTechId: {inProgressId: 50},
    );
    final midGame = game.copyWith(
      players: [midGamePlayer, ...game.players.skip(1)],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TechTreeWidget(game: midGame, player: midGamePlayer),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(TechTreeWidget), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsWidgets);
  });

  testWidgets('TechTreeWidget shows legend with category and state labels', (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TechTreeWidget(game: game, player: player),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Technology tree legend'), findsOneWidget);
    expect(find.text('Gathering'), findsAtLeastNWidgets(1));
    expect(find.text('Researched'), findsOneWidget);
    expect(find.text('In progress'), findsOneWidget);
    expect(find.text('Available'), findsOneWidget);
    expect(find.text('Locked'), findsOneWidget);
  });

  testWidgets('Tapping locked tech node does not open dialog', (WidgetTester tester) async {
    final emptyPlayer = player.copyWith(techUnlocked: <String, bool>{});
    final gameWithEmptyPlayer = game.copyWith(
      players: [emptyPlayer, ...game.players.skip(1)],
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TechTreeWidget(game: gameWithEmptyPlayer, player: emptyPlayer),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(CtDialogShell), findsNothing);
    // Wind Saw Mill has prerequisite Saw Mill; with no techs unlocked it is locked.
    final lockedTechFind = find.text('Wind Saw Mill');
    await tester.ensureVisible(lockedTechFind.first);
    await tester.tap(lockedTechFind.first);
    await tester.pumpAndSettle();
    expect(find.byType(CtDialogShell), findsNothing);
  });

  test('Column rule: A→B→C and A→C places B between A and C (gap between A and C)', () {
    // SPEC/ui/tech-tree-widget.md: when there is both a chain (A→B→C) and a direct edge (A→C),
    // there must be a gap between A and C because B occupies the column in between.
    const a = TechDefinition(
      id: 'a',
      era: 1,
      category: 'gathering',
      cost: 1,
      prerequisiteIds: [],
      regimentUnlockIds: [],
      shipUnlockIds: [],
    );
    const b = TechDefinition(
      id: 'b',
      era: 1,
      category: 'gathering',
      cost: 1,
      prerequisiteIds: ['a'],
      regimentUnlockIds: [],
      shipUnlockIds: [],
    );
    const c = TechDefinition(
      id: 'c',
      era: 1,
      category: 'gathering',
      cost: 1,
      prerequisiteIds: ['a', 'b'],
      regimentUnlockIds: [],
      shipUnlockIds: [],
    );
    final catalog = <String, TechDefinition>{'a': a, 'b': b, 'c': c};
    final positions = TechTreeWidget.computeLayout(catalog);
    expect(positions.length, 3);
    final posA = positions.firstWhere((p) => p.techId == 'a');
    final posB = positions.firstWhere((p) => p.techId == 'b');
    final posC = positions.firstWhere((p) => p.techId == 'c');
    expect(posA.x, lessThan(posB.x), reason: 'A must be left of B');
    expect(posB.x, lessThan(posC.x), reason: 'B must be left of C so B occupies column between A and C');
  });
}

Player _dummyPlayer() {
  return Player(
    id: 'dummy',
    displayName: 'Dummy',
    isHuman: true,
  );
}
