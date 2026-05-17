import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('resolveTurnForGame', () {
    test(
      'join_home_fleet mission moves ships into home fleet and removes fleet',
      () {
        const ow = 'oldWorld';
        final topology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'sea1',
              regionId: ow,
              type: TopologyNodeType.seaZone,
            ),
            TopologyNode(
              id: 'P1',
              regionId: ow,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'sea1', id2: 'P1')],
        );
        final capitalId = '$ow|P1';
        final homeFleet = Fleet(
          id: 'fleet_p1',
          ownerId: 'p1',
          seaZoneId: null,
          inPortAtProvinceId: capitalId,
          regionId: ow,
          shipTypeIds: const ['carrack'],
        );
        final otherFleet = Fleet(
          id: 'f2',
          ownerId: 'p1',
          seaZoneId: null,
          inPortAtProvinceId: capitalId,
          regionId: ow,
          shipTypeIds: const ['fluyte'],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [Province(id: capitalId, regionId: ow, ownerId: 'p1')],
            ),
            newWorld: const RegionData(),
            fleets: [homeFleet, otherFleet],
          ),
          players: [
            const Player(
              id: 'p1',
              displayName: 'A',
              isHuman: true,
              capitalProvinceId: 'oldWorld|P1',
            ),
          ],
        );
        final orders = Orders(
          navalMissionOrdersByPlayerId: {
            'p1': [
              const NavalMissionOrder(
                fleetId: 'f2',
                mission: 'join_home_fleet',
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

        expect(next.worldState.turnState.turnNumber, 1);
        expect(next.worldState.fleets.length, 1);
        final resultingFleet = next.worldState.fleets.single;
        expect(resultingFleet.id, 'fleet_p1');
        expect(resultingFleet.shipTypeIds, containsAll(['carrack', 'fluyte']));
      },
    );

    test('blockade order not applied when not at war with province owner', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: ow,
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
          Player(id: 'p2', displayName: 'B', isHuman: true),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'p1',
            factionId2: 'p2',
            state: RelationState.atPeace,
          ),
        ],
      );
      final orders = Orders(
        navalMissionOrdersByPlayerId: {
          'p1': [
            NavalMissionOrder(
              fleetId: 'f1',
              mission: FleetMission.blockade.name,
              targetProvinceId: '$ow|P2',
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
      final fleet = next.worldState.fleets.singleWhere((f) => f.id == 'f1');
      expect(fleet.mission, FleetMission.none);
    });

    test('existing blockade cleared when not at war with target owner', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'sea1',
            regionId: ow,
            type: TopologyNodeType.seaZone,
          ),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
            ],
          ),
          newWorld: const RegionData(),
          fleets: [
            Fleet(
              id: 'f1',
              ownerId: 'p1',
              seaZoneId: 'sea1',
              regionId: ow,
              mission: FleetMission.blockade,
              targetProvinceId: '$ow|P2',
              shipTypeIds: const ['carrack'],
            ),
          ],
        ),
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
          Player(id: 'p2', displayName: 'B', isHuman: true),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'p1',
            factionId2: 'p2',
            state: RelationState.atPeace,
          ),
        ],
      );
      final next = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: topology,
          orders: const Orders(),
          extractedByPlayerId: const {},
          defaultAssignments: const [],
        ),
      );
      final fleet = next.worldState.fleets.singleWhere((f) => f.id == 'f1');
      expect(fleet.mission, FleetMission.none);
    });

    test(
      'naval interception phase runs when two at-war fleets in same zone',
      () {
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
                id: 'fleet_p1',
                ownerId: 'p1',
                seaZoneId: 'sea1',
                regionId: 'oldWorld',
                shipTypeIds: ['carrack'],
              ),
              Fleet(
                id: 'fleet_p2',
                ownerId: 'p2',
                seaZoneId: 'sea1',
                regionId: 'oldWorld',
                shipTypeIds: ['fluyte'],
              ),
            ],
          ),
          players: const [
            Player(id: 'p1', displayName: 'A', isHuman: true),
            Player(id: 'p2', displayName: 'B', isHuman: true),
          ],
          diplomacyRelations: [
            DiplomacyRelation(
              factionId1: 'p1',
              factionId2: 'p2',
              state: RelationState.atWar,
            ),
          ],
        );
        final next = requireTurnResolutionComplete(
          resolveTurnForGame(
            game: game,
            topology: topology,
            orders: const Orders(),
            extractedByPlayerId: const {},
            defaultAssignments: const [],
          ),
        );
        expect(next.worldState.turnState.turnNumber, 1);
        expect(next.worldState.fleets, isNotEmpty);
      },
    );

    test('full turn with buildWork applies work order', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
            id: 'P1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [],
      );
      const ow = 'oldWorld';
      const provinceId = 'oldWorld|P1';
      const tileKey = 'oldWorld|P1|0|0';
      final unit = Unit(
        id: 'u1',
        type: kUnitTypeExplorer,
        ownerId: 'p1',
        locationProvinceId: provinceId,
        tileKey: tileKey,
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [Province(id: provinceId, regionId: ow, ownerId: 'p1')],
            units: [unit],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final tileMapByRegion = {
        ow: TileMapResult(
          width: 1,
          height: 1,
          grid: const [
            ['P1'],
          ],
          terrainGrid: [
            [TerrainType.hills],
          ],
        ),
      };
      final orders = Orders(
        workOrdersByPlayerId: {
          'p1': [
            WorkOrder(
              unitId: 'u1',
              target: kWorkTargetProspect,
              targetTileKey: tileKey,
            ),
          ],
        },
      );
      final next = requireTurnResolutionComplete(
        resolveTurnForGame(
          game: game,
          topology: topology,
          orders: orders,
          tileMapByRegion: tileMapByRegion,
          extractedByPlayerId: const {},
          defaultAssignments: const [],
        ),
      );
      expect(next.worldState.turnState.turnNumber, 1);
      expect(next.worldState.playerProspectedTiles['p1'], contains(tileKey));
    });
  });
}
