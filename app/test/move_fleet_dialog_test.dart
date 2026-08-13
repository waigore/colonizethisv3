import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart' show suppressLogsForTests;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:colonizethis_app/features/game/widgets/unit_orders/move_fleet_dialog.dart';

import 'app_shell_harness.dart';

Widget _openDialogButton(VoidCallback onOpen) {
  return TextButton(onPressed: onOpen, child: const Text('open'));
}

T? Function() _captureBusEvent<T extends AppEvent>(AppEventBus bus) {
  T? captured;
  addTearDown(bus.on<T>().listen((e) => captured = e).cancel);
  return () => captured;
}

TopologyNode _seaNode(String id, String regionId) => TopologyNode(
  id: id,
  regionId: regionId,
  type: TopologyNodeType.seaZone,
);

void main() {
  suppressLogsForTests();

  const humanId = 'gp_move_dialog';
  const originSea = 'sea_ow';
  const sameRegionWarpSea = 'sea_local';
  const sameRegionNonWarpSea = 'sea_plain';
  const crossRegionWarpSea = 'sea_nw';

  Game buildGame() => Game(
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

  MapTopology buildTopology() => MapTopology(
    nodes: [
      _seaNode(originSea, 'oldWorld'),
      _seaNode(sameRegionWarpSea, 'oldWorld'),
      _seaNode(sameRegionNonWarpSea, 'oldWorld'),
      _seaNode(crossRegionWarpSea, 'newWorld'),
    ],
    edges: const [
      TopologyEdge(id1: originSea, id2: sameRegionWarpSea),
      TopologyEdge(id1: originSea, id2: sameRegionNonWarpSea),
      TopologyEdge(id1: originSea, id2: crossRegionWarpSea),
      TopologyEdge(id1: sameRegionWarpSea, id2: crossRegionWarpSea),
    ],
  );

  Fleet buildFleet() => Fleet(
    id: 'f_move',
    ownerId: humanId,
    regionId: 'oldWorld',
    seaZoneId: originSea,
    ships: const [ShipInstance(id: 'ship_1', typeId: 'carrack')],
  );

  Future<void> openDialog(
    WidgetTester tester, {
    required AppEventBus bus,
    Game? game,
    MapTopology? topology,
    Fleet? fleet,
    String playerId = humanId,
  }) async {
    final resolvedGame = game ?? buildGame();
    final resolvedTopology = topology ?? buildTopology();
    final resolvedFleet = fleet ?? buildFleet();
    // Editorial shell via buildAppShell (Refs #4035 — no inline MaterialApp).
    await tester.pumpWidget(
      buildAppShell(
        child: Scaffold(
          body: Builder(
            builder: (context) {
              return _openDialogButton(() {
                showDialog<void>(
                  context: context,
                  builder: (_) => MoveFleetDialog(
                    game: resolvedGame,
                    topology: resolvedTopology,
                    humanPlayerId: playerId,
                    fleet: resolvedFleet,
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
      const nwHumanId = 'gp_move_dialog_nw';
      const nwOriginSea = 'sea_nw_origin';
      const sameRegionAdjacentSea = 'sea_nw_local';
      const crossRegionAdjacentSea = 'sea_ow_cross';
      await openDialog(
        tester,
        bus: AppEventBus.create(),
        playerId: nwHumanId,
        game: Game(
          id: 'g_move_dialog_nw',
          worldState: const WorldState(
            turnState: TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(),
            newWorld: RegionData(),
            seaZoneDisplayNameById: {
              'newWorld|sea_nw_origin': 'Origin NW Sea',
              'newWorld|sea_nw_local': 'Adjacent NW Sea',
              'oldWorld|sea_ow_cross': 'Cross OW Sea',
            },
          ),
          players: const [
            Player(
              id: nwHumanId,
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
        ),
        topology: MapTopology(
          nodes: [
            _seaNode(nwOriginSea, 'newWorld'),
            _seaNode(sameRegionAdjacentSea, 'newWorld'),
            _seaNode(crossRegionAdjacentSea, 'oldWorld'),
          ],
          edges: const [
            TopologyEdge(id1: nwOriginSea, id2: sameRegionAdjacentSea),
            TopologyEdge(id1: nwOriginSea, id2: crossRegionAdjacentSea),
          ],
        ),
        fleet: Fleet(
          id: 'f_move_nw',
          ownerId: nwHumanId,
          regionId: 'newWorld',
          seaZoneId: nwOriginSea,
          ships: const [ShipInstance(id: 'ship_1', typeId: 'carrack')],
        ),
      );

      expect(find.text('Adjacent NW Sea'), findsOneWidget);
      expect(find.text('Cross OW Sea links to Old World'), findsOneWidget);
      expect(find.textContaining('· New World'), findsNothing);
      expect(find.textContaining('(cross-region)'), findsNothing);
    },
  );

  testWidgets('confirm / cancel / locate bus events', (tester) async {
    final confirmBus = AppEventBus.create();
    final latestMove = _captureBusEvent<NavalMoveFleetRequestedEvent>(
      confirmBus,
    );
    await openDialog(tester, bus: confirmBus);
    await tester.tap(find.text('Cross NW Sea links to New World'));
    await tester.pump();
    await tester.tap(find.text('Confirm'));
    await tester.pump();
    final captured = latestMove();
    expect(captured, isNotNull);
    expect(captured!.humanPlayerId, humanId);
    expect(captured.moveOrder.fleetId, 'f_move');
    expect(captured.moveOrder.destinationSeaZoneId, crossRegionWarpSea);
    expect(captured.moveOrder.destinationPortProvinceId, isNull);
    expect(find.text('Move fleet — f_move'), findsNothing);

    final cancelBus = AppEventBus.create();
    final cancelled = _captureBusEvent<NavalMoveFleetRequestedEvent>(cancelBus);
    await openDialog(tester, bus: cancelBus);
    await tester.tap(find.text('Cancel'));
    await tester.pump();
    expect(cancelled(), isNull);
    expect(find.text('Move fleet — f_move'), findsNothing);

    final locateBus = AppEventBus.create();
    final latestLocate = _captureBusEvent<LocateMapTileEvent>(locateBus);
    await openDialog(tester, bus: locateBus);
    final locateButtons = find.descendant(
      of: find.byType(MoveFleetDialog),
      matching: find.byTooltip('Locate on map'),
    );
    expect(locateButtons, findsNWidgets(3));
    await tester.tap(locateButtons.first);
    await tester.pump();
    final locate = latestLocate();
    expect(locate, isNotNull);
    expect(locate!.regionId, 'newWorld');
    expect(locate.tileKey, 'newWorld|port_nw|0|0');
  });
  testWidgets(
    'in-port fleet with combined topology shows Sea zones (issue #1446)',
    (WidgetTester tester) async {
      const ow = 'oldWorld';
      const localCap = 'port_cap';
      final fullCap = '$ow|$localCap';
      await openDialog(
        tester,
        bus: AppEventBus.create(),
        topology: MapTopology(
          nodes: [
            TopologyNode(
              id: fullCap,
              regionId: ow,
              type: TopologyNodeType.province,
            ),
            _seaNode('$ow|sea1', ow),
            _seaNode('$ow|sea2', ow),
          ],
          edges: [
            TopologyEdge(id1: fullCap, id2: '$ow|sea1'),
            TopologyEdge(id1: fullCap, id2: '$ow|sea2'),
            TopologyEdge(id1: '$ow|sea1', id2: '$ow|sea2'),
          ],
        ),
        game: Game(
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
        ),
        fleet: Fleet(
          id: 'f_in_port',
          ownerId: humanId,
          regionId: ow,
          inPortAtProvinceId: fullCap,
          ships: const [ShipInstance(id: 'ship_1', typeId: 'carrack')],
        ),
      );

      expect(
        find.text('No adjacent sea zones (check map topology).'),
        findsNothing,
      );
      expect(find.text('SEA ZONES'), findsOneWidget);
      expect(find.text('Second Sea'), findsOneWidget);
    },
  );

  testWidgets('sea zone section lists S–S neighbors only, not provinces', (
    WidgetTester tester,
  ) async {
    const mixHumanId = 'gp_mix';
    const seaA = 'sea_a';
    const seaB = 'sea_b';
    const coastProv = 'coast_p';
    await openDialog(
      tester,
      bus: AppEventBus.create(),
      playerId: mixHumanId,
      game: Game(
        id: 'g_mix',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              const Province(
                id: 'oldWorld|inland_cap',
                regionId: 'oldWorld',
                ownerId: mixHumanId,
                displayName: 'Inland Capital',
              ),
              Province(
                id: 'oldWorld|$coastProv',
                regionId: 'oldWorld',
                ownerId: mixHumanId,
                displayName: 'Coastal Province',
              ),
            ],
          ),
          newWorld: const RegionData(),
          seaZoneDisplayNameById: {
            'oldWorld|$seaA': 'Alpha Sea',
            'oldWorld|$seaB': 'Beta Sea',
          },
        ),
        players: const [
          Player(
            id: mixHumanId,
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
      ),
      topology: MapTopology(
        nodes: [
          _seaNode(seaA, 'oldWorld'),
          _seaNode(seaB, 'oldWorld'),
          const TopologyNode(
            id: coastProv,
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [
          TopologyEdge(id1: seaA, id2: coastProv),
          TopologyEdge(id1: seaA, id2: seaB),
        ],
      ),
      fleet: Fleet(
        id: 'f_mix',
        ownerId: mixHumanId,
        regionId: 'oldWorld',
        seaZoneId: seaA,
        ships: const [ShipInstance(id: 's1', typeId: 'carrack')],
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SEA ZONES'), findsOneWidget);
    expect(find.text('PROVINCES (DOCK)'), findsOneWidget);
    expect(find.text('Coastal Province'), findsOneWidget);
    expect(find.textContaining('Beta Sea'), findsOneWidget);
    expect(find.textContaining('Alpha Sea'), findsNothing);
  });
}
