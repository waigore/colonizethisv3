// Fleet-marker routing + Sail row tests (Refs #4343).
// SPEC: SPEC/ui/map-widget.md, naval-mission-menu-dialog.md, move-fleet-dialog.md.

import 'package:colonizethis_app/features/game/widgets/unit_orders/in_port_fleet_marker_actions_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_fleet_marker_flow.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_flow.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/naval_mission_menu_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/split_fleet_dialog.dart';
import 'package:colonizethis_app/features/game/widgets/unit_orders/transfer_to_home_fleet_dialog.dart';
import 'package:colonizethis_app_fixtures/config/ct_e2e.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart'
    show navalMissionAvailabilityForFleet;
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'app_shell_harness.dart';
import 'naval_units_panel_test_support.dart';

void main() {
  suppressLogsForTests();

  const humanId = 'gp_marker_route';
  const locationScope = 'port:oldWorld|cap1';
  const tileKey = 'oldWorld|cap1|0|0';

  Game homeOnlyGame() => buildNavalPanelCapitalHomeAndPeersGame(
    humanId: humanId,
    gameId: 'g_marker_home',
    displayName: 'Marker Home',
    peerFleets: const [],
  );

  Game inPortPeerGame() => buildNavalPanelCapitalHomeAndPeersGame(
    humanId: humanId,
    gameId: 'g_marker_in_port',
    displayName: 'Marker In Port',
    peerFleets: [
      navalPanelPortPeer(
        id: 'f_in_port',
        humanId: humanId,
        ships: const [ShipInstance(id: 's_port', typeId: 'carrack')],
      ),
    ],
  );

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

  group('showNavalFleetMarkerFlow', () {
    testWidgets('non-empty Home Fleet opens detach-then-sail split', (
      tester,
    ) async {
      final game = homeOnlyGame();
      final bus = AppEventBus();
      OpenNavalUnitsPanelEvent? opened;
      addTearDown(
        bus.on<OpenNavalUnitsPanelEvent>().listen((e) => opened = e).cancel,
      );

      await pumpOpenButton(
        tester,
        onPressed: (context) => showNavalFleetMarkerFlow(
          context: context,
          game: game,
          topology: buildUnitsPanelCapitalAdjacentSeaTopology(),
          humanPlayerId: humanId,
          draftOrders: const Orders(),
          bus: bus,
          fleetIds: [homeFleetIdFor(humanId)],
          locationScopeKey: locationScope,
          tileScopeTileKey: tileKey,
        ),
      );
      await tester.tap(find.text('open-flow'));
      await tester.pumpAndSettle();

      expect(opened, isNull);
      expect(find.byType(SplitFleetDialog), findsOneWidget);
      expect(find.byType(MoveFleetDialog), findsNothing);
      expect(find.byType(NavalMissionMenuDialog), findsNothing);
    });

    testWidgets('empty Home Fleet only opens tile-scoped Naval Units event', (
      tester,
    ) async {
      final game = buildNavalPanelCapitalHomeAndPeersGame(
        humanId: humanId,
        gameId: 'g_marker_home_empty',
        displayName: 'Marker Home Empty',
        peerFleets: const [],
        homeShips: const [],
      );
      final bus = AppEventBus();
      OpenNavalUnitsPanelEvent? opened;
      addTearDown(
        bus.on<OpenNavalUnitsPanelEvent>().listen((e) => opened = e).cancel,
      );

      await pumpOpenButton(
        tester,
        onPressed: (context) => showNavalFleetMarkerFlow(
          context: context,
          game: game,
          topology: const MapTopology(),
          humanPlayerId: humanId,
          draftOrders: const Orders(),
          bus: bus,
          fleetIds: [homeFleetIdFor(humanId)],
          locationScopeKey: locationScope,
          tileScopeTileKey: tileKey,
        ),
      );
      await tester.tap(find.text('open-flow'));
      await tester.pumpAndSettle();

      expect(opened, isNotNull);
      expect(opened!.locationScopeKey, locationScope);
      expect(opened!.tileScopeTileKey, tileKey);
      expect(opened!.initialSelectedFleetId, homeFleetIdFor(humanId));
      expect(find.byType(MoveFleetDialog), findsNothing);
      expect(find.byType(NavalMissionMenuDialog), findsNothing);
      expect(find.byType(SplitFleetDialog), findsNothing);
    });

    testWidgets('capital in-port sea-going opens chooser then Move on Sail', (
      tester,
    ) async {
      final game = inPortPeerGame();
      final bus = AppEventBus();
      OpenNavalUnitsPanelEvent? openedPanel;
      addTearDown(
        bus
            .on<OpenNavalUnitsPanelEvent>()
            .listen((e) => openedPanel = e)
            .cancel,
      );

      await pumpOpenButton(
        tester,
        onPressed: (context) => showNavalFleetMarkerFlow(
          context: context,
          game: game,
          topology: buildUnitsPanelCapitalAdjacentSeaTopology(),
          humanPlayerId: humanId,
          draftOrders: const Orders(),
          bus: bus,
          fleetIds: const ['f_in_port'],
          locationScopeKey: locationScope,
          tileScopeTileKey: tileKey,
        ),
      );
      await tester.tap(find.text('open-flow'));
      await tester.pumpAndSettle();

      expect(find.byType(InPortFleetMarkerActionsDialog), findsOneWidget);
      expect(find.byType(MoveFleetDialog), findsNothing);
      await tester.tap(find.text('Sail / Move'));
      await tester.pumpAndSettle();

      expect(find.byType(MoveFleetDialog), findsOneWidget);
      expect(find.byType(NavalMissionMenuDialog), findsNothing);
      expect(find.byType(TransferToHomeFleetDialog), findsNothing);
      expect(openedPanel, isNull);
    });

    testWidgets('capital in-port chooser Transfer opens DLG40001', (
      tester,
    ) async {
      final game = inPortPeerGame();
      final bus = AppEventBus();

      await pumpOpenButton(
        tester,
        onPressed: (context) => showNavalFleetMarkerFlow(
          context: context,
          game: game,
          topology: buildUnitsPanelCapitalAdjacentSeaTopology(),
          humanPlayerId: humanId,
          draftOrders: const Orders(),
          bus: bus,
          fleetIds: const ['f_in_port'],
          locationScopeKey: locationScope,
          tileScopeTileKey: tileKey,
        ),
      );
      await tester.tap(find.text('open-flow'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Transfer to Home Fleet'));
      await tester.pumpAndSettle();

      expect(find.byType(TransferToHomeFleetDialog), findsOneWidget);
      expect(find.byType(MoveFleetDialog), findsNothing);
      expect(find.byType(InPortFleetMarkerActionsDialog), findsNothing);
    });

    testWidgets('non-capital in-port sea-going opens Move without chooser', (
      tester,
    ) async {
      final game = buildNavalPanelCapitalHomeAndPeersGame(
        humanId: humanId,
        gameId: 'g_marker_outport',
        displayName: 'Marker Outport',
        peerFleets: [
          navalPanelPortPeer(
            id: 'f_out_port',
            humanId: humanId,
            ships: const [ShipInstance(id: 's_out', typeId: 'carrack')],
            port: 'oldWorld|port1',
          ),
        ],
      );
      final bus = AppEventBus();

      await pumpOpenButton(
        tester,
        onPressed: (context) => showNavalFleetMarkerFlow(
          context: context,
          game: game,
          topology: buildUnitsPanelCapitalAdjacentSeaTopology(),
          humanPlayerId: humanId,
          draftOrders: const Orders(),
          bus: bus,
          fleetIds: const ['f_out_port'],
          locationScopeKey: 'port:oldWorld|port1',
          tileScopeTileKey: 'oldWorld|port1|0|0',
        ),
      );
      await tester.tap(find.text('open-flow'));
      await tester.pumpAndSettle();

      expect(find.byType(InPortFleetMarkerActionsDialog), findsNothing);
      expect(find.byType(MoveFleetDialog), findsOneWidget);
      expect(find.byType(TransferToHomeFleetDialog), findsNothing);
    });

    testWidgets('stacked marker Home Fleet pick never opens Move', (
      tester,
    ) async {
      final game = inPortPeerGame();
      final bus = AppEventBus();
      OpenNavalUnitsPanelEvent? opened;
      addTearDown(
        bus.on<OpenNavalUnitsPanelEvent>().listen((e) => opened = e).cancel,
      );
      final homeId = homeFleetIdFor(humanId);

      await pumpOpenButton(
        tester,
        onPressed: (context) => showNavalFleetMarkerFlow(
          context: context,
          game: game,
          topology: buildUnitsPanelCapitalAdjacentSeaTopology(),
          humanPlayerId: humanId,
          draftOrders: const Orders(),
          bus: bus,
          fleetIds: [homeId, 'f_in_port'],
          locationScopeKey: locationScope,
          tileScopeTileKey: tileKey,
        ),
      );
      await tester.tap(find.text('open-flow'));
      await tester.pumpAndSettle();

      expect(find.text('Select fleet'), findsOneWidget);
      await tester.tap(find.text('Fleet $homeId'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Confirm'));
      await tester.pumpAndSettle();

      expect(opened, isNull);
      expect(find.byType(MoveFleetDialog), findsNothing);
      expect(find.byType(SplitFleetDialog), findsOneWidget);
    });

    testWidgets('at-sea marker opens mission menu with Sail row', (
      tester,
    ) async {
      final game = atSeaPeerGame();
      final bus = AppEventBus();

      await pumpOpenButton(
        tester,
        onPressed: (context) => showNavalFleetMarkerFlow(
          context: context,
          game: game,
          topology: const MapTopology(),
          humanPlayerId: humanId,
          draftOrders: const Orders(),
          bus: bus,
          fleetIds: const ['sea_named'],
          locationScopeKey: 'sea:oldWorld|zone_alpha',
          tileScopeTileKey: 'oldWorld|zone_alpha|0|0',
        ),
      );
      await tester.tap(find.text('open-flow'));
      await tester.pumpAndSettle();

      expect(find.byType(NavalMissionMenuDialog), findsOneWidget);
      expect(find.text('Sail / Move'), findsOneWidget);
      expect(find.text('Patrol'), findsOneWidget);
    });
  });

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
