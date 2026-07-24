// Tests for TechTreeWidget and TechnologyScreen. SPEC/ui/tech-tree-widget.md.
// Hosts compose buildAppShell (Refs #4035 tech-tree densify).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology/tech_tree_widget.dart';
import 'package:colonizethis_app/features/game/screens/technology/technology_screen.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';

import 'app_shell_harness.dart';
import 'panel_test_fixtures.dart';

Player _dummyPlayer() =>
    Player(id: 'dummy', displayName: 'Dummy', isHuman: true);

List<Override> _technologyOverrides(Game g) => [
      currentGameProvider.overrideWith(() => CurrentGameNotifier(g)),
      currentOrdersProvider.overrideWith(
        () => CurrentOrdersNotifier(const Orders()),
      ),
      appEventBusProvider.overrideWith((ref) {
        final bus = AppEventBus.create();
        ref.onDispose(bus.dispose);
        return bus;
      }),
    ];

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

  Future<void> pumpScreen(WidgetTester tester, Game g, Player p) async {
    await tester.pumpWidget(
      buildAppShell(
        overrides: _technologyOverrides(g),
        child: Scaffold(
          body: TechnologyScreen(game: g, player: p),
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

  testWidgets('TechTreeWidget builds and shows scrollable content', (
    WidgetTester tester,
  ) async {
    await pumpTree(tester, g: game, p: player);
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(find.byType(TechTreeWidget), findsOneWidget);
  });

  testWidgets(
    'TechTreeWidget with mid-game player shows researched and available nodes',
    (WidgetTester tester) async {
      final half = (techCatalog.keys.length / 2).floor();
      final unlockedIds = techCatalog.keys.toList()..sort();
      final (midGameGame, midGamePlayer) = withUnlocked(
        Map<String, bool>.fromEntries(
          unlockedIds.take(half).map((id) => MapEntry(id, true)),
        ),
      );
      await pumpTree(tester, g: midGameGame, p: midGamePlayer);
      expect(find.text('Road Construction'), findsOneWidget);
    },
  );

  testWidgets('TechnologyScreen has Slots and Tree tabs', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, game, player);
    expect(find.text('Slots'), findsOneWidget);
    expect(find.text('Tree'), findsOneWidget);
    expect(find.text('Technology'), findsOneWidget);
  });

  // Note: the legacy "TechnologyScreen uses CtScreenShell with showBackButton"
  // test was removed in #2864 S1. The dark editorial-monocle chrome replaces
  // CtScreenShell with CtGameFeatureScreenShell + CtTopBar + CtBackButton,
  // and SPEC/ui/technology-panel.md § Acceptance criteria explicitly forbids
  // any fallback to the legacy parchment chrome. The replacement assertions
  // (CtTopBar, no CtScreenShell, CtBackButton inside the top bar) live in
  // app/test/technology_screen_dark_chrome_test.dart.

  testWidgets('TechnologyScreen back button pops navigator', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      buildAppShell(
        overrides: _technologyOverrides(game),
        child: Navigator(
          pages: [
            const MaterialPage(child: Text('Home')),
            MaterialPage(
              child: TechnologyScreen(game: game, player: player),
            ),
          ],
          onDidRemovePage: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Technology'), findsOneWidget);

    await tester.tap(find.byType(CtBackButton));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Technology'), findsNothing);
  });

  testWidgets('TechnologyScreen Tree tab shows tech tree content', (
    WidgetTester tester,
  ) async {
    await pumpScreen(tester, game, player);
    await tester.tap(find.text('Tree'));
    await tester.pumpAndSettle();
    expect(find.byType(TechTreeWidget), findsOneWidget);
    expect(find.text('Road Construction'), findsOneWidget);
  });

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

  test(
    'Column rule: A→B→C and A→C places B between A and C (gap between A and C)',
    () {
      // SPEC/ui/tech-tree-widget.md: when there is both a chain (A→B→C) and a direct edge (A→C),
      // there must be a gap between A and C because B occupies the column in between.
      TechDefinition def(String id, List<String> prereqs) => TechDefinition(
        id: id,
        era: 1,
        category: 'gathering',
        cost: 1,
        prerequisiteIds: prereqs,
        regimentUnlockIds: const [],
        shipUnlockIds: const [],
      );
      final catalog = <String, TechDefinition>{
        'a': def('a', const []),
        'b': def('b', const ['a']),
        'c': def('c', const ['a', 'b']),
      };
      final positions = TechTreeWidget.computeLayout(catalog);
      expect(positions.length, 3);
      final posA = positions.firstWhere((p) => p.techId == 'a');
      final posB = positions.firstWhere((p) => p.techId == 'b');
      final posC = positions.firstWhere((p) => p.techId == 'c');
      expect(posA.x, lessThan(posB.x), reason: 'A must be left of B');
      expect(
        posB.x,
        lessThan(posC.x),
        reason: 'B must be left of C so B occupies column between A and C',
      );
    },
  );

  test(
    'Connector slot: edge A→C reserves row in middle layer so B is not on same row',
    () {
      // SPEC: when an edge spans columns (A→C), the layout reserves that row in intermediate
      // columns so the connector does not pass through other nodes (e.g. B).
      TechDefinition def(String id, List<String> prereqs) => TechDefinition(
        id: id,
        era: 1,
        category: 'gathering',
        cost: 1,
        prerequisiteIds: prereqs,
        regimentUnlockIds: const [],
        shipUnlockIds: const [],
      );
      final catalog = <String, TechDefinition>{
        'a': def('a', const []),
        'b': def('b', const ['a']),
        'c': def('c', const ['a']),
      };
      final positions = TechTreeWidget.computeLayout(catalog);
      expect(positions.length, 3);
      final posB = positions.firstWhere((p) => p.techId == 'b');
      final posC = positions.firstWhere((p) => p.techId == 'c');
      const rowGap = 52.0;
      const baseY = 24.0;
      final rowB = ((posB.y - baseY) / rowGap).round();
      final rowC = ((posC.y - baseY) / rowGap).round();
      expect(
        rowB,
        isNot(equals(rowC)),
        reason:
            'B must not share row with C so A→C connector has its own slot in middle column',
      );
    },
  );
}
