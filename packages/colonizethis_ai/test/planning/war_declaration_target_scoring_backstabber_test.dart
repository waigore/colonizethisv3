import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../domain_planner_test_fake_api.dart';
import '../planner_test_helpers.dart';

void main() {
  group('war declaration target scoring (backstabber)', () {
    test(
      'backstabber prefers allied target when it is the only declare-war candidate',
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
              leaderKey: 'napoleon',
            ),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
            Player(id: 'gp3', displayName: 'C', isHuman: false),
          ],
          diplomacyRelations: [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp2',
              score: 80,
              level: RelationLevel.allied,
              state: RelationState.atPeace,
            ),
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp3',
              score: 50,
              level: RelationLevel.neutral,
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
          ],
        );
        final orders = runDomainPlannersInTest(
          game: game,
          topology: topology,
          view: view,
          turnSeed: 333,
          primaryGoal: StrategicGoal.conquer,
          config: const AIConfig(
            leaderId: 'napoleon',
            personalityId: 'napoleon',
            hiddenAgendaId: 'backstabber',
          ),
          suggestionAPI: fakeApi,
        );

        final diplo = orders.diplomaticOrdersByPlayerId['gp1'];
        expect(diplo, isNotNull);
        expect(diplo!.single.type, DiplomaticOrderType.declareWar);
        expect(
          diplo.single.targetFactionId,
          'gp2',
          reason:
              'only candidate is gp2 (allied); backstabber applies +25 bonus',
        );
      },
    );
  });
}
