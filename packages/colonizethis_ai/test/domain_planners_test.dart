import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

// Fake suggestion API used to drive domain planners deterministically in tests.
class _FakeOrderSuggestionAPI implements OrderSuggestionAPI {
  const _FakeOrderSuggestionAPI({
    required this.work,
    required this.build,
    required this.move,
    required this.research,
    required this.navalMove,
    required this.navalMission,
  });

  final List<WorkOrder> work;
  final List<BuildUnitOrder> build;
  final List<MoveOrder> move;
  final List<ResearchOrder> research;
  final List<NavalMoveOrder> navalMove;
  final List<NavalMissionOrder> navalMission;

  @override
  List<MoveOrder> suggestMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) =>
      move;

  @override
  List<WorkOrder> suggestWorkOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) =>
      work;

  @override
  List<BuildUnitOrder> suggestBuildOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) =>
      build;

  @override
  List<ResearchOrder> suggestResearchOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) =>
      research;

  @override
  List<NavalMoveOrder> suggestNavalMoveOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) =>
      navalMove;

  @override
  List<NavalMissionOrder> suggestNavalMissionOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders,
  ) =>
      navalMission;
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
          Player(id: 'gp1', displayName: 'England', isHuman: false, leaderKey: 'victoria'),
        ],
      );
      const topology = MapTopology(nodes: [], edges: []);
      final view = buildPlayerView(game, topology, 'gp1');
      final snapshot = AIWorldSnapshot.fromPlayerView(view);
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'industrial_trader',
        hiddenAgendaId: 'peacemaker',
      );
      final seeds = AISeedBundle.fromTurnSeed(999);
      const api = DefaultOrderSuggestionAPI();

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
            units: const [
              Unit(
                id: 'u1',
                type: 'inf',
                ownerId: 'gp1',
                provinceId: 'oldWorld|p1',
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
        ),
        players: const [
          Player(id: 'gp1', displayName: 'GP', isHuman: false, leaderKey: 'victoria'),
        ],
      );
      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: 'p1', regionId: 'oldWorld', type: TopologyNodeType.province),
          TopologyNode(id: 'p2', regionId: 'oldWorld', type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
      );
      final view = buildPlayerView(game, topology, 'gp1');
      final snapshot = AIWorldSnapshot.fromPlayerView(view);
      const config = AIConfig(
        leaderId: 'victoria',
        personalityId: 'industrial_trader',
        hiddenAgendaId: 'peacemaker',
      );
      final seeds = AISeedBundle.fromTurnSeed(100);
      const api = DefaultOrderSuggestionAPI();

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
      );

      expect(orders, isNotNull);
      // Move planner may add moves when weight >= 20 and candidates exist.
      expect(orders.moveOrdersByPlayerId['gp1'] != null, isTrue);
    });

    test('uses economy and naval planners when candidates exist', () {
      // Fake suggestion API to hit economy (work/build), naval move/mission, and research
      // branches without depending on full game logic.
      final fakeApi = _FakeOrderSuggestionAPI(
        work: const [WorkOrder(unitId: 'u1', target: 'explore', targetTileKey: 'oldWorld|p1|0|0')],
        build: const [BuildUnitOrder(unitType: 'inf', isMilitary: false, spawnProvinceId: 'oldWorld|p1')],
        move: const [MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|p2')],
        research: const [
          ResearchOrder(
            slotIndex: 0,
            techId: 'road_construction',
            funding: ResearchFundingLevel.low,
          )
        ],
        navalMove: const [NavalMoveOrder(fleetId: 'f1', destinationSeaZoneId: 's2')],
        navalMission: const [NavalMissionOrder(fleetId: 'f1', mission: 'patrol')],
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
            leaderKey: 'victoria', // economy and military weights both high enough
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
        personalityId: 'industrial_trader',
        hiddenAgendaId: 'peacemaker',
      );
      final seeds = AISeedBundle.fromTurnSeed(123);

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
      );

      // Economy: at least one work and build order should be appended.
      expect(orders.workOrdersByPlayerId['gp1']?.length ?? 0, greaterThanOrEqualTo(1));
      expect(orders.buildUnitOrdersByPlayerId['gp1']?.length ?? 0, greaterThanOrEqualTo(1));
      // Research: one research order.
      expect(orders.researchOrdersByPlayerId['gp1']?.length ?? 0, greaterThanOrEqualTo(1));
      // Naval: move + mission orders appended.
      expect(orders.navalMoveOrdersByPlayerId['gp1']?.length ?? 0, greaterThanOrEqualTo(1));
      expect(orders.navalMissionOrdersByPlayerId['gp1']?.length ?? 0, greaterThanOrEqualTo(1));
    });
  });
}
