import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_test_fake_api.dart';
import 'planner_test_helpers.dart';

void main() {
  group('war declaration relation threshold (peacemaker)', () {
    test(
      'peacemaker scores declareWar 0 when relation above threshold so does not pick it when another candidate exists',
      () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: const RegionData(),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(
              id: 'gp1',
              displayName: 'A',
              isHuman: false,
              leaderKey: 'victoria',
            ),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
            Player(id: 'gp3', displayName: 'C', isHuman: false),
          ],
          diplomacyRelations: [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp2',
              score: 60,
              level: RelationLevel.neutral,
              state: RelationState.atPeace,
            ),
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp3',
              score: 20,
              level: RelationLevel.hostile,
              state: RelationState.atPeace,
            ),
          ],
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, 'gp1');
        const fakeApi = FakeOrderSuggestionAPIForDomainPlannerTests(
          work: [],
          build: [],
          move: [],
          research: [],
          navalMove: [],
          navalMission: [],
          diplomatic: const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp2',
            ),
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp3',
            ),
          ],
        );
        final orders = runDomainPlannersInTest(
          game: game,
          topology: topology,
          view: view,
          turnSeed: 111,
          primaryGoal: StrategicGoal.conquer,
          suggestionAPI: fakeApi,
        );

        final diplo = orders.diplomaticOrdersByPlayerId['gp1'];
        expect(diplo, isNotNull);
        expect(
          diplo!.single.targetFactionId,
          'gp3',
          reason:
              'peacemaker max relation 30; gp2 has 60 so score 0; only gp3 has positive score',
        );
      },
    );
  });
}
