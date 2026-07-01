// DiplomacyPanel order UI + bus command emission coverage.
import 'package:colonizethis_app/features/game/widgets/diplomacy_panel.dart';
import 'package:colonizethis_app/widgets/ct_nine_patch_button.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/panel_test_fixtures.dart';
import 'support/widget_test_assets.dart';

Future<void> _bindTallTestSurface(WidgetTester tester) async {
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.binding.setSurfaceSize(const Size(800, 4000));
}

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
    'DiplomacyPanel Break Alliance confirm emits BreakAllianceImmediatelyEvent',
    (WidgetTester tester) async {
      final game = buildDiplomacyPanelTestGame().copyWith(
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 90,
            formalAlliance: true,
          ),
        ],
      );
      final humanId = game.players.firstWhere((p) => p.isHuman).id;
      final bus = AppEventBus.create();
      final breakFuture = bus
          .on<BreakAllianceImmediatelyEvent>()
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

      final breakButton = find.text('Break Alliance');
      expect(breakButton, findsOneWidget);
      await tester.ensureVisible(breakButton);
      await tester.tap(breakButton);
      await tester.pump();

      final event = await breakFuture;
      expect(event.playerId, humanId);
      expect(event.targetFactionId, 'gp2');
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

  testWidgets(
    'DiplomacyPanel colony holder shows Boycott enabled on GP row (Refs #3753 S14)',
    (WidgetTester tester) async {
      const humanId = kPanelTestHumanPlayerId;
      const target = 'gp2';
      final game = buildDiplomacyPanelTestGame().copyWith(
        colonyStates: const [
          ColonyState(tribeId: 't1', colonyOfGpId: humanId, sinceTurn: 1),
        ],
        tribes: const [Tribe(id: 't1', displayName: 'Aztec')],
      );
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

      expect(find.text('Boycott'), findsOneWidget);
      expect(find.text('Revoke Boycott'), findsOneWidget);

      await tester.ensureVisible(find.text('Boycott'));
      await tester.tap(find.text('Boycott'));
      await tester.pump();

      final event = await appendFuture;
      expect(event.playerId, humanId);
      expect(event.order.type, DiplomaticOrderType.boycott);
      expect(event.order.targetFactionId, target);
    },
  );

  testWidgets(
    'DiplomacyPanel active boycott shows Revoke Boycott enabled on GP row (Refs #3753 S14)',
    (WidgetTester tester) async {
      const humanId = kPanelTestHumanPlayerId;
      const target = 'gp2';
      final game = buildDiplomacyPanelTestGame().copyWith(
        colonyStates: const [
          ColonyState(tribeId: 't1', colonyOfGpId: humanId, sinceTurn: 1),
        ],
        tribes: const [Tribe(id: 't1', displayName: 'Aztec')],
        boycottStates: const [
          BoycottState(gpId: humanId, targetGpId: target, sinceTurn: 1),
        ],
      );
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

      expect(find.text('Revoke Boycott'), findsOneWidget);

      await tester.ensureVisible(find.text('Revoke Boycott'));
      await tester.tap(find.text('Revoke Boycott'));
      await tester.pump();

      final event = await appendFuture;
      expect(event.playerId, humanId);
      expect(event.order.type, DiplomaticOrderType.revokeBoycott);
      expect(event.order.targetFactionId, target);
    },
  );

  testWidgets(
    'DiplomacyPanel pending boycott shows Cancel and removes on tap (Refs #3753 S14)',
    (WidgetTester tester) async {
      const humanId = kPanelTestHumanPlayerId;
      const target = 'gp2';
      final game = buildDiplomacyPanelTestGame().copyWith(
        colonyStates: const [
          ColonyState(tribeId: 't1', colonyOfGpId: humanId, sinceTurn: 1),
        ],
        tribes: const [Tribe(id: 't1', displayName: 'Aztec')],
      );
      final bus = AppEventBus.create();
      final removeFuture = bus
          .on<RemoveDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));

      final currentOrders = Orders(
        diplomaticOrdersByPlayerId: {
          humanId: [
            DiplomaticOrder(
              type: DiplomaticOrderType.boycott,
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

      expect(find.text('Boycott'), findsNothing);
      final cancelButton = find.text('Cancel').first;
      expect(cancelButton, findsOneWidget);
      await tester.ensureVisible(cancelButton);
      await tester.tap(cancelButton);
      await tester.pump();

      final event = await removeFuture;
      expect(event.playerId, humanId);
      expect(event.type, DiplomaticOrderType.boycott);
      expect(event.targetFactionId, target);
    },
  );

  testWidgets(
    'DiplomacyPanel pending revokeBoycott shows Cancel and removes on tap (Refs #3753 S14)',
    (WidgetTester tester) async {
      const humanId = kPanelTestHumanPlayerId;
      const target = 'gp2';
      final game = buildDiplomacyPanelTestGame().copyWith(
        colonyStates: const [
          ColonyState(tribeId: 't1', colonyOfGpId: humanId, sinceTurn: 1),
        ],
        tribes: const [Tribe(id: 't1', displayName: 'Aztec')],
        boycottStates: const [
          BoycottState(gpId: humanId, targetGpId: target, sinceTurn: 1),
        ],
      );
      final bus = AppEventBus.create();
      final removeFuture = bus
          .on<RemoveDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));

      final currentOrders = Orders(
        diplomaticOrdersByPlayerId: {
          humanId: [
            DiplomaticOrder(
              type: DiplomaticOrderType.revokeBoycott,
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

      expect(find.text('Revoke Boycott'), findsNothing);
      final cancelButton = find.text('Cancel').first;
      expect(cancelButton, findsOneWidget);
      await tester.ensureVisible(cancelButton);
      await tester.tap(cancelButton);
      await tester.pump();

      final event = await removeFuture;
      expect(event.playerId, humanId);
      expect(event.type, DiplomaticOrderType.revokeBoycott);
      expect(event.targetFactionId, target);
    },
  );

  testWidgets(
    'DiplomacyPanel Boycott disabled when human holds no colony (Refs #3753 S14)',
    (WidgetTester tester) async {
      const humanId = kPanelTestHumanPlayerId;
      final game = buildDiplomacyPanelTestGame();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiplomacyPanel(
              game: game,
              humanPlayerId: humanId,
              topology: const MapTopology(),
              currentOrders: const Orders(),
              bus: AppEventBus.create(),
            ),
          ),
        ),
      );
      await tester.pump();

      final boycottButton = find.widgetWithText(CtNinePatchButton, 'Boycott');
      expect(boycottButton, findsOneWidget);
      expect(tester.widget<CtNinePatchButton>(boycottButton).enabled, isFalse);
    },
  );

  testWidgets(
    'DiplomacyPanel Minor row omits Boycott controls (Refs #3753 S14 negative)',
    (WidgetTester tester) async {
      const humanId = kPanelTestHumanPlayerId;
      final game = buildDiplomacyRichPanelTestGame();

      await _bindTallTestSurface(tester);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: DiplomacyPanel(
              game: game,
              humanPlayerId: humanId,
              topology: const MapTopology(),
              currentOrders: const Orders(),
              bus: AppEventBus.create(),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.text('Minors only'));
      await tester.pump();

      expect(find.text('Free City'), findsOneWidget);
      expect(find.text('Boycott'), findsNothing);
      expect(find.text('Revoke Boycott'), findsNothing);
    },
  );

  testWidgets(
    'DiplomacyPanel pending setSubsidy shows percent line and Cancel (Refs #3753 S15)',
    (WidgetTester tester) async {
      const humanId = kPanelTestHumanPlayerId;
      const minorId = 'm1';
      const percent = 15;
      final game = buildDiplomacyRichPanelTestGame();
      final bus = AppEventBus.create();
      final removeFuture = bus
          .on<RemoveDiplomaticOrderRequestedEvent>()
          .first
          .timeout(const Duration(seconds: 2));

      final currentOrders = Orders(
        diplomaticOrdersByPlayerId: {
          humanId: [
            DiplomaticOrder(
              type: DiplomaticOrderType.setSubsidy,
              targetFactionId: minorId,
              amount: percent,
            ),
          ],
        },
      );

      await _bindTallTestSurface(tester);
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

      await tester.tap(find.text('Minors only'));
      await tester.pump();

      expect(
        find.text('Pending subsidy: $percent% (resolves end of turn)'),
        findsOneWidget,
      );
      expect(find.text('Set Subsidy ($percent%)'), findsNothing);

      final cancelButton = find.text('Cancel').first;
      await tester.ensureVisible(cancelButton);
      await tester.tap(cancelButton);
      await tester.pump();

      final event = await removeFuture;
      expect(event.playerId, humanId);
      expect(event.type, DiplomaticOrderType.setSubsidy);
      expect(event.targetFactionId, minorId);
    },
  );
}
