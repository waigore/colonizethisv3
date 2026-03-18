import 'package:colonizethis_app/features/game/flame/game_side_menu.dart';
import 'package:colonizethis_app/features/game/widgets/production_screen.dart';
import 'package:colonizethis_app/providers/games_provider.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  suppressLogsForTests();

  late Game game;

  setUpAll(() async {
    final result = getDebugInitGameResult();
    game = result.game;

    Hive.init('./.dart_tool/test_hive_side_menu');
    await Hive.openBox<dynamic>('games');
  });

  testWidgets('GameSideMenu builds empire buttons and close button calls onClose',
      (WidgetTester tester) async {
    final humanPlayerId = game.players.where((p) => p.isHuman).isNotEmpty
        ? game.players.where((p) => p.isHuman).first.id
        : game.players.first.id;

    var closed = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentGameProvider.overrideWith((ref) => game),
          currentOrdersProvider.overrideWith((ref) => const Orders()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                GameSideMenu(
                  game: game,
                  humanPlayerId: humanPlayerId,
                  sideMenuOpen: true,
                  onClose: () => closed = true,
                  onLocateCivilianUnit: (_) {},
                  onLocateMilitaryTile: (_, __) {},
                  onLocateNavalFleet: (_, __) {},
                  onCancelUnitWork: (_) {},
                  onStartWorkTargetSelection: (_, __) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Production'), findsOneWidget);
    expect(find.text('Diplomacy'), findsOneWidget);
    expect(find.text('×'), findsOneWidget);

    await tester.tap(find.text('×'));
    await tester.pumpAndSettle();

    expect(closed, isTrue);
  });

  testWidgets('GameSideMenu tapping Production navigates to ProductionScreen',
      (WidgetTester tester) async {
    final humanPlayerId = game.players.where((p) => p.isHuman).isNotEmpty
        ? game.players.where((p) => p.isHuman).first.id
        : game.players.first.id;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentGameProvider.overrideWith((ref) => game),
          currentOrdersProvider.overrideWith((ref) => const Orders()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                GameSideMenu(
                  game: game,
                  humanPlayerId: humanPlayerId,
                  sideMenuOpen: true,
                  onClose: () {},
                  onLocateCivilianUnit: (_) {},
                  onLocateMilitaryTile: (_, __) {},
                  onLocateNavalFleet: (_, __) {},
                  onCancelUnitWork: (_) {},
                  onStartWorkTargetSelection: (_, __) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Production'));
    await tester.pumpAndSettle();

    expect(find.byType(ProductionScreen), findsOneWidget);
    expect(find.text('Production'), findsOneWidget);
  });

  testWidgets('GameSideMenu tapping Technology navigates to TechnologyScreen',
      (WidgetTester tester) async {
    final humanPlayerId = game.players.where((p) => p.isHuman).isNotEmpty
        ? game.players.where((p) => p.isHuman).first.id
        : game.players.first.id;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentGameProvider.overrideWith((ref) => game),
          currentOrdersProvider.overrideWith((ref) => const Orders()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                GameSideMenu(
                  game: game,
                  humanPlayerId: humanPlayerId,
                  sideMenuOpen: true,
                  onClose: () {},
                  onLocateCivilianUnit: (_) {},
                  onLocateMilitaryTile: (_, __) {},
                  onLocateNavalFleet: (_, __) {},
                  onCancelUnitWork: (_) {},
                  onStartWorkTargetSelection: (_, __) {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Technology'));
    await tester.pumpAndSettle();

    expect(find.text('Technology'), findsOneWidget);
  });
}

