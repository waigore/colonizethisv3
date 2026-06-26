import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/domain_planner_test_fake_api.dart';
import '../support/planner_test_helpers.dart';

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
            leaderKey:
                'victoria', // economy and military weights both high enough
            // Positive treasury so the treasury-aware research planner
            // (Refs #3472) can afford a funding tier for the empty slot.
            treasury: 500,
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
      // Use a tech primary goal so the treasury-aware research planner
      // (Refs #3472) deterministically fills the single empty slot the fake
      // API offers; economy work/build still run via Victoria's high economy
      // weight and naval move/mission are independent of the primary goal.
      final orders = runDomainPlannersInTest(
        game: game,
        topology: topology,
        view: view,
        turnSeed: 123,
        primaryGoal: StrategicGoal.tech,
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
        const fakeApi = FakeOrderSuggestionAPIForDomainPlannerTests(
          work: [],
          build: [],
          move: [],
          research: [],
          navalMove: [],
          navalMission: [],
          diplomatic: const [
            DiplomaticOrder(
              type: DiplomaticOrderType.offerPeace,
              targetFactionId: 'gp2',
            ),
          ],
        );
        final orders = runDomainPlannersInTest(
          game: game,
          topology: topology,
          view: view,
          turnSeed: 456,
          primaryGoal: StrategicGoal.diplomacy,
          suggestionAPI: fakeApi,
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
      const fakeApi = FakeOrderSuggestionAPIForDomainPlannerTests(
        work: [],
        build: [],
        move: [],
        research: [],
        navalMove: [],
        navalMission: [],
        diplomatic: [],
      );
      final orders = runDomainPlannersInTest(
        game: game,
        topology: topology,
        view: view,
        turnSeed: 789,
        primaryGoal: StrategicGoal.diplomacy,
        config: const AIConfig(
          leaderId: 'napoleon',
          personalityId: 'napoleon',
          hiddenAgendaId: 'warmonger',
        ),
        suggestionAPI: fakeApi,
      );

      expect(orders.diplomaticOrdersByPlayerId['gp1'], isNull);
    });

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
        const postQuotaSnapshot = AIWorldSnapshot(
          playerId: 'gp1',
          threats: ThreatSummary(),
          opportunities: OpportunitySummary(),
          conquest: ConquestSummary(
            oldWorldProvincesOwned: kObserverConquestMinOwProvincesPerGp + 2,
          ),
          economy: EconomySummary(),
          relations: {},
        );
        final orders = runDomainPlannersInTest(
          game: game,
          topology: topology,
          view: view,
          snapshot: postQuotaSnapshot,
          turnSeed: 42,
          primaryGoal: StrategicGoal.expand,
          config: const AIConfig(
            leaderId: 'henry',
            personalityId: 'henry',
            hiddenAgendaId: 'peacemaker',
          ),
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
        final orders1 = runDomainPlannersInTest(
          game: game,
          topology: topology,
          turnSeed: 999,
          suggestionAPI: fakeApi,
        );
        final orders2 = runDomainPlannersInTest(
          game: game,
          topology: topology,
          turnSeed: 999,
          suggestionAPI: fakeApi,
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
