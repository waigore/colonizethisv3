// DiplomacyPanel order UI + bus command emission coverage.
// Boycott pins: diplomacy_panel_orders_boycott_test.dart (Refs #4734 Slice F).
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter_test/flutter_test.dart';

import 'diplomacy_panel_orders_pump_support.dart';
import 'panel_test_fixtures.dart';
import 'widget_test_assets.dart';

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
      final game = buildDiplomacyPanelGameWithNoDiscoveredFactions();
      await pumpDiplomacyOrdersPanel(
        tester,
        game: game,
        humanId: game.players.first.id,
        settle: true,
      );

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
      final appendFuture =
          awaitDiplomacyBusEvent<AppendDiplomaticOrderRequestedEvent>(bus);
      autoConfirmDiplomacyDialogs(bus);

      await pumpDiplomacyOrdersPanel(
        tester,
        game: game,
        humanId: humanId,
        bus: bus,
      );

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

      await tapVisibleDiplomacy(tester, actionFinder!);
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
      final breakFuture = awaitDiplomacyBusEvent<BreakAllianceImmediatelyEvent>(
        bus,
      );
      autoConfirmDiplomacyDialogs(bus);

      await pumpDiplomacyOrdersPanel(
        tester,
        game: game,
        humanId: humanId,
        bus: bus,
      );
      await tapVisibleDiplomacy(tester, find.text('Break Alliance'));

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
      final removeFuture =
          awaitDiplomacyBusEvent<RemoveDiplomaticOrderRequestedEvent>(bus);

      await pumpDiplomacyOrdersPanel(
        tester,
        game: game,
        humanId: humanId,
        bus: bus,
        currentOrders: diplomacyPendingOrders(
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: target,
          ),
        ),
      );
      await tapVisibleDiplomacy(tester, find.text('Cancel').first);

      final event = await removeFuture;
      expect(event.playerId, humanId);
      expect(event.type, DiplomaticOrderType.declareWar);
      expect(event.targetFactionId, target);
    },
  );
}
