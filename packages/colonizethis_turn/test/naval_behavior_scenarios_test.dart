import 'package:colonizethis_logic/colonizethis_logic.dart' show NavalCombatResultEvent;
import 'package:colonizethis_turn/src/turn/naval_resolution.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

Game _baseGame({
  required List<Fleet> fleets,
  required List<DiplomacyRelation> relations,
  int globalGameSeed = 42,
}) {
  return Game(
    id: 'g_naval',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
      fleets: fleets,
    ),
    players: const [
      Player(id: 'p1', displayName: 'A', isHuman: true),
      Player(id: 'p2', displayName: 'B', isHuman: true),
      Player(id: 'p3', displayName: 'C', isHuman: true),
    ],
    diplomacyRelations: relations,
    globalGameSeed: globalGameSeed,
  );
}

void main() {
  group('naval behavior scenarios', () {
    test(
        'scenario: sole mover is side1 (attacker) in naval event when opponent is not Patrol/Blockade '
        '(no interception roll; battle always proceeds)', () {
      NavalCombatResultEvent? navalEvent;
      final game = _baseGame(
        fleets: [
          Fleet(
            id: 'f_mover',
            ownerId: 'p1',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: const ['carrack', 'carrack'],
            mission: FleetMission.none,
          ),
          Fleet(
            id: 'f_other',
            ownerId: 'p2',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: const ['fluyte', 'fluyte'],
            mission: FleetMission.defend,
          ),
        ],
        relations: [
          DiplomacyRelation(
            factionId1: 'p1',
            factionId2: 'p2',
            state: RelationState.atWar,
          ),
        ],
      );

      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [],
      );

      runNavalInterceptionCombatPhase(
        game,
        topology,
        {
          'p1': [
            NavalMoveOrder(fleetId: 'f_mover', destinationSeaZoneId: 'sea1'),
          ],
        },
        onGameEvent: (e) {
          if (e is NavalCombatResultEvent) navalEvent = e;
        },
      );

      expect(navalEvent, isNotNull);
      final ev = navalEvent!;
      expect(ev.side1OwnerId, 'p1');
      expect(ev.side2OwnerId, 'p2');
    });

    test('scenario: post-battle fleets preserve mission', () {
      final game = _baseGame(
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'p1',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: const ['carrack', 'carrack'],
            mission: FleetMission.patrol,
          ),
          Fleet(
            id: 'f2',
            ownerId: 'p2',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: const ['fluyte', 'fluyte'],
            mission: FleetMission.blockade,
          ),
        ],
        relations: [
          DiplomacyRelation(
            factionId1: 'p1',
            factionId2: 'p2',
            state: RelationState.atWar,
          ),
        ],
      );

      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [],
      );

      final resolved = runNavalInterceptionCombatPhase(
        game,
        topology,
        const {},
      );

      final p1Fleets = resolved.worldState.fleets.where((f) => f.ownerId == 'p1').toList();
      final p2Fleets = resolved.worldState.fleets.where((f) => f.ownerId == 'p2').toList();
      if (p1Fleets.isNotEmpty) {
        expect(p1Fleets.first.mission, FleetMission.patrol);
      }
      if (p2Fleets.isNotEmpty) {
        expect(p2Fleets.first.mission, FleetMission.blockade);
      }
    });

    test('scenario: hostile adjacent sea zone is not used for retreat', () {
      final game = _baseGame(
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'p1',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: const ['carrack', 'carrack'],
            mission: FleetMission.patrol,
          ),
          Fleet(
            id: 'f2',
            ownerId: 'p2',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: const ['fluyte', 'fluyte'],
            mission: FleetMission.blockade,
          ),
          Fleet(
            id: 'f3',
            ownerId: 'p3',
            seaZoneId: 'sea2',
            regionId: 'oldWorld',
            shipTypeIds: const ['carrack'],
            mission: FleetMission.patrol,
          ),
        ],
        relations: [
          DiplomacyRelation(
            factionId1: 'p1',
            factionId2: 'p2',
            state: RelationState.atWar,
          ),
          DiplomacyRelation(
            factionId1: 'p1',
            factionId2: 'p3',
            state: RelationState.atWar,
          ),
          DiplomacyRelation(
            factionId1: 'p2',
            factionId2: 'p3',
            state: RelationState.atWar,
          ),
        ],
      );

      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
          TopologyNode(id: 'sea2', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
          TopologyNode(id: 'sea3', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [
          TopologyEdge(id1: 'sea1', id2: 'sea2'),
          TopologyEdge(id1: 'sea1', id2: 'sea3'),
        ],
      );

      final resolved = runNavalInterceptionCombatPhase(
        game,
        topology,
        const {},
      );

      final retreatingOwnersInSea2 = resolved.worldState.fleets.where(
        (f) => (f.ownerId == 'p1' || f.ownerId == 'p2') && f.seaZoneId == 'sea2',
      );
      expect(retreatingOwnersInSea2, isEmpty);
    });

    test('scenario: no legal retreat destination keeps survivors in battle zone', () {
      final game = _baseGame(
        fleets: [
          Fleet(
            id: 'f1',
            ownerId: 'p1',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: const ['carrack', 'carrack'],
            mission: FleetMission.patrol,
          ),
          Fleet(
            id: 'f2',
            ownerId: 'p2',
            seaZoneId: 'sea1',
            regionId: 'oldWorld',
            shipTypeIds: const ['fluyte', 'fluyte'],
            mission: FleetMission.blockade,
          ),
          Fleet(
            id: 'f3',
            ownerId: 'p3',
            seaZoneId: 'sea2',
            regionId: 'oldWorld',
            shipTypeIds: const ['carrack'],
            mission: FleetMission.patrol,
          ),
        ],
        relations: [
          DiplomacyRelation(
            factionId1: 'p1',
            factionId2: 'p2',
            state: RelationState.atWar,
          ),
          DiplomacyRelation(
            factionId1: 'p1',
            factionId2: 'p3',
            state: RelationState.atWar,
          ),
          DiplomacyRelation(
            factionId1: 'p2',
            factionId2: 'p3',
            state: RelationState.atWar,
          ),
        ],
      );

      const topology = MapTopology(
        nodes: [
          TopologyNode(id: 'sea1', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
          TopologyNode(id: 'sea2', regionId: 'oldWorld', type: TopologyNodeType.seaZone),
        ],
        edges: [
          TopologyEdge(id1: 'sea1', id2: 'sea2'),
        ],
      );

      final resolved = runNavalInterceptionCombatPhase(
        game,
        topology,
        const {},
      );

      final sideFleets = resolved.worldState.fleets.where(
        (f) => f.ownerId == 'p1' || f.ownerId == 'p2',
      );
      for (final fleet in sideFleets) {
        expect(fleet.seaZoneId, 'sea1');
      }
    });
  });
}
