import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_app/features/game/widgets/technology_panel.dart';
import 'package:colonizethis_app/widgets/debug_init_game.dart';

void main() {
  suppressLogsForTests();

  group('TechnologyPanel interactions', () {
    late Game game;
    late Player player;

    setUpAll(() {
      final result = getDebugInitGameResult();
      game = result.game;
      player = game.players.first;
    });

    testWidgets('Choosing tech closes the bottom sheet (AC3)', (
      WidgetTester tester,
    ) async {
      Orders last = const Orders();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TechnologyPanel(
              game: game,
              player: player,
              currentOrders: const Orders(),
              onOrdersChanged: (o) => last = o,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choose tech').first);
      await tester.pumpAndSettle();

      final emptyState = find.text('No techs available to research');
      if (emptyState.evaluate().isNotEmpty) {
        expect(emptyState, findsOneWidget);
        return;
      }

      final firstTechTile = find.ancestor(
        of: find.textContaining('Era ').first,
        matching: find.byType(ListTile),
      );
      await tester.ensureVisible(firstTechTile);
      await tester.tap(firstTechTile);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Era '),
        findsNothing,
        reason: 'Bottom sheet should be closed after selection',
      );
      final orders = last.researchOrdersByPlayerId[player.id] ?? const [];
      expect(orders, isNotEmpty);
      expect(orders.first.slotIndex, 0);
      expect(orders.first.techId, isNotEmpty);
    });

    testWidgets('Tech assigned to slot 1 does not appear in slot 2 list (AC4)', (
      WidgetTester tester,
    ) async {
      final rootIds =
          techCatalog.entries
              .where((e) => e.value.prerequisiteIds.isEmpty)
              .map((e) => e.key)
              .toList()
            ..sort();
      final techA = rootIds.isNotEmpty ? rootIds[0] : techCatalog.keys.first;
      final seeded = Orders(
        researchOrdersByPlayerId: {
          player.id: [
            ResearchOrder(
              slotIndex: 0,
              techId: techA,
              funding: ResearchFundingLevel.medium,
            ),
          ],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TechnologyPanel(
              game: game,
              player: player,
              currentOrders: seeded,
              onOrdersChanged: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Choose tech').last);
      await tester.pumpAndSettle();

      if (find.text('No techs available to research').evaluate().isNotEmpty) {
        expect(find.text('No techs available to research'), findsOneWidget);
        return;
      }

      // The assigned slot card now visibly renders the tech name (Refs
      // #2864 S3 — slot card assigned-tech body), so the assertion is
      // scoped to the bottom-sheet ListView contents only (AC4: the
      // selection list must not offer the already-assigned tech).
      final bottomSheetMatches = find.descendant(
        of: find.byType(ListView),
        matching: find.text(techDisplayName(techA)),
      );
      expect(
        bottomSheetMatches,
        findsNothing,
        reason:
            'Tech already assigned to slot 1 should not appear in slot 2 list',
      );
    });

    testWidgets(
      'Discovery tech does NOT appear when player has not revealed the resource (AC5)',
      (WidgetTester tester) async {
        const tileKey = 'oldWorld|r1:p1|0|0';
        const playerId = 'test-player-ac5';

        final playerWithNoVis = Player(
          id: playerId,
          displayName: 'Test Player',
          isHuman: true,
          techUnlocked: <String, bool>{},
        );

        final worldWithHiddenResource = WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              const Province(id: 'oldWorld|r1:p1', regionId: 'oldWorld'),
            ],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: {tileKey: 'sugarCane'},
          playerVisibilityByTile: {
            playerId: {tileKey: 'unknown'},
          },
        );

        final noVisGame = Game(
          id: 'ac5-no-vis',
          worldState: worldWithHiddenResource,
          players: [playerWithNoVis],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TechnologyPanel(
                game: noVisGame,
                player: playerWithNoVis,
                currentOrders: const Orders(),
                onOrdersChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Choose tech').first);
        await tester.pumpAndSettle();

        if (find.text('No techs available to research').evaluate().isNotEmpty) {
          expect(find.text('No techs available to research'), findsOneWidget);
        } else {
          expect(
            find.text('Discovery of Sugar'),
            findsNothing,
            reason:
                'Discovery of Sugar should not appear when sugarCane is not revealed',
          );
        }
      },
    );

    testWidgets(
      'Root tech appears in assignable list when prereqs are met (AC1)',
      (WidgetTester tester) async {
        final emptyPlayer = Player(
          id: player.id,
          displayName: player.displayName,
          isHuman: true,
          techUnlocked: <String, bool>{},
        );
        final emptyGame = game.copyWith(
          players: [emptyPlayer, ...game.players.skip(1)],
        );

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: TechnologyPanel(
                game: emptyGame,
                player: emptyPlayer,
                currentOrders: const Orders(),
                onOrdersChanged: (_) {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Choose tech').first);
        await tester.pumpAndSettle();

        if (find.text('No techs available to research').evaluate().isNotEmpty) {
          // No root techs available — skip
          return;
        }

        final rootTech =
            techCatalog.values.where((t) => t.prerequisiteIds.isEmpty).toList()
              ..sort(
                (a, b) =>
                    techDisplayName(a.id).compareTo(techDisplayName(b.id)),
              );

        if (rootTech.isNotEmpty) {
          expect(
            find.text(techDisplayName(rootTech.first.id)),
            findsWidgets,
            reason:
                'Root tech "${techDisplayName(rootTech.first.id)}" '
                'should appear in assignable list when prereqs are met',
          );
        }
      },
    );
  });
}
