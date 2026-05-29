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
  const sameRegionWarpSea = 'sea_local';
  const sameRegionNonWarpSea = 'sea_plain';
  const crossRegionWarpSea = 'sea_nw';

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
        seaZoneDisplayNameById: const {
          'oldWorld|sea_ow': 'Origin Sea',
          'oldWorld|sea_local': 'Warp OW Sea',
          'oldWorld|sea_plain': 'Plain OW Sea',
          'newWorld|sea_nw': 'Cross NW Sea',
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
          id: sameRegionWarpSea,
          regionId: 'oldWorld',
          type: TopologyNodeType.seaZone,
        ),
        TopologyNode(
          id: sameRegionNonWarpSea,
          regionId: 'oldWorld',
          type: TopologyNodeType.seaZone,
        ),
        TopologyNode(
          id: crossRegionWarpSea,
          regionId: 'newWorld',
          type: TopologyNodeType.seaZone,
        ),
      ],
      edges: [
        TopologyEdge(id1: originSea, id2: sameRegionWarpSea),
        TopologyEdge(id1: originSea, id2: sameRegionNonWarpSea),
        TopologyEdge(id1: originSea, id2: crossRegionWarpSea),
        TopologyEdge(id1: sameRegionWarpSea, id2: crossRegionWarpSea),
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

  testWidgets('labels warp-zone destinations with warp copy only', (
    WidgetTester tester,
  ) async {
    await openDialog(tester, bus: AppEventBus.create());

    expect(
      find.textContaining('Move fleet — Fleet f_move (3 destinations)'),
      findsOneWidget,
    );
    // CtSectionLabel upper-cases its content per #2859 R9.
    expect(find.text('SEA ZONES'), findsOneWidget);
    expect(find.text('Warp OW Sea links'), findsOneWidget);
    expect(find.text('Plain OW Sea'), findsOneWidget);
    expect(find.text('Cross NW Sea links to New World'), findsOneWidget);
    expect(find.textContaining('Plain OW Sea links'), findsNothing);
    expect(find.textContaining('· Old World'), findsNothing);
    expect(find.textContaining('(cross-region)'), findsNothing);
  });

  testWidgets(
    'shows links-to Old World for new-world fleet cross-region picks',
    (WidgetTester tester) async {
      const humanId = 'gp_move_dialog_nw';
      const originSea = 'sea_nw_origin';
      const sameRegionAdjacentSea = 'sea_nw_local';
      const crossRegionAdjacentSea = 'sea_ow_cross';
      final game = Game(
        id: 'g_move_dialog_nw',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          portsByProvinceSeaboard: const {},
          seaZoneDisplayNameById: const {
            'newWorld|sea_nw_origin': 'Origin NW Sea',
            'newWorld|sea_nw_local': 'Adjacent NW Sea',
            'oldWorld|sea_ow_cross': 'Cross OW Sea',
          },
        ),
        players: const [
          Player(
            id: humanId,
            displayName: 'Move Dialog Tester NW',
            isHuman: true,
            capitalProvinceId: 'newWorld|port_home_nw',
            capitalTile: CapitalTile(
              regionId: 'newWorld',
              provinceId: 'newWorld|port_home_nw',
              x: 0,
              y: 0,
            ),
          ),
        ],
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: originSea,
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: sameRegionAdjacentSea,
            regionId: 'newWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: crossRegionAdjacentSea,
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [
          TopologyEdge(id1: originSea, id2: sameRegionAdjacentSea),
          TopologyEdge(id1: originSea, id2: crossRegionAdjacentSea),
        ],
      );
      final fleet = Fleet(
        id: 'f_move_nw',
        ownerId: humanId,
        regionId: 'newWorld',
        seaZoneId: originSea,
        ships: const [ShipInstance(id: 'ship_1', typeId: 'carrack')],
      );
      final bus = AppEventBus.create();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
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
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pump();

      expect(find.text('Adjacent NW Sea'), findsOneWidget);
      expect(find.text('Cross OW Sea links to Old World'), findsOneWidget);
      expect(find.textContaining('· New World'), findsNothing);
      expect(find.textContaining('(cross-region)'), findsNothing);
    },
  );

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

    await tester.tap(find.text('Cross NW Sea links to New World'));
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pump();

    expect(captured, isNotNull);
    expect(captured!.humanPlayerId, humanId);
    expect(captured!.moveOrder.fleetId, 'f_move');
    expect(captured!.moveOrder.destinationSeaZoneId, crossRegionWarpSea);
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
      of: find.byType(MoveFleetDialog),
      matching: find.byTooltip('Locate on map'),
    );
    expect(locateButtons, findsNWidgets(3));

    await tester.tap(locateButtons.first);
    await tester.pump();

    expect(locate, isNotNull);
    expect(locate!.regionId, 'newWorld');
    expect(locate!.tileKey, 'newWorld|port_nw|0|0');
  });

  testWidgets(
    'in-port fleet with combined topology shows Sea zones (issue #1446)',
    (WidgetTester tester) async {
      const ow = 'oldWorld';
      const localCap = 'port_cap';
      final fullCap = '$ow|$localCap';
      final combinedTopology = MapTopology(
        nodes: [
          TopologyNode(
            id: fullCap,
            regionId: ow,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: '$ow|sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: '$ow|sea2',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: [
          TopologyEdge(id1: fullCap, id2: '$ow|sea1'),
          TopologyEdge(id1: fullCap, id2: '$ow|sea2'),
          TopologyEdge(id1: '$ow|sea1', id2: '$ow|sea2'),
        ],
      );
      final gameInPort = Game(
        id: 'g_move_dialog_in_port',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: fullCap,
                regionId: ow,
                ownerId: humanId,
                displayName: 'Seabound Capital',
              ),
            ],
          ),
          newWorld: const RegionData(),
          portsByProvinceSeaboard: const {},
          seaZoneDisplayNameById: const {
            'oldWorld|sea1': 'First Sea',
            'oldWorld|sea2': 'Second Sea',
          },
        ),
        players: [
          Player(
            id: humanId,
            displayName: 'Move Dialog Tester',
            isHuman: true,
            capitalProvinceId: fullCap,
            capitalTile: CapitalTile(
              regionId: ow,
              provinceId: fullCap,
              x: 0,
              y: 0,
            ),
          ),
        ],
      );
      final fleetInPort = Fleet(
        id: 'f_in_port',
        ownerId: humanId,
        regionId: ow,
        seaZoneId: null,
        inPortAtProvinceId: fullCap,
        ships: const [ShipInstance(id: 'ship_1', typeId: 'carrack')],
      );
      final bus = AppEventBus.create();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                return TextButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => MoveFleetDialog(
                        game: gameInPort,
                        topology: combinedTopology,
                        humanPlayerId: humanId,
                        fleet: fleetInPort,
                        bus: bus,
                      ),
                    );
                  },
                  child: const Text('open'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pump();

      expect(
        find.text('No adjacent sea zones (check map topology).'),
        findsNothing,
      );
      // CtSectionLabel renders the localized header upper-cased; see the
      // section-header AC in SPEC/ui/move-fleet-dialog.md.
      expect(find.text('SEA ZONES'), findsOneWidget);
      expect(find.text('Second Sea'), findsOneWidget);
    },
  );

  testWidgets('sea zone section lists S–S neighbors only, not provinces', (
    WidgetTester tester,
  ) async {
    const humanId = 'gp_mix';
    const seaA = 'sea_a';
    const seaB = 'sea_b';
    const coastProv = 'coast_p';
    final game = Game(
      id: 'g_mix',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: [
            Province(
              id: 'oldWorld|inland_cap',
              regionId: 'oldWorld',
              ownerId: humanId,
              displayName: 'Inland Capital',
            ),
            Province(
              id: 'oldWorld|$coastProv',
              regionId: 'oldWorld',
              ownerId: humanId,
              displayName: 'Coastal Province',
            ),
          ],
        ),
        newWorld: const RegionData(),
        portsByProvinceSeaboard: const {},
        seaZoneDisplayNameById: const {
          'oldWorld|$seaA': 'Alpha Sea',
          'oldWorld|$seaB': 'Beta Sea',
        },
      ),
      players: const [
        Player(
          id: humanId,
          displayName: 'T',
          isHuman: true,
          capitalProvinceId: 'oldWorld|inland_cap',
          capitalTile: CapitalTile(
            regionId: 'oldWorld',
            provinceId: 'oldWorld|inland_cap',
            x: 0,
            y: 0,
          ),
        ),
      ],
    );
    const topology = MapTopology(
      nodes: [
        TopologyNode(
          id: seaA,
          regionId: 'oldWorld',
          type: TopologyNodeType.seaZone,
        ),
        TopologyNode(
          id: seaB,
          regionId: 'oldWorld',
          type: TopologyNodeType.seaZone,
        ),
        TopologyNode(
          id: coastProv,
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
      ],
      edges: [
        TopologyEdge(id1: seaA, id2: coastProv),
        TopologyEdge(id1: seaA, id2: seaB),
      ],
    );
    final fleet = Fleet(
      id: 'f_mix',
      ownerId: humanId,
      regionId: 'oldWorld',
      seaZoneId: seaA,
      ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
    );
    final bus = AppEventBus.create();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
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
                },
                child: const Text('open'),
              );
            },
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    // CtSectionLabel upper-cases its text per the editorial-monocle catalog
    // contract (#2859 R9). Section headers in the dialog now read
    // 'SEA ZONES' / 'PROVINCES (DOCK)'.
    expect(find.text('SEA ZONES'), findsOneWidget);
    expect(find.text('PROVINCES (DOCK)'), findsOneWidget);
    expect(find.text('Coastal Province'), findsOneWidget);
    expect(find.textContaining('Beta Sea'), findsOneWidget);
    expect(find.textContaining('Alpha Sea'), findsNothing);
  });
}
