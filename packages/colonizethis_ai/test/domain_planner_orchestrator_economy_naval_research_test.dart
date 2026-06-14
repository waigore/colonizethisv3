import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planner_test_fake_api.dart';
import 'planner_test_helpers.dart';

void main() {
  group('runDomainPlanners', () {
    test('uses economy and naval planners when candidates exist', () {
      // Fake suggestion API to hit economy (work/build), naval move/mission, and research
      // branches without depending on full game logic.
      final fakeApi = FakeOrderSuggestionAPIForDomainPlannerTests(
        work: const [
          WorkOrder(
            unitId: 'u1',
            target: kWorkTargetExplore,
            targetTileKey: 'oldWorld|p1|0|0',
          ),
        ],
        build: const [
          BuildUnitOrder(
            unitType: 'inf',
            isMilitary: false,
            spawnProvinceId: 'oldWorld|p1',
          ),
        ],
        move: const [
          MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|p2|0|0'),
        ],
        research: const [
          ResearchOrder(
            slotIndex: 0,
            techId: kTechIdRoadConstruction,
            funding: ResearchFundingLevel.low,
          ),
        ],
        navalMove: const [
          NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 's2'),
        ],
        navalMission: const [
          NavalMissionOrder(fleetId: 'f1', mission: 'patrol'),
        ],
      );

      final game = Game(
        id: 'g3',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: const RegionData(),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'Leader',
            isHuman: false,
            // Treasury funds the treasury-aware research planner (Refs #3472).
            treasury: 1000,
            leaderKey:
                'victoria', // economy and military weights both high enough
          ),
        ],
      );
      const topology = MapTopology(nodes: [], edges: []);
      // Minimal view; domain_planners only looks at playerId for appending orders.
      final view = PlayerView(
        playerId: 'gp1',
        player: game.players.single,
        ownUnitsById: const {},
        provincesById: const {},
        visibilityByTile: const {},
        prospectedTiles: const {},
        diplomacyByOtherId: const {},
      );
      final orders = runDomainPlannersInTest(
        game: game,
        topology: topology,
        view: view,
        turnSeed: 123,
        primaryGoal: StrategicGoal.expand,
        suggestionAPI: fakeApi,
      );

      // Economy: at least one work and build order should be appended.
      expect(
        orders.workOrdersByPlayerId['gp1']?.length ?? 0,
        greaterThanOrEqualTo(1),
      );
      expect(
        orders.buildUnitOrdersByPlayerId['gp1']?.length ?? 0,
        greaterThanOrEqualTo(1),
      );
      // Research: one research order.
      expect(
        orders.researchOrdersByPlayerId['gp1']?.length ?? 0,
        greaterThanOrEqualTo(1),
      );
      // Naval: move + mission orders appended.
      expect(
        orders.navalMoveOrdersByPlayerId['gp1']?.length ?? 0,
        greaterThanOrEqualTo(1),
      );
      expect(
        orders.navalMissionOrdersByPlayerId['gp1']?.length ?? 0,
        greaterThanOrEqualTo(1),
      );
    });
  });
}
