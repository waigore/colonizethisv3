import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_test_fake_api.dart';

void main() {
  group('runDomainPlanners', () {
    test('_runArmyMovePlanner applies fake suggestion army move', () {
      final fakeApi = FakeOrderSuggestionAPIForDomainPlannerTests(
        work: const [],
        build: const [],
        move: const [],
        research: const [],
        navalMove: const [],
        navalMission: const [],
        diplomatic: const [],
        armyMove: const [
          ArmyMoveOrder(
            armyId: 'field_a',
            destinationProvinceId: 'oldWorld|p2',
          ),
        ],
      );
      final game = Game(
        id: 'g_army_fake',
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
            leaderKey: 'victoria',
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
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final seeds = AISeedBundle.fromTurnSeed(1);
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

      expect(orders.armyMoveOrdersByPlayerId['gp1']?.single.destinationProvinceId,
          'oldWorld|p2');
    });
  });
}
