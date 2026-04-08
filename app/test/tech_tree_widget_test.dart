// Tests for TechTreeWidget and TechnologyScreen. SPEC/ui/tech-tree-widget.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/tech_tree_widget.dart';
import 'package:colonizethis_app/features/game/widgets/technology_screen.dart';
import 'package:colonizethis_app/widgets/ct_dialog_shell.dart';
import 'package:colonizethis_app/widgets/ct_screen_shell.dart';
import 'package:colonizethis_app/providers/app_event_bus_provider.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
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

  Widget scopedTechnology(Game g, Widget child) {
    return ProviderScope(
      overrides: [
        currentGameProvider.overrideWith(() => CurrentGameNotifier(g)),
        currentOrdersProvider.overrideWith(
          () => CurrentOrdersNotifier(const Orders()),
        ),
        appEventBusProvider.overrideWith((ref) {
          final bus = AppEventBus.create();
          ref.onDispose(bus.dispose);
          return bus;
        }),
      ],
      child: child,
    );
  }

  testWidgets('TechTreeWidget builds and shows scrollable content', (
    WidgetTester tester,
  ) async {
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

  testWidgets(
    'TechTreeWidget with mid-game player shows researched and available nodes',
    (WidgetTester tester) async {
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
    },
  );

  testWidgets('TechnologyScreen has Slots and Tree tabs', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      scopedTechnology(
        game,
        MaterialApp(
          home: Scaffold(
            body: TechnologyScreen(game: game, player: player),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Slots'), findsOneWidget);
    expect(find.text('Tree'), findsOneWidget);
    expect(find.text('Technology'), findsOneWidget);
  });

  testWidgets('TechnologyScreen uses CtScreenShell with showBackButton', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      scopedTechnology(
        game,
        MaterialApp(
          home: Navigator(
            pages: [
              MaterialPage(
                child: TechnologyScreen(game: game, player: player),
              ),
            ],
            onDidRemovePage: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CtScreenShell), findsOneWidget);
    expect(find.byIcon(Icons.arrow_back), findsOneWidget);
  });

  testWidgets('TechnologyScreen back button pops navigator', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(MaterialApp(home: const Text('Home')));
    await tester.pumpWidget(
      scopedTechnology(
        game,
        MaterialApp(
          home: Navigator(
            pages: [
              const MaterialPage(child: Text('Home')),
              MaterialPage(
                child: TechnologyScreen(game: game, player: player),
              ),
            ],
            onDidRemovePage: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Technology'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Technology'), findsNothing);
  });

  testWidgets('TechnologyScreen Tree tab shows tech tree content', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      scopedTechnology(
        game,
        MaterialApp(
          home: Scaffold(
            body: TechnologyScreen(game: game, player: player),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tree'));
    await tester.pumpAndSettle();
    expect(find.byType(TechTreeWidget), findsOneWidget);
    expect(find.text('Road Construction'), findsOneWidget);
  });

  testWidgets('Tapping available tech node opens description dialog', (
    WidgetTester tester,
  ) async {
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

  testWidgets(
    'Tech description dialog shows era, category, RP cost and effect summary',
    (WidgetTester tester) async {
      final emptyPlayer = player.copyWith(techUnlocked: <String, bool>{});
      final gameWithEmptyPlayer = game.copyWith(
        players: [emptyPlayer, ...game.players.skip(1)],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TechTreeWidget(
              game: gameWithEmptyPlayer,
              player: emptyPlayer,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Saw Mill').first);
      await tester.tap(find.text('Saw Mill').first);
      await tester.pumpAndSettle();
      // SPEC: display name, era, category, RP cost, prerequisites list (when any), effect summary.
      expect(find.byType(CtDialogShell), findsOneWidget);
      expect(find.text('Saw Mill'), findsWidgets);
      expect(find.textContaining('Era'), findsOneWidget);
      expect(find.textContaining('Gathering'), findsWidgets);
      expect(find.textContaining('RP'), findsOneWidget);
      expect(find.text('Effects'), findsOneWidget);
    },
  );

  testWidgets('Closing tech dialog dismisses it and tree remains', (
    WidgetTester tester,
  ) async {
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

  testWidgets('TechTreeWidget builds with in-progress tech', (
    WidgetTester tester,
  ) async {
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

  testWidgets('TechTreeWidget shows legend with category and state labels', (
    WidgetTester tester,
  ) async {
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

  testWidgets(
    'TechTreeWidget shows all four node states in legend for a mid-game player (AC3)',
    (WidgetTester tester) async {
      final allIds = techCatalog.keys.toList()..sort();
      final mid = (allIds.length / 2).floor();
      final techUnlocked = Map<String, bool>.fromEntries(
        allIds.take(mid).map((id) => MapEntry(id, true)),
      );
      final inProgressId = allIds[mid];
      final midPlayer = player.copyWith(
        techUnlocked: techUnlocked,
        researchProgressByTechId: {inProgressId: 50},
      );
      final midGame = game.copyWith(
        players: [midPlayer, ...game.players.skip(1)],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: TechTreeWidget(game: midGame, player: midPlayer),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Researched'), findsOneWidget);
      expect(find.text('In progress'), findsOneWidget);
      expect(find.text('Available'), findsOneWidget);
      expect(find.text('Locked'), findsOneWidget);
    },
  );

  testWidgets(
    'TechTreeWidget renders nodes with category-specific colours (AC5)',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 800,
              height: 600,
              child: TechTreeWidget(game: game, player: player),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final customPainters = find.byType(CustomPaint);
      expect(
        customPainters,
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
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 800,
            height: 600,
            child: TechTreeWidget(game: game, player: player),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

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
    expect(find.byType(CtDialogShell), findsOneWidget);
    expect(find.text('Prerequisites'), findsOneWidget);
    expect(find.text('Effects'), findsOneWidget);
  });

  testWidgets(
    'Batch-1 tech descriptions are concrete and avoid generic fallback text',
    (WidgetTester tester) async {
      final emptyPlayer = player.copyWith(techUnlocked: <String, bool>{});
      final gameWithEmptyPlayer = game.copyWith(
        players: [emptyPlayer, ...game.players.skip(1)],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TechTreeWidget(
              game: gameWithEmptyPlayer,
              player: emptyPlayer,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final expectedByTech = <String, String>{
        'Crop Rotation':
            'Unlocks: Sheep Ranching, Animal Husbandry, and Steppe Horsemen research paths',
        'Saw Mill': 'Improves: Timber extraction cap to 2 (forested provinces)',
        'Land Enclosure': 'Improves: Grain extraction cap to 2',
        'Mine Engineering': 'Enables: Builder upgrades to Fort Level 2',
        'Iron Mining': 'Improves: Iron extraction cap to 2',
        'Copper and Tin Mining': 'Improves: Copper/Tin extraction cap to 2',
        'Coal Mining': 'Enables: Coal extraction (cap 1)',
        'Wind Saw Mill': 'Improves: Timber extraction cap to 3',
        'Seed Drill': 'Improves: Grain extraction cap to 3',
        'Sheep Ranching': 'Improves: Wool extraction cap to 2',
      };

      for (final entry in expectedByTech.entries) {
        final techNode = find.text(entry.key).first;
        await tester.ensureVisible(techNode);
        await tester.tap(techNode);
        await tester.pumpAndSettle();

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.textContaining(entry.value), findsOneWidget);
        expect(
          find.textContaining('Improves gathering capabilities'),
          findsNothing,
        );
        expect(
          find.textContaining('Improves labour and economy output'),
          findsNothing,
        );

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'Batch-2 tech descriptions are concrete and avoid generic fallback text (Refs #1626)',
    (WidgetTester tester) async {
      final emptyPlayer = player.copyWith(techUnlocked: <String, bool>{});
      final gameWithEmptyPlayer = game.copyWith(
        players: [emptyPlayer, ...game.players.skip(1)],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TechTreeWidget(
              game: gameWithEmptyPlayer,
              player: emptyPlayer,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final expectedByTech = <String, String>{
        'Animal Husbandry': 'Improves: Meat extraction cap to 3',
        'Square-set Timbering': 'Improves: Coal extraction cap to 2',
        'Steam in Mining': 'Improves: Iron extraction cap to 3',
        'Large Coal Mines': 'Improves: Coal extraction cap to 3',
        'Large Copper and Tin Mines':
            'Improves: Copper/Tin extraction cap to 3',
        'Circular Saw': 'Improves: Timber extraction cap to 4',
        'Scientific Sheep Breeding': 'Improves: Wool extraction cap to 3',
        'Scientific Cattle Breeding': 'Improves: Meat extraction cap to 4',
        'Moldboard Plow': 'Improves: Grain extraction cap to 4',
        'Safety Lamp': 'Improves: Coal extraction cap to 4',
      };

      for (final entry in expectedByTech.entries) {
        final techNode = find.text(entry.key).first;
        await tester.ensureVisible(techNode);
        await tester.tap(techNode);
        await tester.pumpAndSettle();

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.textContaining(entry.value), findsOneWidget);
        expect(
          find.textContaining('Improves gathering capabilities'),
          findsNothing,
        );
        expect(
          find.textContaining('Improves labour and economy output'),
          findsNothing,
        );

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'Batch-3 tech descriptions are concrete and avoid generic fallback text (Refs #1627)',
    (WidgetTester tester) async {
      final emptyPlayer = player.copyWith(techUnlocked: <String, bool>{});
      final gameWithEmptyPlayer = game.copyWith(
        players: [emptyPlayer, ...game.players.skip(1)],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TechTreeWidget(
              game: gameWithEmptyPlayer,
              player: emptyPlayer,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final expectedByTech = <String, String>{
        'Large Precious Stone Mines':
            'Improves: Gems/diamonds extraction cap to 3',
        'Extraction of Precious Metals':
            'Improves: Gold/silver extraction cap to 3',
        'Geological Prospecting': 'Improves: Gems/diamonds extraction cap to 4',
        'Amalgamation Process': 'Improves: Gold/silver extraction cap to 4',
        'Industrial Iron Mining': 'Improves: Iron extraction cap to 4',
        'Efficient Extraction of Copper & Tin':
            'Improves: Copper/Tin extraction cap to 4',
        'Discovery of Sugar':
            'Enables: Research when player has revealed sugar cane (discovery rule)',
        'Sugar Planting': 'Improves: Sugar cane extraction cap to 2',
        'Sugar Refining':
            'Enables: Refined sugar luxury for Apprentice-tier worker consumption',
        'Large Sugar Plantations': 'Improves: Sugar cane extraction cap to 3',
      };

      for (final entry in expectedByTech.entries) {
        final techNode = find.text(entry.key).first;
        await tester.ensureVisible(techNode);
        await tester.tap(techNode);
        await tester.pumpAndSettle();

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.textContaining(entry.value), findsOneWidget);
        expect(
          find.textContaining('Improves gathering capabilities'),
          findsNothing,
        );
        expect(
          find.textContaining('Improves labour and economy output'),
          findsNothing,
        );
        expect(
          find.textContaining('Improves new-world capabilities'),
          findsNothing,
        );

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'Batch-4 tech descriptions are concrete and avoid generic fallback text (Refs #1628)',
    (WidgetTester tester) async {
      final emptyPlayer = player.copyWith(techUnlocked: <String, bool>{});
      final gameWithEmptyPlayer = game.copyWith(
        players: [emptyPlayer, ...game.players.skip(1)],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TechTreeWidget(
              game: gameWithEmptyPlayer,
              player: emptyPlayer,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final expectedByTech = <String, String>{
        'Sugar Industry': 'Improves: Sugar cane extraction cap to 4',
        'Discovery of Tobacco':
            'Enables: Research when player has revealed tobacco (discovery rule)',
        'Tobacco Planting': 'Improves: Tobacco extraction cap to 2',
        'Cigar Production':
            'Enables: Cigar luxury production for Journeyman-tier worker consumption',
        'Large Tobacco Plantations': 'Improves: Tobacco extraction cap to 3',
        'Tobacco Industry': 'Improves: Tobacco extraction cap to 4',
        'Discovery of Cotton':
            'Enables: Research when player has revealed cotton (discovery rule)',
        'Cotton Planting': 'Improves: Cotton extraction cap to 2',
        'Cotton Weaving': 'Enables: Cloth production from cotton',
        'Large Cotton Plantations': 'Improves: Cotton extraction cap to 3',
      };

      for (final entry in expectedByTech.entries) {
        final techNode = find.text(entry.key).first;
        await tester.ensureVisible(techNode);
        await tester.tap(techNode);
        await tester.pumpAndSettle();

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.textContaining(entry.value), findsOneWidget);
        expect(
          find.textContaining('Improves gathering capabilities'),
          findsNothing,
        );
        expect(
          find.textContaining('Improves labour and economy output'),
          findsNothing,
        );
        expect(
          find.textContaining('Improves new-world capabilities'),
          findsNothing,
        );

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'Batch-5 tech descriptions are concrete and avoid generic fallback text (Refs #1629)',
    (WidgetTester tester) async {
      final emptyPlayer = player.copyWith(techUnlocked: <String, bool>{});
      final gameWithEmptyPlayer = game.copyWith(
        players: [emptyPlayer, ...game.players.skip(1)],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TechTreeWidget(
              game: gameWithEmptyPlayer,
              player: emptyPlayer,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final expectedByTech = <String, String>{
        'Cotton Gin': 'Improves: Cotton extraction cap to 4',
        'Discovery of Furs':
            'Enables: Research when player has revealed furs (discovery rule)',
        'Improved Trapping Techniques': 'Improves: Furs extraction cap to 2',
        'Hat Production':
            'Enables: Fur hats luxury production for Master-tier worker consumption',
        'Riverboats': 'Improves: Furs extraction cap to 3',
        'Excessive Fur Harvesting': 'Improves: Furs extraction cap to 4',
        'Discovery of Spices':
            'Enables: Research when player has revealed spices (discovery rule)',
        'Improved Sea Routes': 'Improves: Spices extraction cap to 2',
        'Large Spice Plantations': 'Improves: Spices extraction cap to 3',
        'Improved Food Preservation': 'Improves: Spices extraction cap to 4',
      };

      for (final entry in expectedByTech.entries) {
        final techNode = find.text(entry.key).first;
        await tester.ensureVisible(techNode);
        await tester.tap(techNode);
        await tester.pumpAndSettle();

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.textContaining(entry.value), findsOneWidget);
        expect(
          find.textContaining('Improves gathering capabilities'),
          findsNothing,
        );
        expect(
          find.textContaining('Improves labour and economy output'),
          findsNothing,
        );
        expect(
          find.textContaining('Improves new-world capabilities'),
          findsNothing,
        );

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'Batch-6 tech descriptions are concrete and avoid generic fallback text (Refs #1630)',
    (WidgetTester tester) async {
      final emptyPlayer = player.copyWith(techUnlocked: <String, bool>{});
      final gameWithEmptyPlayer = game.copyWith(
        players: [emptyPlayer, ...game.players.skip(1)],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TechTreeWidget(
              game: gameWithEmptyPlayer,
              player: emptyPlayer,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final expectedByTech = <String, String>{
        'Discovery of Gold or Silver':
            'Enables: Research when player has revealed and prospected gold/silver',
        'Precious Metals Mining': 'Improves: Gold/silver extraction cap to 2',
        'Discovery of Gems or Diamonds':
            'Enables: Research when player has revealed and prospected gems/diamonds',
        'Precious Stone Mining': 'Improves: Gems/diamonds extraction cap to 2',
        'Road Construction':
            'Enables: Engineer road upgrades to transport level 2',
        'Early Steam Engine':
            'Enables: Rail Builder and railroads on flat terrain',
        'Later Steam Engine': 'Enables: Railroads on hills and swamps',
        'Dynamite': 'Enables: Railroads on mountains',
        'Printing Press':
            'Unlocks: Trained Journeymen, University, and military doctrine paths',
        'Apprentice Workers':
            'Enables: Apprentice tier (4x labour; consumes refined sugar)',
      };

      for (final entry in expectedByTech.entries) {
        final techNode = find.text(entry.key).first;
        await tester.ensureVisible(techNode);
        await tester.tap(techNode);
        await tester.pumpAndSettle();

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.textContaining(entry.value), findsOneWidget);
        expect(
          find.textContaining('Improves new-world capabilities'),
          findsNothing,
        );
        expect(
          find.textContaining('Improves transport capabilities'),
          findsNothing,
        );
        expect(
          find.textContaining('Improves labour capabilities'),
          findsNothing,
        );

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'Batch-7 tech descriptions are concrete and avoid generic fallback text (Refs #1631)',
    (WidgetTester tester) async {
      final emptyPlayer = player.copyWith(techUnlocked: <String, bool>{});
      final gameWithEmptyPlayer = game.copyWith(
        players: [emptyPlayer, ...game.players.skip(1)],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TechTreeWidget(
              game: gameWithEmptyPlayer,
              player: emptyPlayer,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final expectedByTech = <String, String>{
        'Trained Journeymen':
            'Enables: Journeyman tier (6x labour; consumes cigars)',
        'Master Artisans':
            'Enables: Master tier (8x labour; consumes fur hats)',
        'Money Lending': 'Enables: Research-phase treasury floor to -500',
        'Banking':
            'Unlocks: Dynamite, Empire Building, Modern Military Funding',
        'Trade Fairs':
            'Enables: Planned increase to trade commodity slots (deferred in MVP)',
        'University': 'Enables: Fourth active research slot (3 -> 4)',
        'Diplomatic Expertise': 'Enables: Embassy overtures with Minor Nations',
        'Merchant Companies': 'Enables: Merchant civilian unit construction',
        'National Bureaucracy': 'Enables: Builder upgrade_town work order',
        'Propaganda':
            'Improves: Diplomatic protest war penalty against aggressor (-10 -> -5)',
      };

      for (final entry in expectedByTech.entries) {
        final techNode = find.text(entry.key).first;
        await tester.ensureVisible(techNode);
        await tester.tap(techNode);
        await tester.pumpAndSettle();

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.textContaining(entry.value), findsOneWidget);
        expect(
          find.textContaining('Improves labour capabilities'),
          findsNothing,
        );
        expect(
          find.textContaining('Improves diplomacy capabilities'),
          findsNothing,
        );
        expect(
          find.textContaining('Improves civilian capabilities'),
          findsNothing,
        );

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'Batch-10 tech descriptions are concrete and avoid generic fallback text (Refs #1634)',
    (WidgetTester tester) async {
      final emptyPlayer = player.copyWith(techUnlocked: <String, bool>{});
      final gameWithEmptyPlayer = game.copyWith(
        players: [emptyPlayer, ...game.players.skip(1)],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TechTreeWidget(
              game: gameWithEmptyPlayer,
              player: emptyPlayer,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final expectedByTech = <String, String>{
        'Industrial Machinery':
            'Unlocks: Explosives, Improved Cavalry Weapons, Industrial Funding of Research (as prerequisite)',
        'Explosives': 'Improves: Musketeers regiment upgrade path',
        'Early Rifles': 'Improves: Calivermen regiment upgrade path',
        'Long Range Rifles': 'Improves: Skirmishers regiment upgrade path',
        'Needle Guns': 'Improves: Regulars regiment upgrade path',
        'Elite Military Training': 'Improves: Grenadiers regiment upgrade path',
        'Recruit Steppe Horsemen': 'Improves: Squires regiment upgrade path',
        'Improved Cavalry Tactics':
            'Prerequisite for: Hussars and Improved Cavalry Weapons',
        'Hussars': 'Improves: Cossacks regiment upgrade path',
        'Improved Cavalry Weapons':
            'Improves: Harquebusiers regiment upgrade path',
      };

      for (final entry in expectedByTech.entries) {
        final techNode = find.text(entry.key).first;
        await tester.ensureVisible(techNode);
        await tester.tap(techNode);
        await tester.pumpAndSettle();

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.textContaining(entry.value), findsOneWidget);
        expect(
          find.textContaining('Improves Military capabilities'),
          findsNothing,
        );

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'Batch-11 tech descriptions are concrete and avoid generic fallback text (Refs #1635)',
    (WidgetTester tester) async {
      final emptyPlayer = player.copyWith(techUnlocked: <String, bool>{});
      final gameWithEmptyPlayer = game.copyWith(
        players: [emptyPlayer, ...game.players.skip(1)],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TechTreeWidget(
              game: gameWithEmptyPlayer,
              player: emptyPlayer,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final expectedByTech = <String, String>{
        'Scouting': 'Improves: Hussars regiment upgrade path',
        'Repeating Cavalry Carbine':
            'Improves: Cuirassiers regiment upgrade path',
        'Horse Artillery': 'Prerequisite for: Light Artillery Tactics',
        'Siege Engineering': 'Improves: Culverin regiment upgrade path',
        'Light Artillery Tactics':
            'Improves: Horse Artillery regiment upgrade path',
        'Modern Forts':
            'Enables: Builder fort upgrades to level 3 (Modern: 3 emplaced guns, strongest walls)',
        'Heavy Artillery': 'Improves: Royal Artillery regiment upgrade path',
        'Heavy Emplaced Artillery':
            'Improves: defender emplaced fort batteries to Heavy quality (Royal → Heavy line)',
        'Field Artillery Tactics':
            'Improves: Light Artillery regiment upgrade path',
        'High Grade Steel': 'Improves: Heavy Artillery regiment upgrade path',
      };

      for (final entry in expectedByTech.entries) {
        final techNode = find.text(entry.key).first;
        await tester.ensureVisible(techNode);
        await tester.tap(techNode);
        await tester.pumpAndSettle();

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.textContaining(entry.value), findsOneWidget);
        expect(
          find.textContaining('Improves Military capabilities'),
          findsNothing,
        );

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'Batch-12 tech descriptions are concrete and avoid generic fallback text (Refs #1636)',
    (WidgetTester tester) async {
      final emptyPlayer = player.copyWith(techUnlocked: <String, bool>{});
      final gameWithEmptyPlayer = game.copyWith(
        players: [emptyPlayer, ...game.players.skip(1)],
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TechTreeWidget(
              game: gameWithEmptyPlayer,
              player: emptyPlayer,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final expectedByTech = <String, String>{
        'Emplaced Siege Guns':
            'Improves: defender emplaced fort batteries to Siege Gun quality (final emplaced tier)',
        'Modern Military Funding':
            'Unlocks: Field Artillery Tactics, High Grade Steel, Elite Military Training stack',
        'Industrial Funding of Research':
            'Unlocks: Needle Guns, Repeating Cavalry Carbine, High Grade Steel, Advanced Iron Working (as prerequisite)',
      };

      for (final entry in expectedByTech.entries) {
        final techNode = find.text(entry.key).first;
        await tester.ensureVisible(techNode);
        await tester.tap(techNode);
        await tester.pumpAndSettle();

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.textContaining(entry.value), findsOneWidget);
        expect(
          find.textContaining('Improves Military capabilities'),
          findsNothing,
        );

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }
    },
  );

  test(
    'Column rule: A→B→C and A→C places B between A and C (gap between A and C)',
    () {
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
        prerequisiteIds: ['a'],
        regimentUnlockIds: [],
        shipUnlockIds: [],
      );
      final catalog = <String, TechDefinition>{'a': a, 'b': b, 'c': c};
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

Player _dummyPlayer() {
  return Player(id: 'dummy', displayName: 'Dummy', isHuman: true);
}
