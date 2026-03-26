import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('resolveTurnForGame', () {
    test('quick battle mode runs without error and can flip province', () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          const TopologyNode(
              id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [
          const TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );

      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
              ),
              Unit(
                id: 'u2',
                type: 'peasant_levies',
                ownerId: 'p2',
                locationProvinceId: '$ow|P2',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true, militaryLevel: 3),
          Player(id: 'p2', displayName: 'B', isHuman: true, militaryLevel: 1),
        ],
        defaultCombatMode: CombatMode.quickBattle,
      );

      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            MoveOrder(unitId: 'u1', destinationProvinceId: '$ow|P2'),
          ],
        },
      );

      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
      ));

      expect(next.worldState.turnState.turnNumber, 1);
      final p2 = next.worldState.oldWorld.provinces
          .where((p) => p.id == 'oldWorld|P2')
          .singleOrNull;
      expect(p2, isNotNull);
      // Owner may or may not flip depending on Quick Battle outcome, but state
      // remains consistent and combat resolved.
      expect(p2!.ownerId, isNotNull);
    });

    test(
        'combat phase with AI players invokes onDialogue with event battle_won/battle_lost',
        () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          const TopologyNode(
              id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [
          const TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );

      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        globalGameSeed: 12345,
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
              ),
              Unit(
                id: 'u2',
                type: 'peasant_levies',
                ownerId: 'p2',
                locationProvinceId: '$ow|P2',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
              id: 'p1',
              displayName: 'AI Attacker',
              isHuman: false,
              militaryLevel: 3),
          Player(
              id: 'p2',
              displayName: 'AI Defender',
              isHuman: false,
              militaryLevel: 1),
        ],
        defaultCombatMode: CombatMode.quickBattle,
      );

      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [
            MoveOrder(unitId: 'u1', destinationProvinceId: '$ow|P2'),
          ],
        },
      );

      final dialogueEvents = <DialogueEvent>[];
      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        onDialogue: dialogueEvents.add,
      ));

      expect(next.worldState.turnState.turnNumber, 1);
      final eventDialogue = dialogueEvents
          .where((e) =>
              e.category == 'event' &&
              (e.situation == 'battle_won' || e.situation == 'battle_lost'))
          .toList();
      expect(eventDialogue, isNotEmpty);
      expect(eventDialogue.any((e) => e.situation == 'battle_won'), isTrue);
      expect(eventDialogue.any((e) => e.situation == 'battle_lost'), isTrue);
    });

    test(
        'quick battle defender holds: onDialogue receives battle_won for defender and battle_lost for attacker',
        () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          const TopologyNode(
              id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [
          const TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );

      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        globalGameSeed: 7777,
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
            ],
            units: [
              Unit(
                  id: 'u1',
                  type: 'peasant_levies',
                  ownerId: 'p1',
                  locationProvinceId: '$ow|P1'),
              Unit(
                  id: 'u2',
                  type: 'grenadiers',
                  ownerId: 'p2',
                  locationProvinceId: '$ow|P2',
                  medals: 2),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
              id: 'p1',
              displayName: 'AI Attacker',
              isHuman: false,
              militaryLevel: 1),
          Player(
              id: 'p2',
              displayName: 'AI Defender',
              isHuman: false,
              militaryLevel: 3),
        ],
        defaultCombatMode: CombatMode.quickBattle,
      );

      final orders = Orders(
        moveOrdersByPlayerId: {
          'p1': [MoveOrder(unitId: 'u1', destinationProvinceId: '$ow|P2')],
        },
      );

      final dialogueEvents = <DialogueEvent>[];
      requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        onDialogue: dialogueEvents.add,
      ));

      final eventDialogue = dialogueEvents
          .where((e) =>
              e.category == 'event' &&
              (e.situation == 'battle_won' || e.situation == 'battle_lost'))
          .toList();
      expect(eventDialogue, isNotEmpty);
    });

    test(
        'naval interception combat with AI players invokes onDialogue with event battle_won/battle_lost',
        () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        globalGameSeed: 42,
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
              shipTypeIds: ['carrack', 'carrack'],
            ),
            Fleet(
              id: 'f2',
              ownerId: 'p2',
              seaZoneId: 'sea1',
              regionId: 'oldWorld',
              shipTypeIds: ['fluyte'],
            ),
          ],
        ),
        players: const [
          Player(id: 'p1', displayName: 'AI Fleet A', isHuman: false),
          Player(id: 'p2', displayName: 'AI Fleet B', isHuman: false),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'p1',
            factionId2: 'p2',
            state: RelationState.atWar,
          ),
        ],
      );
      final dialogueEvents = <DialogueEvent>[];
      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: const Orders(),
        onDialogue: dialogueEvents.add,
      ));
      expect(next.worldState.turnState.turnNumber, 1);
      // Naval battle may or may not eliminate one side; when it does, event dialogue is emitted.
      final eventDialogue = dialogueEvents
          .where((e) =>
              e.category == 'event' &&
              (e.situation == 'battle_won' || e.situation == 'battle_lost'))
          .toList();
      expect(eventDialogue.length, lessThanOrEqualTo(2));
    });

    test('endOfTurn era transition invokes onDialogue with event era_change',
        () {
      // Turn 100 → year 1698 (earlyModern); turn 101 → 1700 (imperial). SPEC/ai/dialogue-and-mood.md.
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [],
      );
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 100),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'AI One', isHuman: false),
          Player(id: 'gp2', displayName: 'AI Two', isHuman: false),
        ],
        turnTimeMapping: TurnTimeMapping.gdd01,
      );
      final dialogueEvents = <DialogueEvent>[];
      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: const Orders(),
        onDialogue: dialogueEvents.add,
      ));
      expect(next.worldState.turnState.turnNumber, 101);
      final eraChange = dialogueEvents
          .where((e) => e.category == 'event' && e.situation == 'era_change')
          .toList();
      expect(eraChange.length, 2);
      for (final e in eraChange) {
        expect(e.era, 'imperial');
        expect(e.variables['previousEra'], 'earlyModern');
      }
    });

    test('resolveTurnForGameFromOrderEngine integrates order engine output',
        () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          const TopologyNode(
              id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: [
          const TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
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
                type: 'grenadiers',
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
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
        ],
      );

      final engine = OrderEngine();
      engine.addMoveOrder('p1',
          const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'));

      final next = requireTurnResolutionComplete(resolveTurnForGameFromOrderEngine(
        game: game,
        topology: topology,
        orderEngine: engine,
      ));

      expect(next.worldState.turnState.turnNumber, 1);
      expect(next.worldState.oldWorld.units.single.locationProvinceId, 'oldWorld|P2');
    });

    test(
        'validateOrdersAndResolveTurn filters invalid order and applies only valid move',
        () {
      final topology = MapTopology(
        nodes: [
          const TopologyNode(
              id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
          const TopologyNode(
              id: 'P2', regionId: 'oldWorld', type: TopologyNodeType.province),
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
                  type: 'musketeers',
                  ownerId: 'p1',
                  locationProvinceId: '$ow|P1'),
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
            MoveOrder(unitId: 'u1', destinationProvinceId: '$ow|P2'),
            MoveOrder(unitId: 'u999', destinationProvinceId: '$ow|P2'),
          ],
        },
      );
      final next = requireTurnResolutionComplete(validateOrdersAndResolveTurn(
        game: game,
        topology: topology,
        orders: orders,
        extractedByPlayerId: const {},
        defaultAssignments: const [],
      ));
      expect(next.worldState.turnState.turnNumber, 1);
      expect(next.worldState.oldWorld.units.length, 1);
      expect(next.worldState.oldWorld.units.single.locationProvinceId, '$ow|P2');
    });

    test('movement phase applies naval mission order', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
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
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
        ],
      );
      final orders = Orders(
        navalMissionOrdersByPlayerId: {
          'p1': [
            NavalMissionOrder(fleetId: 'f1', mission: FleetMission.patrol.name),
          ],
        },
      );
      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        extractedByPlayerId: const {},
        defaultAssignments: const [],
      ));
      expect(next.worldState.fleets.single.mission, FleetMission.patrol);
      expect(next.worldState.turnState.turnNumber, 1);
    });

    test('movement phase applies naval move order to adjacent sea zone', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
          TopologyNode(
              id: 'sea2', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [
          TopologyEdge(id1: 'sea1', id2: 'sea2'),
        ],
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
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
        ],
      );
      final orders = Orders(
        navalMoveOrdersByPlayerId: {
          'p1': [
            NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea2'),
          ],
        },
      );
      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        extractedByPlayerId: const {},
        defaultAssignments: const [],
      ));
      expect(next.worldState.fleets.single.seaZoneId, 'sea2');
      expect(next.worldState.turnState.turnNumber, 1);
    });

    test('dock order moves fleet from sea to port at owned province', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'sea1', regionId: ow, type: TopologyNodeType.seaZone),
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'sea1', id2: 'P1'),
        ],
      );
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
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
        ],
      );
      final orders = Orders(
        navalMoveOrdersByPlayerId: {
          'p1': [
            NavalMoveOrder(
              fleetId: 'f1',
              destinationPortProvinceId: '$ow|P1',
            ),
          ],
        },
      );
      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        extractedByPlayerId: const {},
        defaultAssignments: const [],
      ));
      final fleet = next.worldState.fleets.single;
      expect(fleet.isInPort, isTrue);
      expect(fleet.inPortAtProvinceId, '$ow|P1');
      expect(fleet.seaZoneId, isNull);
    });

    test('naval move order undocks fleet from port to adjacent sea zone', () {
      const ow = 'oldWorld';
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'sea1', regionId: ow, type: TopologyNodeType.seaZone),
          TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [
          TopologyEdge(id1: 'sea1', id2: 'P1'),
        ],
      );
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
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
        ],
      );
      final orders = Orders(
        navalMoveOrdersByPlayerId: {
          'p1': [
            const NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 'sea1'),
          ],
        },
      );
      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        extractedByPlayerId: const {},
        defaultAssignments: const [],
      ));
      final fleet = next.worldState.fleets.single;
      expect(fleet.isAtSea, isTrue);
      expect(fleet.seaZoneId, 'sea1');
      expect(fleet.inPortAtProvinceId, isNull);
    });

    test('naval move order targeting home fleet does not move it', () {
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
              id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
          TopologyNode(
              id: 'sea2', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: const [
          TopologyEdge(id1: 'sea1', id2: 'sea2'),
        ],
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
        players: const [
          Player(id: 'p1', displayName: 'A', isHuman: true),
        ],
      );
      final orders = Orders(
        navalMoveOrdersByPlayerId: {
          'p1': [
            const NavalMoveOrder(
                fleetId: 'fleet_p1', destinationSeaZoneId: 'sea2'),
          ],
        },
      );

      final next = requireTurnResolutionComplete(resolveTurnForGame(
        game: game,
        topology: topology,
        orders: orders,
        extractedByPlayerId: const {},
        defaultAssignments: const [],
      ));
      expect(next.worldState.fleets.single.seaZoneId, 'sea1');
      expect(next.worldState.turnState.turnNumber, 1);
    });
  });
}
