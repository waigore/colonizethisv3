import 'package:colonizethis_ai/src/planning/build_planner.dart';
import 'package:colonizethis_ai/src/planning/goal_manager.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'planner_test_helpers.dart';

void main() {
  group('pickBuildOrder', () {
    test('prefers regiment when behind victory pace and conquer goal', () {
      const candidates = [
        BuildUnitOrder(
          unitType: 'sloop',
          isMilitary: false,
          spawnProvinceId: 'oldWorld|p1',
        ),
        BuildUnitOrder(
          unitType: 'grenadiers',
          isMilitary: true,
          spawnProvinceId: 'oldWorld|p1',
        ),
      ];
      const config = AIConfig(
        leaderId: 'napoleon',
        personalityId: 'napoleon',
        hiddenAgendaId: 'warmonger',
      );
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
      final ctx = buildTestPlannerContext(
        game: game,
        topology: topology,
        config: config,
        primaryGoal: StrategicGoal.conquer,
      );
      final chosen = pickBuildOrder(
        ctx: ctx,
        buildCandidates: candidates,
        cargoPreference: CargoPreference.none,
        provincesToVictory: 20,
        seedOverride: 1,
      );
      expect(chosen?.unitType, 'grenadiers');
    });
  });
}
