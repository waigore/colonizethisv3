import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/planner_test_helpers.dart';

void main() {
  group('move planner diplomacy filter', () {
    test('full-AI move planner scores civilian moves; at-peace target not pre-filtered',
        () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'p1', regionId: ow, ownerId: 'gp1'),
              Province(id: 'p2', regionId: ow, ownerId: 'gp2'),
              Province(id: 'p3', regionId: ow, ownerId: 'gp3'),
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
          ),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
          Player(id: 'gp3', displayName: 'C', isHuman: false),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 0,
            state: RelationState.atWar,
          ),
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp3',
            score: 50,
            state: RelationState.atPeace,
          ),
        ],
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, 'gp1');
      const fakeApi = FakeOrderSuggestionAPIForDomainPlannerTests(
        work: [],
        build: [],
        move: [
          MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|p2|0|0'),
          MoveOrder(unitId: 'u2', destinationTileKey: 'oldWorld|p3|0|0'),
        ],
        research: [],
        navalMove: [],
        navalMission: [],
        diplomatic: [],
      );
      final orders = runDomainPlannersInTest(
        game: game,
        topology: topology,
        view: view,
        turnSeed: 444,
        primaryGoal: StrategicGoal.conquer,
        config: const AIConfig(
          leaderId: 'napoleon',
          personalityId: 'napoleon',
          hiddenAgendaId: 'warmonger',
        ),
        suggestionAPI: fakeApi,
      );

      final moves = orders.moveOrdersByPlayerId['gp1'] ?? [];
      expect(moves.length, 1);
      // At-war destination is heavily weighted over at-peace (see kMovePreferEnemyTerritoryBonus).
      expect(moves.single.destinationTileKey, 'oldWorld|p2|0|0');
    });
  });
}
