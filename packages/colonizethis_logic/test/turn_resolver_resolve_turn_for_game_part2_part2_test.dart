import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('resolveTurnForGame', () {
    test(
      'validateOrdersAndResolveTurn filters invalid order and applies only valid move',
      () {
        final topology = MapTopology(
          nodes: [
            const TopologyNode(
              id: 'P1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
            const TopologyNode(
              id: 'P2',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: [const TopologyEdge(id1: 'P1', id2: 'P2')],
        );
        const ow = 'oldWorld';
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
                Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: kUnitTypeBuilder,
                  ownerId: 'p1',
                  locationProvinceId: '$ow|P1',
                ),
              ],
            ),
            newWorld: const RegionData(),
            playerVisibilityByTile: const {
              'p1': {
                'oldWorld|P1|0|0': 'fullyVisible',
                'oldWorld|P2|0|0': 'fullyVisible',
              },
            },
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        );
        final orders = Orders(
          moveOrdersByPlayerId: {
            'p1': [
              MoveOrder(unitId: 'u1', destinationTileKey: '$ow|P2|0|0'),
              MoveOrder(unitId: 'u999', destinationTileKey: '$ow|P2|0|0'),
            ],
          },
        );
        final next = requireTurnResolutionComplete(
          validateOrdersAndResolveTurn(
            game: game,
            topology: topology,
            orders: orders,
            extractedByPlayerId: const {},
            defaultAssignments: const [],
          ),
        );
        expect(next.worldState.turnState.turnNumber, 1);
        expect(next.worldState.oldWorld.units.length, 1);
        expect(
          next.worldState.oldWorld.units.single.locationProvinceId,
          '$ow|P2',
        );
      },
    );

    test('movement phase applies naval mission order', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: 'oldWorld',
              shipTypeIds: ['carrack'],
              mission: FleetMission.none,
            ),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
      );
      final orders = Orders(
        navalMissionOrdersByPlayerId: {
          'p1': [
            NavalMissionOrder(fleetId: 'f1', mission: FleetMission.patrol.name),
          ],
        },
      );
      final next = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: topology,
          orders: orders,
          extractedByPlayerId: const {},
          defaultAssignments: const [],
        ),
      );
      expect(next.worldState.fleets.single.mission, FleetMission.patrol);
      expect(next.worldState.turnState.turnNumber, 1);
    });

    test('movement phase applies naval move order to adjacent sea zone', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea2',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: 'oldWorld',
              shipTypeIds: ['carrack'],
            ),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
      );
      final orders = Orders(
        navalMoveOrdersByPlayerId: {
          'p1': [NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2')],
        },
      );
      final next = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: topology,
          orders: orders,
          extractedByPlayerId: const {},
          defaultAssignments: const [],
        ),
      );
      expect(next.worldState.fleets.single.seaZoneId, 'sea2');
      expect(next.worldState.turnState.turnNumber, 1);
    });

    test('dock order moves fleet from sea to port at owned province', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              inPortAtProvinceId: null,
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
      );
      final orders = Orders(
        navalMoveOrdersByPlayerId: {
          'p1': [
            NavalMoveOrder(fleetId: 'f1', destinationPortProvinceId: '$ow|P1'),
          ],
        },
      );
      final next = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: topology,
          orders: orders,
          extractedByPlayerId: const {},
          defaultAssignments: const [],
        ),
      );
      final fleet = next.worldState.fleets.single;
      expect(fleet.isInPort, isTrue);
      expect(fleet.inPortAtProvinceId, '$ow|P1');
      expect(fleet.seaZoneId, isNull);
    });

    test('naval move order undocks fleet from port to adjacent sea zone', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: '$ow|P1', regionId: ow, ownerId: 'p1')],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: null,
              inPortAtProvinceId: '$ow|P1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
      );
      final orders = Orders(
        navalMoveOrdersByPlayerId: {
          'p1': [
            const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea1'),
          ],
        },
      );
      final next = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: topology,
          orders: orders,
          extractedByPlayerId: const {},
          defaultAssignments: const [],
        ),
      );
      final fleet = next.worldState.fleets.single;
      expect(fleet.isAtSea, isTrue);
      expect(fleet.seaZoneId, 'sea1');
      expect(fleet.inPortAtProvinceId, isNull);
    });

    test('naval move order targeting home fleet does not move it', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea2',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'fleet_p1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: 'oldWorld',
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
      );
      final orders = Orders(
        navalMoveOrdersByPlayerId: {
          'p1': [
            const NavalMoveOrder(
              fleetId: 'fleet_p1',
              destinationSeaZoneId: 'sea2',
            ),
          ],
        },
      );

      final next = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: topology,
          orders: orders,
          extractedByPlayerId: const {},
          defaultAssignments: const [],
        ),
      );
      expect(next.worldState.fleets.single.seaZoneId, 'sea1');
      expect(next.worldState.turnState.turnNumber, 1);
    });

    test('dock at capital merges sea-going fleet into home fleet and reveals port tiles',
        () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
      );
      const tileKey = '$ow|P1|0|0';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            ow: {'$ow|P1': [tileKey]},
          },
          playerVisibilityByTile: {
            'p1': {tileKey: 'fogged'},
          },
          fleets: [
            Fleet(
              id: 'fleet_p1',
              ownerId: 'p1',
              seaZoneId: null,
              inPortAtProvinceId: '$ow|P1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
            Fleet(
              id: 'f2',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: ow,
              shipTypeIds: const ['frigate'],
            ),
          ],
        ),
        players: const [
          Player(
            id: 'p1',
            displayName: 'A',
            isHuman: true,
            capitalProvinceId: '$ow|P1',
          ),
        ],
      );
      final orders = Orders(
        navalMoveOrdersByPlayerId: {
          'p1': [
            NavalMoveOrder(fleetId: 'f2', destinationPortProvinceId: '$ow|P1'),
          ],
        },
      );
      final next = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: topology,
          orders: orders,
          extractedByPlayerId: const {},
          defaultAssignments: const [],
        ),
      );
      expect(next.worldState.fleets.length, 1);
      final home = next.worldState.fleets.single;
      expect(home.id, 'fleet_p1');
      expect(home.shipTypeIds.length, 2);
      expect(home.isInPort, isTrue);
      expect(
        next.worldState.playerVisibilityByTile['p1']?[tileKey],
        'fullyVisible',
      );
    });

    test('naval move clears mission on fleet', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea2',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: 'oldWorld',
              shipTypeIds: const ['carrack'],
              mission: FleetMission.patrol,
            ),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
      );
      final orders = Orders(
        navalMoveOrdersByPlayerId: {
          'p1': [
            const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2'),
          ],
        },
      );
      final next = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: topology,
          orders: orders,
          extractedByPlayerId: const {},
          defaultAssignments: const [],
        ),
      );
      expect(next.worldState.fleets.single.mission, FleetMission.none);
    });

    test('naval mission order skipped when naval move targets same fleet', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
          TopologyNode(
            id: 'sea2',
            regionId: 'oldWorld',
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: 'oldWorld',
              shipTypeIds: const ['carrack'],
              mission: FleetMission.none,
            ),
          ],
        ),
        players: const [Player(id: 'p1', displayName: 'A', isHuman: true)],
      );
      final orders = Orders(
        navalMoveOrdersByPlayerId: {
          'p1': [
            const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2'),
          ],
        },
        navalMissionOrdersByPlayerId: {
          'p1': [
            NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
          ],
        },
      );
      final next = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: topology,
          orders: orders,
          extractedByPlayerId: const {},
          defaultAssignments: const [],
        ),
      );
      expect(next.worldState.fleets.single.seaZoneId, 'sea2');
      expect(next.worldState.fleets.single.mission, FleetMission.none);
    });
  });
}
