// DLG31001 Sail / Move row tests (Refs #4343).
// SPEC: SPEC/ui/naval-mission-menu-dialog.md, move-fleet-dialog.md.

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_flow.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_menu_dialog.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show applyNavalMoveOrderForPlayer, navalMissionAvailabilityForFleet;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'naval_units_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  const humanId = 'gp_marker_route';

  Game atSeaPeerGame() => buildNavalPanelNamedSeaZoneGame(humanId: humanId);

  MapTopology adjacentSeasTopology() => const MapTopology(
    nodes: [
      TopologyNode(
        id: 'zone_alpha',
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
      TopologyNode(
        id: 'zone_beta',
        regionId: 'oldWorld',
        type: TopologyNodeType.seaZone,
      ),
    ],
    edges: [TopologyEdge(id1: 'zone_alpha', id2: 'zone_beta')],
  );

  Future<void> pumpOpenButton(
    WidgetTester tester, {
    required Future<void> Function(BuildContext context) onPressed,
  }) async {
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () => onPressed(context),
                child: const Text('open-flow'),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('DLG31001 Sail / Move', () {
    testWidgets('menu always lists Sail / Move', (tester) async {
      final game = atSeaPeerGame();
      final fleet = game.worldState.fleets.single;
      final availability = navalMissionAvailabilityForFleet(
        game: game,
        topology: const MapTopology(),
        playerId: humanId,
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
      expect(find.text('Sail / Move'), findsOneWidget);
      expect(
        find.text('Move this fleet to an adjacent sea zone or owned port.'),
        findsOneWidget,
      );
    });

    testWidgets('confirming Sail move clears pending mission (XOR)', (
      tester,
    ) async {
      await bindFixedTestSurface(tester, const Size(800, 1200));
      final game = atSeaPeerGame();
      final bus = AppEventBus();
      var orders = Orders(
        navalMissionOrdersByPlayerId: {
          humanId: [NavalMissionOrder(fleetId: 'sea_named', mission: 'patrol')],
        },
      );
      bus.on<NavalMoveFleetRequestedEvent>().listen((e) {
        orders = applyNavalMoveOrderForPlayer(
          orders,
          e.humanPlayerId,
          e.moveOrder,
        );
      });

      final fleet = game.worldState.fleets.single;
      await pumpOpenButton(
        tester,
        onPressed: (context) => showNavalMissionFlow(
          context: context,
          game: game,
          topology: adjacentSeasTopology(),
          humanPlayerId: humanId,
          draftOrders: orders,
          bus: bus,
          fleetIds: [fleet.id],
        ),
      );
      await tester.tap(find.text('open-flow'));
      await tester.pumpAndSettle();

      final sailFinder = find.text('Sail / Move');
      await tester.ensureVisible(sailFinder);
      await tester.tap(sailFinder);
      await tester.pumpAndSettle();
      expect(find.byType(MoveFleetDialog), findsOneWidget);

      // Prefer e2e keys when CT_E2E is on; otherwise tap the destination label.
      final seaRow = find.byKey(
        kCtE2EMoveFleetDestinationSeaZoneRowKey('zone_beta'),
      );
      if (seaRow.evaluate().isNotEmpty) {
        await tester.ensureVisible(seaRow);
        await tester.tap(seaRow);
      } else {
        final label = find.text('zone_beta');
        await tester.ensureVisible(label);
        await tester.tap(label);
      }
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(orders.navalMissionOrdersByPlayerId[humanId] ?? const [], isEmpty);
      expect(
        orders.navalMoveOrdersByPlayerId[humanId]?.single.fleetId,
        'sea_named',
      );
      expect(
        orders.navalMoveOrdersByPlayerId[humanId]?.single.destinationSeaZoneId,
        'zone_beta',
      );
    });
  });
}
