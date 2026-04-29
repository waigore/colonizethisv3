import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'domain_planners_test_fake_api.dart';
void main() {
  group('runDomainPlanners', () {
    test('returns empty orders when suggestion API returns no candidates', () {
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
      final seeds = AISeedBundle.fromTurnSeed(999);
      const api = DefaultOrderSuggestionAPI();

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
        primaryGoal: StrategicGoal.expand,
        seeds: seeds,
        suggestionAPI: api,
        economyPlan: economyPlan,
      );

      expect(orders.moveOrdersByPlayerId.isEmpty, isTrue);
      expect(orders.workOrdersByPlayerId.isEmpty, isTrue);
      expect(orders.buildUnitOrdersByPlayerId.isEmpty, isTrue);
      // Research planner may still suggest orders when candidates exist (e.g. default tech).
      expect(orders, isNotNull);
    });

    test('can produce move orders when topology and visibility allow', () {
      final game = Game(
        id: 'g2',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
              Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: null),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'explorer',
                ownerId: 'gp1',
                locationProvinceId: 'oldWorld|p1',
                tileKey: 'oldWorld|p1|0|0',
              ),
            ],
          ),
          newWorld: RegionData(provinces: [], units: []),
          playerVisibilityByTile: const {
            'gp1': {
              'oldWorld|p1|0|0': 'fullyVisible',
              'oldWorld|p2|0|0': 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince: const {
            'oldWorld': {
              'oldWorld|p1': ['oldWorld|p1|0|0'],
              'oldWorld|p2': ['oldWorld|p2|0|0'],
            },
          },
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'GP',
            isHuman: false,
            leaderKey: 'victoria',
          ),
        ],
      );
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'p1',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'p2',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final snapshot = AIWorldSnapshot.fromPlayerView(view);
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final seeds = AISeedBundle.fromTurnSeed(100);
      const api = DefaultOrderSuggestionAPI();

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
        primaryGoal: StrategicGoal.expand,
        seeds: seeds,
        suggestionAPI: api,
        economyPlan: economyPlan,
      );

      expect(orders, isNotNull);
      // Move planner may add moves when weight >= 20 and candidates exist.
      expect(orders.moveOrdersByPlayerId['gp1'] != null, isTrue);
    });

    test('DefaultOrderSuggestionAPI can add army move for non-home army', () {
      const cap = 'oldWorld|cap';
      const p1 = 'oldWorld|p1';
      const nw = 'newWorld|col';
      final game = Game(
        id: 'g_army_dom',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(
                id: cap,
                regionId: 'oldWorld',
                ownerId: 'gp1',
                townTileKey: 'oldWorld|cap|0|0',
              ),
              Province(id: p1, regionId: 'oldWorld', ownerId: 'gp1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: 'gp1',
                locationProvinceId: p1,
                tileKey: 'oldWorld|p1|0|0',
              ),
            ],
          ),
          newWorld: RegionData(
            provinces: [
              Province(id: nw, regionId: 'newWorld', ownerId: 'gp1'),
            ],
          ),
          armies: [
            Army(
              id: homeArmyIdFor('gp1'),
              ownerId: 'gp1',
              regionId: 'oldWorld',
              stationedProvinceId: cap,
              regimentUnitIds: const [],
              isHomeArmy: true,
            ),
            Army(
              id: 'field_a',
              ownerId: 'gp1',
              regionId: 'oldWorld',
              stationedProvinceId: p1,
              regimentUnitIds: const ['u1'],
              isHomeArmy: false,
            ),
          ],
          playerVisibilityByTile: const {
            'gp1': {
              'oldWorld|cap|0|0': 'fullyVisible',
              'oldWorld|p1|0|0': 'fullyVisible',
              'newWorld|col|0|0': 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince: {
            'oldWorld': {
              cap: [cap],
              p1: ['oldWorld|p1|0|0'],
            },
            'newWorld': {
              nw: ['newWorld|col|0|0'],
            },
          },
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'GP',
            isHuman: false,
            leaderKey: 'victoria',
            capitalProvinceId: cap,
          ),
        ],
      );
      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: cap,
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: p1,
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: nw,
            regionId: 'newWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final snapshot = AIWorldSnapshot.fromPlayerView(view);
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final seeds = AISeedBundle.fromTurnSeed(77);
      const api = DefaultOrderSuggestionAPI();
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
        suggestionAPI: api,
        economyPlan: economyPlan,
      );

      expect(orders.armyMoveOrdersByPlayerId['gp1'], isNotNull);
      expect(orders.armyMoveOrdersByPlayerId['gp1']!, isNotEmpty);
    });

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

    test('uses economy and naval planners when candidates exist', () {
      // Fake suggestion API to hit economy (work/build), naval move/mission, and research
      // branches without depending on full game logic.
      final fakeApi = FakeOrderSuggestionAPIForDomainPlannerTests(
        work: const [
          WorkOrder(
            unitId: 'u1',
            target: 'explore',
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
            techId: 'road_construction',
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
      final snapshot = AIWorldSnapshot.fromPlayerView(view);
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final seeds = AISeedBundle.fromTurnSeed(123);
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
        primaryGoal: StrategicGoal.expand,
        seeds: seeds,
        suggestionAPI: fakeApi,
        economyPlan: economyPlan,
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
