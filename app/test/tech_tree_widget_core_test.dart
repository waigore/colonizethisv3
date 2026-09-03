// Tests for TechTreeWidget and TechnologyScreen. SPEC/ui/tech-tree-widget.md.
// Hosts compose buildAppShell (Refs #4035 tech-tree densify).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/technology/tech_tree_widget.dart';
import 'package:colonizethis_app/features/game/screens/technology/technology_screen.dart';
import 'package:colonizethis_app/widgets/ct_back_button.dart';
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
}
