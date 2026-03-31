import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/move_fleet_dialog.dart';

Widget _openDialogButton(VoidCallback onOpen) {
  return TextButton(onPressed: onOpen, child: const Text('open'));
}

void main() {
  suppressLogsForTests();

  const humanId = 'gp_move_dialog';
  const originSea = 'sea_ow';
  const sameRegionAdjacentSea = 'sea_local';
  const crossRegionAdjacentSea = 'sea_nw';

  Game buildGame() {
    return Game(
      id: 'g_move_dialog',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: const RegionData(
          provinces: [
            Province(
              id: 'port_home',
              regionId: 'oldWorld',
              ownerId: humanId,
              displayName: 'Home Port',
            ),
          ],
        ),
        newWorld: const RegionData(),
        portsByProvinceSeaboard: const {
          'oldWorld|port_home|sea_local': 'oldWorld|port_home|0|0',
          'newWorld|port_nw|sea_nw': 'newWorld|port_nw|0|0',
        },
      ),
      players: const [
        Player(
          id: humanId,
          displayName: 'Move Dialog Tester',
          isHuman: true,
          capitalProvinceId: 'oldWorld|port_home',
          capitalTile: CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|port_home',
            x: 0,
            y: 0,
          ),
        ),
      ],
    );
  }

  MapTopology buildTopology() {
    return const MapTopology(
      nodes: [
        TopologyNode(
          id: originSea,
          regionId: 'oldWorld',
          type: TopologyNodeType.seaZone,
        ),
        TopologyNode(
          id: sameRegionAdjacentSea,
          regionId: 'oldWorld',
          type: TopologyNodeType.seaZone,
        ),
        TopologyNode(
          id: crossRegionAdjacentSea,
          regionId: 'newWorld',
          type: TopologyNodeType.seaZone,
        ),
      ],
      edges: [
        TopologyEdge(id1: originSea, id2: sameRegionAdjacentSea),
        TopologyEdge(id1: originSea, id2: crossRegionAdjacentSea),
      ],
    );
  }

  Fleet buildFleet() {
    return Fleet(
      id: 'f_move',
      ownerId: humanId,
      regionId: 'oldWorld',
      seaZoneId: originSea,
      ships: const [ShipInstance(id: 'ship_1', typeId: 'carrack')],
    );
  }

  Future<void> openDialog(
    WidgetTester tester, {
    required AppEventBus bus,
  }) async {
    final game = buildGame();
    final topology = buildTopology();
    final fleet = buildFleet();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return _openDialogButton(() {
                showDialog<void>(
                  context: context,
                  builder: (_) => MoveFleetDialog(
                    game: game,
                    topology: topology,
                    humanPlayerId: humanId,
                    fleet: fleet,
                    bus: bus,
                  ),
                );
              });
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pump();
  }

  testWidgets('shows cross-region destination label in sea-zone picks', (
    WidgetTester tester,
  ) async {
    await openDialog(tester, bus: AppEventBus.create());

    expect(find.text('Sea zones'), findsOneWidget);
    expect(find.text('$sameRegionAdjacentSea · Old World'), findsOneWidget);
    expect(
      find.text('$crossRegionAdjacentSea · New World (cross-region)'),
      findsOneWidget,
    );
  });

  testWidgets('confirm emits NavalMoveFleetRequestedEvent and closes dialog', (
    WidgetTester tester,
  ) async {
    NavalMoveFleetRequestedEvent? captured;
    final bus = AppEventBus.create();
    final sub = bus.on<NavalMoveFleetRequestedEvent>().listen((e) {
      captured = e;
    });
    addTearDown(sub.cancel);

    await openDialog(tester, bus: bus);

    await tester.tap(find.text('$crossRegionAdjacentSea · New World (cross-region)'));
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pump();

    expect(captured, isNotNull);
    expect(captured!.humanPlayerId, humanId);
    expect(captured!.moveOrder.fleetId, 'f_move');
    expect(captured!.moveOrder.destinationSeaZoneId, crossRegionAdjacentSea);
    expect(captured!.moveOrder.destinationPortProvinceId, isNull);
    expect(find.text('Move fleet — f_move'), findsNothing);
  });

  testWidgets('cancel closes dialog without emitting move request', (
    WidgetTester tester,
  ) async {
    NavalMoveFleetRequestedEvent? captured;
    final bus = AppEventBus.create();
    final sub = bus.on<NavalMoveFleetRequestedEvent>().listen((e) {
      captured = e;
    });
    addTearDown(sub.cancel);

    await openDialog(tester, bus: bus);

    await tester.tap(find.text('Cancel'));
    await tester.pump();

    expect(captured, isNull);
    expect(find.text('Move fleet — f_move'), findsNothing);
  });

  testWidgets('locate icon emits LocateMapTileEvent for selected row', (
    WidgetTester tester,
  ) async {
    LocateMapTileEvent? locate;
    final bus = AppEventBus.create();
    final sub = bus.on<LocateMapTileEvent>().listen((e) {
      locate = e;
    });
    addTearDown(sub.cancel);

    await openDialog(tester, bus: bus);

    final locateButtons = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byTooltip('Locate on map'),
    );
    expect(locateButtons, findsNWidgets(2));

    await tester.tap(locateButtons.at(1));
    await tester.pump();

    expect(locate, isNotNull);
    expect(locate!.regionId, 'newWorld');
    expect(locate!.tileKey, 'newWorld|port_nw|0|0');
  });
}
