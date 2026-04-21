import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

// Fake suggestion API used to drive domain planners deterministically in tests.
class _FakeOrderSuggestionAPI implements OrderSuggestionAPI {
  const _FakeOrderSuggestionAPI({
    required this.work,
    required this.build,
    required this.move,
    required this.research,
    required this.navalMove,
    required this.navalMission,
    this.diplomatic = const [],
    this.armyMove = const [],
  });

  final List<WorkOrder> work;
  final List<BuildUnitOrder> build;
  final List<MoveOrder> move;
  final List<ResearchOrder> research;
  final List<NavalMoveOrder> navalMove;
  final List<NavalMissionOrder> navalMission;
  final List<DiplomaticOrder> diplomatic;
  final List<ArmyMoveOrder> armyMove;

  @override
  List<MoveOrder> suggestMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) => move;

  @override
  List<ArmyMoveOrder> suggestArmyMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) => armyMove;

  @override
  List<WorkOrder> suggestWorkOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) => work;

  @override
  List<BuildUnitOrder> suggestBuildOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) => build;

  @override
  List<ResearchOrder> suggestResearchOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) => research;

  @override
  List<NavalMoveOrder> suggestNavalMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) => navalMove;

  @override
  List<NavalMissionOrder> suggestNavalMissionOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) => navalMission;

  @override
  List<DiplomaticOrder> suggestDiplomaticOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) => diplomatic;
}

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
      final fakeApi = _FakeOrderSuggestionAPI(
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
      final fakeApi = _FakeOrderSuggestionAPI(
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
        const fakeApi = _FakeOrderSuggestionAPI(
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
      const fakeApi = _FakeOrderSuggestionAPI(
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
        const fakeApi = _FakeOrderSuggestionAPI(
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
        const fakeApi = _FakeOrderSuggestionAPI(
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

  group('war declaration relation threshold and target scoring', () {
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
        final snapshot = AIWorldSnapshot.fromPlayerView(view);
        const config = AIConfig(
          leaderId: 'victoria',
          personalityId: 'victoria',
          hiddenAgendaId: 'peacemaker',
        );
        final seeds = AISeedBundle.fromTurnSeed(111);
        const fakeApi = _FakeOrderSuggestionAPI(
          work: [],
          build: [],
          move: [],
          research: [],
          navalMove: [],
          navalMission: [],
          diplomatic: [
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

    test('warmonger gets bonus for weakNeighbors target', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'oldWorld|p1', regionId: 'oldWorld', ownerId: 'gp1'),
              Province(id: 'oldWorld|p2', regionId: 'oldWorld', ownerId: 'gp2'),
              Province(id: 'oldWorld|p3', regionId: 'oldWorld', ownerId: 'gp3'),
            ],
            units: [],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            leaderKey: 'napoleon',
            militaryLevel: 3,
          ),
          Player(id: 'gp2', displayName: 'B', isHuman: false, militaryLevel: 1),
          Player(id: 'gp3', displayName: 'C', isHuman: false, militaryLevel: 5),
        ],
        diplomacyRelations: [
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 50,
            state: RelationState.atPeace,
          ),
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp3',
            score: 50,
            state: RelationState.atPeace,
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
          TopologyNode(
            id: 'p3',
            regionId: 'oldWorld',
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [
          TopologyEdge(id1: 'p1', id2: 'p2'),
          TopologyEdge(id1: 'p1', id2: 'p3'),
        ],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final snapshot = AIWorldSnapshot.fromPlayerView(view, topology: topology);
      expect(
        snapshot.opportunities.weakNeighbors,
        contains('gp2'),
        reason: 'gp2 owns p2 adjacent to gp1 p1',
      );
      expect(snapshot.opportunities.weakNeighbors, contains('gp3'));
      const config = AIConfig(
        leaderId: 'napoleon',
        personalityId: 'napoleon',
        hiddenAgendaId: 'warmonger',
      );
      final seeds = AISeedBundle.fromTurnSeed(222);
      const fakeApi = _FakeOrderSuggestionAPI(
        work: [],
        build: [],
        move: [],
        research: [],
        navalMove: [],
        navalMission: [],
        diplomatic: [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'gp2',
          ),
        ],
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
        primaryGoal: StrategicGoal.conquer,
        seeds: seeds,
        suggestionAPI: fakeApi,
        economyPlan: economyPlan,
      );

      final diplo = orders.diplomaticOrdersByPlayerId['gp1'];
      expect(diplo, isNotNull);
      expect(diplo!.single.type, DiplomaticOrderType.declareWar);
      expect(
        diplo.single.targetFactionId,
        'gp2',
        reason:
            'only candidate is gp2 (weak neighbor); warmonger applies +30 bonus',
      );
    });

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
        final snapshot = AIWorldSnapshot.fromPlayerView(view);
        const config = AIConfig(
          leaderId: 'napoleon',
          personalityId: 'napoleon',
          hiddenAgendaId: 'backstabber',
        );
        final seeds = AISeedBundle.fromTurnSeed(333);
        const fakeApi = _FakeOrderSuggestionAPI(
          work: [],
          build: [],
          move: [],
          research: [],
          navalMove: [],
          navalMission: [],
          diplomatic: [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'gp2',
            ),
          ],
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
          primaryGoal: StrategicGoal.conquer,
          seeds: seeds,
          suggestionAPI: fakeApi,
          economyPlan: economyPlan,
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

  group('computeWarDesireScore', () {
    test(
      'higher relative power and hostile relation yields higher war desire',
      () {
        final strongVsWeak = Game(
          id: 'g-desire-1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
                Province(
                  id: 'oldWorld|p2',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
                Province(
                  id: 'oldWorld|p3',
                  regionId: 'oldWorld',
                  ownerId: 'gp2',
                ),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: 'grenadiers',
                  ownerId: 'gp1',
                  locationProvinceId: 'oldWorld|p1',
                ),
                Unit(
                  id: 'u2',
                  type: 'grenadiers',
                  ownerId: 'gp1',
                  locationProvinceId: 'oldWorld|p2',
                ),
              ],
            ),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
          ],
        );
        final weakVsStrong = strongVsWeak.copyWith(
          worldState: strongVsWeak.worldState.copyWith(
            oldWorld: RegionData(
              provinces: strongVsWeak.worldState.oldWorld.provinces,
              units: [
                Unit(
                  id: 'u3',
                  type: 'grenadiers',
                  ownerId: 'gp2',
                  locationProvinceId: 'oldWorld|p3',
                ),
                Unit(
                  id: 'u4',
                  type: 'grenadiers',
                  ownerId: 'gp2',
                  locationProvinceId: 'oldWorld|p3',
                ),
              ],
            ),
          ),
        );

        final high = computeWarDesireScore(
          game: strongVsWeak,
          nationId: 'gp1',
          targetFactionId: 'gp2',
          relationScore: 20,
        );
        final low = computeWarDesireScore(
          game: weakVsStrong,
          nationId: 'gp1',
          targetFactionId: 'gp2',
          relationScore: 80,
        );

        expect(high, greaterThan(low));
      },
    );

    test(
      'minor target with intervention risk and no navy reduces war desire',
      () {
        final game = Game(
          id: 'g-desire-2',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 3),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|p1',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
                Province(
                  id: 'oldWorld|p2',
                  regionId: 'oldWorld',
                  ownerId: 'minor1',
                ),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: 'grenadiers',
                  ownerId: 'gp1',
                  locationProvinceId: 'oldWorld|p1',
                ),
              ],
            ),
            newWorld: RegionData(
              provinces: const [
                Province(
                  id: 'newWorld|n1',
                  regionId: 'newWorld',
                  ownerId: 'minor1',
                ),
              ],
              units: [
                Unit(
                  id: 'u2',
                  type: 'grenadiers',
                  ownerId: 'minor1',
                  locationProvinceId: 'newWorld|n1',
                ),
                Unit(
                  id: 'u3',
                  type: 'grenadiers',
                  ownerId: 'minor1',
                  locationProvinceId: 'newWorld|n1',
                ),
              ],
            ),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
            Player(id: 'gp3', displayName: 'C', isHuman: false),
          ],
          minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
          overtureStates: const [
            OvertureState(
              gpId: 'gp2',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
            ),
            OvertureState(
              gpId: 'gp3',
              targetId: 'minor1',
              stage: OvertureStage.embassy,
            ),
          ],
        );
        final score = computeWarDesireScore(
          game: game,
          nationId: 'gp1',
          targetFactionId: 'minor1',
          relationScore: 40,
        );
        expect(score, lessThan(50));
      },
    );

    test('minor target resources increase war desire when GP stockpile lacks them', () {
      const tileKey = 'oldWorld|p2|0|0';
      WorldState state({required Map<String, String> resources}) => WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: const [
            Province(
              id: 'oldWorld|p1',
              regionId: 'oldWorld',
              ownerId: 'gp1',
            ),
            Province(
              id: 'oldWorld|p2',
              regionId: 'oldWorld',
              ownerId: 'minor1',
            ),
          ],
          units: [
            Unit(
              id: 'u1',
              type: 'grenadiers',
              ownerId: 'gp1',
              locationProvinceId: 'oldWorld|p1',
            ),
            Unit(
              id: 'u2',
              type: 'grenadiers',
              ownerId: 'gp1',
              locationProvinceId: 'oldWorld|p1',
            ),
            Unit(
              id: 'u3',
              type: 'grenadiers',
              ownerId: 'minor1',
              locationProvinceId: 'oldWorld|p2',
            ),
          ],
        ),
        newWorld: const RegionData(),
        tileKeysByRegionAndProvince: {
          'oldWorld': {
            'oldWorld|p2': [tileKey],
          },
        },
        resourceByTileKey: resources,
      );
      final withoutRes = Game(
        id: 'g-res-0',
        worldState: state(resources: const {}),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            stockpile: Stockpile(quantities: {'grain': 10}),
          ),
        ],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'M')],
      );
      final withRes = withoutRes.copyWith(
        id: 'g-res-1',
        worldState: state(resources: {tileKey: 'tobacco'}),
      );
      const relation = 40;
      final a = computeWarDesireScore(
        game: withoutRes,
        nationId: 'gp1',
        targetFactionId: 'minor1',
        relationScore: relation,
      );
      final b = computeWarDesireScore(
        game: withRes,
        nationId: 'gp1',
        targetFactionId: 'minor1',
        relationScore: relation,
      );
      expect(b - a, 5);
    });
  });

  group('computeDiplomaticCandidateScores', () {
    test('declareWar score exceeds establishOverture for same hostile target', () {
      final game = Game(
        id: 'g-diplo-score-1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: const [
              Province(
                id: 'oldWorld|p1',
                regionId: 'oldWorld',
                ownerId: 'gp1',
              ),
              Province(
                id: 'oldWorld|p2',
                regionId: 'oldWorld',
                ownerId: 'gp1',
              ),
              Province(
                id: 'oldWorld|p3',
                regionId: 'oldWorld',
                ownerId: 'gp1',
              ),
              Province(
                id: 'oldWorld|p4',
                regionId: 'oldWorld',
                ownerId: 'gp2',
              ),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'grenadiers',
                ownerId: 'gp1',
                locationProvinceId: 'oldWorld|p1',
              ),
              Unit(
                id: 'u2',
                type: 'grenadiers',
                ownerId: 'gp1',
                locationProvinceId: 'oldWorld|p2',
              ),
              Unit(
                id: 'u3',
                type: 'grenadiers',
                ownerId: 'gp1',
                locationProvinceId: 'oldWorld|p3',
              ),
              Unit(
                id: 'u4',
                type: 'grenadiers',
                ownerId: 'gp2',
                locationProvinceId: 'oldWorld|p4',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [
          Player(id: 'gp1', displayName: 'A', isHuman: false),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 20,
            level: RelationLevel.hostile,
            state: RelationState.atPeace,
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
      final scores = computeDiplomaticCandidateScores(
        candidates: const [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'gp2',
          ),
          DiplomaticOrder(
            type: DiplomaticOrderType.establishOverture,
            targetFactionId: 'gp2',
          ),
        ],
        nationId: 'gp1',
        game: game,
        snapshot: snapshot,
        config: config,
      );
      expect(scores.length, 2);
      expect(scores[0], greaterThan(scores[1]));
    });

    test('offer peace candidate scores lower when war desire is higher', () {
      Game gameForWarDesire({
        required int gp2ProvinceCount,
        required int gp2Regiments,
      }) {
        final provinces = <Province>[
          const Province(
            id: 'oldWorld|p1',
            regionId: 'oldWorld',
            ownerId: 'gp1',
          ),
        ];
        var i = 0;
        for (; i < gp2ProvinceCount; i++) {
          provinces.add(
            Province(
              id: 'oldWorld|g2_$i',
              regionId: 'oldWorld',
              ownerId: 'gp2',
            ),
          );
        }
        final units = <Unit>[
          Unit(
            id: 'a1',
            type: 'grenadiers',
            ownerId: 'gp1',
            locationProvinceId: 'oldWorld|p1',
          ),
          Unit(
            id: 'a2',
            type: 'grenadiers',
            ownerId: 'gp1',
            locationProvinceId: 'oldWorld|p1',
          ),
        ];
        for (var r = 0; r < gp2Regiments; r++) {
          units.add(
            Unit(
              id: 'b$r',
              type: 'grenadiers',
              ownerId: 'gp2',
              locationProvinceId: 'oldWorld|g2_0',
            ),
          );
        }
        return Game(
          id: 'g-peace-$gp2ProvinceCount-$gp2Regiments',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 2),
            oldWorld: RegionData(provinces: provinces, units: units),
            newWorld: const RegionData(),
          ),
          players: const [
            Player(id: 'gp1', displayName: 'A', isHuman: false),
            Player(id: 'gp2', displayName: 'B', isHuman: false),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp2',
              score: 25,
              level: RelationLevel.hostile,
              state: RelationState.atWar,
            ),
          ],
        );
      }

      final highDesireGame = gameForWarDesire(gp2ProvinceCount: 1, gp2Regiments: 1);
      final lowDesireGame =
          gameForWarDesire(gp2ProvinceCount: 3, gp2Regiments: 4);
      expect(
        computeWarDesireScore(
          game: highDesireGame,
          nationId: 'gp1',
          targetFactionId: 'gp2',
          relationScore: 25,
        ),
        greaterThan(
          computeWarDesireScore(
            game: lowDesireGame,
            nationId: 'gp1',
            targetFactionId: 'gp2',
            relationScore: 25,
          ),
        ),
      );
      const topology = MapTopology(nodes: [], edges: []);
      final viewHi = buildPlayerView(highDesireGame, topology, 'gp1');
      final viewLo = buildPlayerView(lowDesireGame, topology, 'gp1');
      final snapHi = AIWorldSnapshot.fromPlayerView(viewHi);
      final snapLo = AIWorldSnapshot.fromPlayerView(viewLo);
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'victoria',
        hiddenAgendaId: 'peacemaker',
      );
      final peaceHi = computeDiplomaticCandidateScores(
        candidates: const [
          DiplomaticOrder(
            type: DiplomaticOrderType.offerPeace,
            targetFactionId: 'gp2',
          ),
        ],
        nationId: 'gp1',
        game: highDesireGame,
        snapshot: snapHi,
        config: config,
      ).single;
      final peaceLo = computeDiplomaticCandidateScores(
        candidates: const [
          DiplomaticOrder(
            type: DiplomaticOrderType.offerPeace,
            targetFactionId: 'gp2',
          ),
        ],
        nationId: 'gp1',
        game: lowDesireGame,
        snapshot: snapLo,
        config: config,
      ).single;
      expect(peaceLo, greaterThan(peaceHi));
    });
  });

  group('diplomacy planner cooldowns', () {
    test('declareWar candidate score zero while wardec retry cooldown active', () {
      final game = Game(
        id: 'g-cool-war',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 5),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            leaderKey: 'napoleon',
          ),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 10,
            level: RelationLevel.hostile,
            state: RelationState.atPeace,
          ),
        ],
        diplomaticHistoryEvents: [
          DiplomaticEvent(
            turn: 2,
            intraTurnIndex: 0,
            type: DiplomaticEventType.declareWar,
            participants: {'gp1', 'gp2'},
            fromFactionId: 'gp1',
            toFactionId: 'gp2',
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
      final scores = computeDiplomaticCandidateScores(
        candidates: const [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'gp2',
          ),
        ],
        nationId: 'gp1',
        game: game,
        snapshot: snapshot,
        config: config,
      );
      expect(scores.single, 0);
    });

    test('establishOverture score zero while improve-relations cooldown active', () {
      final game = Game(
        id: 'g-cool-overture',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 8),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            leaderKey: 'victoria',
          ),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 40,
            state: RelationState.atPeace,
          ),
        ],
        diplomaticHistoryEvents: [
          DiplomaticEvent(
            turn: 7,
            intraTurnIndex: 0,
            type: DiplomaticEventType.overtureAccepted,
            participants: {'gp1', 'gp2'},
            fromFactionId: 'gp1',
            toFactionId: 'gp2',
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
      final scores = computeDiplomaticCandidateScores(
        candidates: const [
          DiplomaticOrder(
            type: DiplomaticOrderType.establishOverture,
            targetFactionId: 'gp2',
          ),
        ],
        nationId: 'gp1',
        game: game,
        snapshot: snapshot,
        config: config,
      );
      expect(scores.single, 0);
    });

    test('runDomainPlanners emits no diplomatic order when all candidates on cooldown',
        () {
      final game = Game(
        id: 'g-cool-all',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 4),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            leaderKey: 'napoleon',
          ),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 10,
            level: RelationLevel.hostile,
            state: RelationState.atPeace,
          ),
        ],
        diplomaticHistoryEvents: [
          DiplomaticEvent(
            turn: 1,
            intraTurnIndex: 0,
            type: DiplomaticEventType.declareWar,
            participants: {'gp1', 'gp2'},
            fromFactionId: 'gp1',
            toFactionId: 'gp2',
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
      final seeds = AISeedBundle.fromTurnSeed(202);
      const fakeApi = _FakeOrderSuggestionAPI(
        work: [],
        build: [],
        move: [],
        research: [],
        navalMove: [],
        navalMission: [],
        diplomatic: [
          DiplomaticOrder(
            type: DiplomaticOrderType.declareWar,
            targetFactionId: 'gp2',
          ),
        ],
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
        primaryGoal: StrategicGoal.conquer,
        seeds: seeds,
        suggestionAPI: fakeApi,
        economyPlan: economyPlan,
      );
      expect(orders.diplomaticOrdersByPlayerId['gp1'], isNull);
    });

    test('improve-relations cooldown expired allows overture selection deterministically',
        () {
      final game = Game(
        id: 'g-cool-overture-ok',
        worldState: const WorldState(
          turnState: TurnState(phase: TurnPhase.orders, turnNumber: 10),
          oldWorld: RegionData(),
          newWorld: RegionData(),
        ),
        players: const [
          Player(
            id: 'gp1',
            displayName: 'A',
            isHuman: false,
            leaderKey: 'victoria',
          ),
          Player(id: 'gp2', displayName: 'B', isHuman: false),
        ],
        diplomacyRelations: [
          const DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp2',
            score: 40,
            state: RelationState.atPeace,
          ),
        ],
        diplomaticHistoryEvents: [
          DiplomaticEvent(
            turn: 7,
            intraTurnIndex: 0,
            type: DiplomaticEventType.overtureAccepted,
            participants: {'gp1', 'gp2'},
            fromFactionId: 'gp1',
            toFactionId: 'gp2',
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
      final seeds = AISeedBundle.fromTurnSeed(77);
      const diplo = DiplomaticOrder(
        type: DiplomaticOrderType.establishOverture,
        targetFactionId: 'gp2',
      );
      const fakeApi = _FakeOrderSuggestionAPI(
        work: [],
        build: [],
        move: [],
        research: [],
        navalMove: [],
        navalMission: [],
        diplomatic: [diplo],
      );
      const economyPlan = EconomyPlan(
        productionAssignments: [],
        cargoPreference: CargoPreference.none,
      );
      final orders1 = runDomainPlanners(
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
      final orders2 = runDomainPlanners(
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
      expect(orders1.diplomaticOrdersByPlayerId['gp1'], isNotNull);
      expect(orders1.diplomaticOrdersByPlayerId['gp1']!.single, diplo);
      expect(orders2.diplomaticOrdersByPlayerId['gp1'], orders1.diplomaticOrdersByPlayerId['gp1']);
    });
  });

  group('move planner diplomacy filter', () {
    test('full-AI move planner scores civilian moves; at-peace target not pre-filtered',
        () {
      const ow = 'oldWorld';
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: 'p1', regionId: ow, ownerId: 'gp1'),
              Province(id: 'p2', regionId: ow, ownerId: 'gp2'),
              Province(id: 'p3', regionId: ow, ownerId: 'gp3'),
            ],
            units: [],
          ),
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
            score: 0,
            state: RelationState.atWar,
          ),
          DiplomacyRelation(
            factionId1: 'gp1',
            factionId2: 'gp3',
            score: 50,
            state: RelationState.atPeace,
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
      final seeds = AISeedBundle.fromTurnSeed(444);
      const fakeApi = _FakeOrderSuggestionAPI(
        work: [],
        build: [],
        move: [
          MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|p2|0|0'),
          MoveOrder(unitId: 'u2', destinationTileKey: 'oldWorld|p3|0|0'),
        ],
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
        primaryGoal: StrategicGoal.conquer,
        seeds: seeds,
        suggestionAPI: fakeApi,
        economyPlan: economyPlan,
      );

      final moves = orders.moveOrdersByPlayerId['gp1'] ?? [];
      expect(moves.length, 1);
      // At-war destination is heavily weighted over at-peace (see kMovePreferEnemyTerritoryBonus).
      expect(moves.single.destinationTileKey, 'oldWorld|p2|0|0');
    });
  });
}
