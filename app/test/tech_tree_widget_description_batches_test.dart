// Tests for TechTreeWidget and TechnologyScreen. SPEC/ui/tech-tree-widget.md.

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/tech_tree_widget.dart';
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
            'Enables: 6 commodity slots per embassy trade agreement (3 baseline without this tech)',
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
    'Batch-8 tech descriptions are concrete and avoid generic fallback text (Refs #1632)',
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
        'Nationalism':
            'Improves: Battle deployment base limit to 12 regiments (vs 10)',
        'Empire Building':
            'Enables: Join Empire overture toward nearly-defeated Great Powers',
        'Superior Hull Design':
            'Unlocks: Improved Sail Design and Navigation hull paths',
        'Improved Sail Design':
            'Unlocks: Advanced Hull Design path (University + Privateering)',
        'Convoying': 'Unlocks: Large Hulls (with Wind Saw Mill + Navigation)',
        'Navigation': 'Unlocks: Large Hulls and Privateering Companies',
        'Large Hulls':
            'Unlocks: Ship of the Line (with Large Copper and Tin Mines)',
        'Clipper Ships': 'Improves: Late-era fast merchant Clipper cargo line',
        'Paddlewheels': 'Unlocks: Merchant Steamships (with Riverboats)',
        'Merchant Steamships':
            'Enables: Steam-powered merchant hull for seagoing trade',
      };

      for (final entry in expectedByTech.entries) {
        final techNode = find.text(entry.key).first;
        await tester.ensureVisible(techNode);
        await tester.tap(techNode);
        await tester.pumpAndSettle();

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.textContaining(entry.value), findsOneWidget);
        expect(
          find.textContaining('Improves naval capabilities'),
          findsNothing,
        );
        expect(
          find.textContaining('Improves diplomacy capabilities'),
          findsNothing,
        );

        await tester.tap(find.text('Close'));
        await tester.pumpAndSettle();
      }
    },
  );

  testWidgets(
    'Batch-9 tech descriptions are concrete and avoid generic fallback text (Refs #1633)',
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
        'Advanced Hull Design':
            'Improves: Frigate — high intercept, moderate flee (patrol/blockade)',
        'Ship of the Line':
            'Improves: Battle-line capital ship for decisive fleet engagements',
        'Privateering Companies':
            'Improves: Patrol/Blockade interception and trade-raid effectiveness',
        'Advanced Iron Working': 'Improves: Ironclad armored steam combat hull',
        'Organised Regiments': 'Improves: General cap floor to at least 2',
        'Improved Iron Weapons': 'Unlocks: Bayonet (with Crucible Process)',
        'Improved Infantry Tactics':
            'Improves: General cap floor to at least 3 (or National Bureaucracy)',
        'Crucible Process':
            'Prerequisite-only: Steel chain for Bayonet, rifles, steam, and cannons',
        'Bayonet':
            'Unlocks: Needle Guns (with Industrial Funding + Early Rifles)',
        'Weapon Craftsmanship':
            'Unlocks: Explosives and Grenadiers (with Industrial Machinery)',
      };

      for (final entry in expectedByTech.entries) {
        final techNode = find.text(entry.key).first;
        await tester.ensureVisible(techNode);
        await tester.tap(techNode);
        await tester.pumpAndSettle();

        expect(find.byType(CtDialogShell), findsOneWidget);
        expect(find.textContaining(entry.value), findsOneWidget);
        expect(
          find.textContaining('Improves naval capabilities'),
          findsNothing,
        );
        expect(
          find.textContaining('Improves military capabilities'),
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
}

Player _dummyPlayer() {
  return Player(id: 'dummy', displayName: 'Dummy', isHuman: true);
}
