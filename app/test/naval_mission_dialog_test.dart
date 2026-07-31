// Naval mission assign dialog widget tests (Refs #4213 slice B).

import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_data/colonizethis_data.dart' show MapTopology;
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_menu_dialog.dart';
import 'app_shell_harness.dart';
import 'naval_units_panel_test_scenarios.dart';
import 'naval_units_panel_test_support.dart';

void main() {
  group('Naval mission assign UI', () {
    testWidgets('panel Mission action stages patrol draft', (tester) async {
      final game = buildNavalPanelNamedSeaZoneGame();
      final bus = AppEventBus();
      final humanId = 'gp_named_sea';
      var orders = const Orders();
      bus.on<NavalMissionRequestedEvent>().listen((e) {
        orders = applyNavalMissionOrderForPlayer(
          orders,
          e.humanPlayerId,
          e.missionOrder,
        );
      });

      await tester.pumpWidget(
        buildNavalPanel(
          game: game,
          humanPlayerId: humanId,
          bus: bus,
          draftOrders: orders,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(kCtE2EFleetMissionActionKey));
      await tester.pumpAndSettle();

      expect(find.text('Assign mission — Fleet sea_named'), findsOneWidget);
      await tester.tap(find.text('Patrol'));
      await tester.pumpAndSettle();

      expect(
        orders.navalMissionOrdersByPlayerId[humanId]?.single.mission,
        'patrol',
      );
    });

    testWidgets('menu hides blockade when no war targets', (tester) async {
      final game = buildNavalPanelNamedSeaZoneGame();
      final fleet = game.worldState.fleets.single;
      final availability = navalMissionAvailabilityForFleet(
        game: game,
        topology: const MapTopology(),
        playerId: 'gp_named_sea',
        fleet: fleet,
        currentOrders: const Orders(),
      );

      await tester.pumpWidget(
        buildAppShell(
          child: NavalMissionMenuDialog(
            game: game,
            fleet: fleet,
            availability: availability,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Blockade'), findsOneWidget);
      final blockadeTile = tester.widget<ListTile>(
        find.ancestor(
          of: find.text('Blockade'),
          matching: find.byType(ListTile),
        ),
      );
      expect(blockadeTile.enabled, isFalse);
    });

    testWidgets('cancel pending removes draft mission', (tester) async {
      final game = buildNavalPanelNamedSeaZoneGame();
      final bus = AppEventBus();
      final humanId = 'gp_named_sea';
      var orders = Orders(
        navalMissionOrdersByPlayerId: {
          humanId: const [
            NavalMissionOrder(fleetId: 'sea_named', mission: 'patrol'),
          ],
        },
      );
      bus.on<NavalMissionCancelRequestedEvent>().listen((e) {
        orders = removeNavalMissionOrderForPlayer(
          orders,
          e.humanPlayerId,
          e.fleetId,
        );
      });

      await tester.pumpWidget(
        buildNavalPanel(
          game: game,
          humanPlayerId: humanId,
          bus: bus,
          draftOrders: orders,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(kCtE2EFleetMissionActionKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel pending mission'));
      await tester.pumpAndSettle();

      expect(orders.navalMissionOrdersByPlayerId[humanId], isEmpty);
    });
  });
}
