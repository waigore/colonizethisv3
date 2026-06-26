import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/planner_test_helpers.dart';

void main() {
  group('runDomainPlanners conquest pairing', () {
    test('after declareWar on minor emits army move into minor province', () {
      const declareMinor = DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: 'minor1',
      );
      const invasionMove = ArmyMoveOrder(
        armyId: 'field_a',
        destinationProvinceId: 'oldWorld|p_minor',
      );
      final fakeApi = FakeOrderSuggestionAPIForDomainPlannerTests(
        work: const [],
        build: const [],
        move: const [],
        research: const [],
        navalMove: const [],
        navalMission: const [],
        diplomatic: [declareMinor],
        armyMove: [invasionMove],
      );
      final game = Game(
        id: 'g_conquest_pair',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|p_gp',
                regionId: 'oldWorld',
                ownerId: 'gp1',
              ),
              Province(
                id: 'oldWorld|p_minor',
                regionId: 'oldWorld',
                ownerId: 'minor1',
              ),
            ],
            units: [],
          ),
          newWorld: RegionData(provinces: [], units: []),
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'Leader',
            isHuman: false,
            leaderKey: 'napoleon',
          ),
        ],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor 1'),
        ],
      );
      const topology = MapTopology(
        nodes: [
          TopologyNode(
            id: 'p_gp',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p_minor',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: [TopologyEdge(id1: 'p_gp', id2: 'p_minor')],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final orders = runDomainPlannersInTest(
        game: game,
        topology: topology,
        view: view,
        turnSeed: 99,
        primaryGoal: StrategicGoal.conquer,
        config: AIConfig(
        leaderId: 'napoleon',
        personalityId: 'napoleon',
        hiddenAgendaId: 'warmonger',
      ),
        suggestionAPI: fakeApi,
      );

      final diplo = orders.diplomaticOrdersByPlayerId['gp1'] ?? const [];
      expect(
        diplo.any(
          (o) =>
              o.type == DiplomaticOrderType.declareWar &&
              o.targetFactionId == 'minor1',
        ),
        isTrue,
      );
      expect(
        orders.armyMoveOrdersByPlayerId['gp1']?.single.destinationProvinceId,
        'oldWorld|p_minor',
      );
    });
  });
}
