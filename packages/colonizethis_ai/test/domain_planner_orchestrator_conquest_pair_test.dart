import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_test_fake_api.dart';

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
          oldWorld: RegionData(provinces: [], units: []),
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
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = PlayerView(
        playerId: 'gp1',
        player: game.players.single,
        ownUnitsById: const {},
        provincesById: const {},
        visibilityByTile: const {},
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      final snapshot = AIWorldSnapshot.fromPlayerView(view);
      const config = AIConfig(
        leaderId: 'napoleon',
        personalityId: 'napoleon',
        hiddenAgendaId: 'warmonger',
      );
      final seeds = AISeedBundle.fromTurnSeed(99);
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
        primaryGoal: StrategicGoal.conquer,
        seeds: seeds,
        suggestionAPI: fakeApi,
        economyPlan: economyPlan,
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
