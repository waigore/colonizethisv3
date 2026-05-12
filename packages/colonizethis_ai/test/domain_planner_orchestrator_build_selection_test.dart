import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_test_fake_api.dart';

void main() {
  group('runDomainPlanners', () {
    test(
      'with strongCargo and ship candidate picks ship deterministically',
      () {
        const regimentBuild = BuildUnitOrder(
          unitType: 'peasant_levies',
          isMilitary: true,
          spawnProvinceId: 'oldWorld|p1',
        );
        const shipBuild = BuildUnitOrder(
          unitType: 'fluyte',
          isMilitary: false,
          spawnProvinceId: 'oldWorld|p1',
        );
        const fakeApi = FakeOrderSuggestionAPIForDomainPlannerTests(
          work: [],
          build: [regimentBuild, shipBuild],
          move: [],
          research: [],
          navalMove: [],
          navalMission: [],
          diplomatic: [],
        );
        const economyPlanStrongCargo = EconomyPlan(
          productionAssignments: [],
          cargoPreference: CargoPreference.strongCargo,
        );
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
              leaderKey: 'henry',
            ),
          ],
        );
        const topology = MapTopology(nodes: [], edges: []);
        final view = buildPlayerView(game, topology, 'gp1');
        final snapshot = AIWorldSnapshot.fromPlayerView(view);
        const config = AIConfig(
          leaderId: 'henry',
          personalityId: 'henry',
          hiddenAgendaId: 'peacemaker',
        );
        final seeds = AISeedBundle.fromTurnSeed(42);

        final orders = runDomainPlanners(
          game: game,
          topology: topology,
          nationId: 'gp1',
          view: view,
          snapshot: snapshot,
          config: config,
          primaryGoal: StrategicGoal.expand,
          seeds: seeds,
          suggestionAPI: fakeApi,
          economyPlan: economyPlanStrongCargo,
        );

        final builds = orders.buildUnitOrdersByPlayerId['gp1'] ?? [];
        expect(builds.length, 1);
        expect(
          builds.single.unitType,
          'fluyte',
          reason: 'strongCargo should favour cargo ship over regiment',
        );
      },
    );

    test(
      'build selection is deterministic for same seed and cargoPreference none',
      () {
        const regimentBuild = BuildUnitOrder(
          unitType: 'peasant_levies',
          isMilitary: true,
          spawnProvinceId: 'oldWorld|p1',
        );
        const shipBuild = BuildUnitOrder(
          unitType: 'fluyte',
          isMilitary: false,
          spawnProvinceId: 'oldWorld|p1',
        );
        const fakeApi = FakeOrderSuggestionAPIForDomainPlannerTests(
          work: [],
          build: [regimentBuild, shipBuild],
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
        final seeds = AISeedBundle.fromTurnSeed(999);

        final orders1 = runDomainPlanners(
          game: game,
          topology: topology,
          nationId: 'gp1',
          view: view,
          snapshot: snapshot,
          config: config,
          primaryGoal: StrategicGoal.expand,
          seeds: seeds,
          suggestionAPI: fakeApi,
          economyPlan: economyPlan,
        );
        final orders2 = runDomainPlanners(
          game: game,
          topology: topology,
          nationId: 'gp1',
          view: view,
          snapshot: snapshot,
          config: config,
          primaryGoal: StrategicGoal.expand,
          seeds: seeds,
          suggestionAPI: fakeApi,
          economyPlan: economyPlan,
        );

        final build1 =
            orders1.buildUnitOrdersByPlayerId['gp1']?.single.unitType;
        final build2 =
            orders2.buildUnitOrdersByPlayerId['gp1']?.single.unitType;
        expect(
          build1,
          build2,
          reason: 'same seed and economyPlan should yield same build choice',
        );
      },
    );
  });
}
