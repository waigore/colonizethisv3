import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_test_fake_api.dart';

void main() {
  group('runDomainPlanners', () {
    test(
      'appends diplomatic order when goal is diplomacy and API returns candidates',
      () {
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(provinces: [], units: []),
            newWorld: RegionData(provinces: [], units: []),
          ),
          players: const [
            Player(
              id: 'gp1',
              displayName: 'England',
              isHuman: false,
              leaderKey: 'victoria',
            ),
          ],
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, 'gp1');
        final snapshot = AIWorldSnapshot.fromPlayerView(view);
        const config = AIConfig(
          leaderId: 'victoria',
          personalityId: 'victoria',
          hiddenAgendaId: 'peacemaker',
        );
        final seeds = AISeedBundle.fromTurnSeed(456);
        const diploOrder = DiplomaticOrder(
          type: DiplomaticOrderType.offerPeace,
          targetFactionId: 'gp2',
        );
        const fakeApi = FakeOrderSuggestionAPIForDomainPlannerTests(
          work: [],
          build: [],
          move: [],
          research: [],
          navalMove: [],
          navalMission: [],
          diplomatic: [diploOrder],
        );
        const economyPlan = EconomyPlan(
          productionAssignments: [],
          cargoPreference: CargoPreference.none,
        );

        final orders = runDomainPlanners(
          game: game,
          topology: topology,
          nationId: 'gp1',
          view: view,
          snapshot: snapshot,
          config: config,
          primaryGoal: StrategicGoal.diplomacy,
          seeds: seeds,
          suggestionAPI: fakeApi,
          economyPlan: economyPlan,
        );

        expect(orders.diplomaticOrdersByPlayerId['gp1'], isNotNull);
        expect(
          orders.diplomaticOrdersByPlayerId['gp1']!.length,
          greaterThanOrEqualTo(1),
        );
        expect(
          orders.diplomaticOrdersByPlayerId['gp1']!.any(
            (o) =>
                o.type == DiplomaticOrderType.offerPeace &&
                o.targetFactionId == 'gp2',
          ),
          isTrue,
        );
      },
    );

    test('appends no diplomatic order when API returns empty candidates', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(provinces: [], units: []),
          newWorld: RegionData(provinces: [], units: []),
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'France',
            isHuman: false,
            leaderKey: 'napoleon',
          ),
        ],
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, 'gp1');
      final snapshot = AIWorldSnapshot.fromPlayerView(view);
      const config = AIConfig(
        leaderId: 'napoleon',
        personalityId: 'napoleon',
        hiddenAgendaId: 'warmonger',
      );
      final seeds = AISeedBundle.fromTurnSeed(789);
      const fakeApi = FakeOrderSuggestionAPIForDomainPlannerTests(
        work: [],
        build: [],
        move: [],
        research: [],
        navalMove: [],
        navalMission: [],
        diplomatic: [],
      );
      const economyPlan = EconomyPlan(
        productionAssignments: [],
        cargoPreference: CargoPreference.none,
      );

      final orders = runDomainPlanners(
        game: game,
        topology: topology,
        nationId: 'gp1',
        view: view,
        snapshot: snapshot,
        config: config,
        primaryGoal: StrategicGoal.diplomacy,
        seeds: seeds,
        suggestionAPI: fakeApi,
        economyPlan: economyPlan,
      );

      expect(orders.diplomaticOrdersByPlayerId['gp1'], isNull);
    });
  });
}
