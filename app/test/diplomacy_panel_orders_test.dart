// DiplomacyPanel order UI + bus command emission coverage.
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/panel_test_fixtures.dart';
import 'support/widget_test_assets.dart';

void main() {
  suppressLogsForTests();
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await setUpNinePatchAssets();
  });

  setUp(() {
    AppEventBus.reset();
  });

  testWidgets(
    'DiplomacyPanel shows always-visible section headings + tribe placeholder '
    'when no factions discovered',
    (WidgetTester tester) async {
      const humanId = 'solo';
      final game = Game(
        id: 'solo_game',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(id: humanId, displayName: 'Only', isHuman: true, treasury: 0),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiplomacyPanel(
              game: game,
              humanPlayerId: humanId,
              topology: MapTopology(),
              currentOrders: const Orders(),
              bus: AppEventBus.create(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // SPEC/ui/diplomacy-panel.md § Section headings (Refs #3341).
      expect(find.text('Great Powers'), findsOneWidget);
      expect(find.text('Minor Nations'), findsOneWidget);
      expect(find.text('Tribes'), findsOneWidget);
      expect(find.text('No tribes contacted yet.'), findsOneWidget);
    },
  );

  testWidgets(
    'DiplomacyPanel confirm action emits AppendDiplomaticOrderRequestedEvent',
    (WidgetTester tester) async {
      final game = buildDiplomacyPanelTestGame();
      final humanId = game.players.firstWhere((p) => p.isHuman).id;
      final bus = AppEventBus.create();
      final appendFuture = bus
          .on<AppendDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));

      final confirmSub = bus.on<ConfirmDialogEvent>().listen((event) {
        event.result(true);
      });
      addTearDown(confirmSub.cancel);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiplomacyPanel(
              game: game,
              humanPlayerId: humanId,
              topology: const MapTopology(),
              currentOrders: const Orders(),
              bus: bus,
            ),
          ),
        ),
      );
      await tester.pump();

      const actionLabels = <String>['Declare War', 'Offer Peace', 'Alliance'];
      Finder? actionFinder;
      for (final label in actionLabels) {
        final candidate = find.text(label);
        if (candidate.evaluate().isNotEmpty) {
          actionFinder = candidate.first;
          break;
        }
      }
      expect(
        actionFinder,
        isNotNull,
        reason: 'Expected at least one non-parameter diplomacy action button',
      );

      await tester.ensureVisible(actionFinder!);
      await tester.tap(actionFinder);
      await tester.pump();

      final event = await appendFuture;
      expect(event.playerId, humanId);
    },
  );

  testWidgets(
    'DiplomacyPanel pending cancel emits RemoveDiplomaticOrderRequestedEvent',
    (WidgetTester tester) async {
      final game = buildDiplomacyPanelTestGame();
      final humanId = game.players.firstWhere((p) => p.isHuman).id;
      final target = game.players.firstWhere((p) => p.id != humanId).id;
      final bus = AppEventBus.create();
      final removeFuture = bus
          .on<RemoveDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));

      final currentOrders = Orders(
        diplomaticOrdersByPlayerId: {
          humanId: [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: target,
            ),
          ],
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiplomacyPanel(
              game: game,
              humanPlayerId: humanId,
              topology: const MapTopology(),
              currentOrders: currentOrders,
              bus: bus,
            ),
          ),
        ),
      );
      await tester.pump();

      final cancelButton = find.text('Cancel').first;
      await tester.ensureVisible(cancelButton);
      await tester.tap(cancelButton);
      await tester.pump();

      final event = await removeFuture;
      expect(event.playerId, humanId);
      expect(event.type, DiplomaticOrderType.declareWar);
      expect(event.targetFactionId, target);
    },
  );
}
