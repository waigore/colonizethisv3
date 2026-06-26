import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../domain_planner_test_fake_api.dart';
import '../planner_test_helpers.dart';

void main() {
  group('war declaration target scoring (warmonger)', () {
    test('warmonger gets bonus for weakNeighbors target', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              for (var i = 0; i < 8; i++)
                Province(
                  id: 'oldWorld|p1_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
              for (var i = 0; i < 3; i++)
                Province(
                  id: 'oldWorld|p2_$i',
                  regionId: 'oldWorld',
                  ownerId: 'gp2',
                ),
              Province(id: 'oldWorld|p3', regionId: 'oldWorld', ownerId: 'gp3'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            leaderKey: 'napoleon',
            militaryLevel: 3,
          ),
          Player(id: 'gp2', displayName: 'B', isHuman: false, militaryLevel: 1),
          Player(id: 'gp3', displayName: 'C', isHuman: false, militaryLevel: 5),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 50,
            state: RelationState.atPeace,
          ),
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp3',
            score: 50,
            state: RelationState.atPeace,
          ),
        ],
      );
      final topology = MapTopology(
        nodes: [
          for (var i = 0; i < 8; i++)
            TopologyNode(
              id: 'p1_$i',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          for (var i = 0; i < 3; i++)
            TopologyNode(
              id: 'p2_$i',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          const TopologyNode(
            id: 'p3',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [
          const TopologyEdge(id1: 'p1_0', id2: 'p2_0'),
          const TopologyEdge(id1: 'p1_0', id2: 'p3'),
        ],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final snapshot = AIWorldSnapshot.fromPlayerView(view, topology: topology);
      expect(
        snapshot.opportunities.weakNeighbors,
        contains('gp2'),
        reason: 'gp2 owns p2 adjacent to gp1 p1',
      );
      expect(snapshot.opportunities.weakNeighbors, contains('gp3'));
      const config = AIConfig(
        leaderId: 'napoleon',
        personalityId: 'napoleon',
        hiddenAgendaId: 'warmonger',
      );
      const fakeApi = FakeOrderSuggestionAPIForDomainPlannerTests(
        work: [],
        build: [],
        move: [],
        research: [],
        navalMove: [],
        navalMission: [],
        diplomatic: [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'gp2',
          ),
        ],
      );
      final orders = runDomainPlannersInTest(
        game: game,
        topology: topology,
        snapshot: snapshot,
        config: config,
        primaryGoal: StrategicGoal.conquer,
        turnSeed: 222,
        suggestionAPI: fakeApi,
      );

      final diplo = orders.diplomaticOrdersByPlayerId['gp1'];
      expect(diplo, isNotNull);
      expect(diplo!.single.type, DiplomaticOrderType.declareWar);
      expect(
        diplo.single.targetFactionId,
        'gp2',
        reason:
            'only candidate is gp2 (weak neighbor); warmonger applies +30 bonus',
      );
    });
  });
}
