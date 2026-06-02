import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('DefaultOrderSuggestionAPI', () {
    late Game game;
    late MapTopology topology;
    late PlayerView view;
    late Orders emptyOrders;

    setUp(() {
      const ow = 'oldWorld';
      topology = MapTopology(
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
      game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1'),
              Province(id: '$ow|p2', regionId: ow, displayName: 'P2'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'inf',
                ownerId: 'gp1',
                locationProvinceId: '$ow|p1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'gp1': {
              'oldWorld|p1|0|0': 'fullyVisible',
              'oldWorld|p2|0|0': 'fullyVisible',
            },
          },
          tileKeysByRegionAndProvince: {
            ow: {
              '$ow|p1': ['oldWorld|p1|0|0'],
              '$ow|p2': ['oldWorld|p2|0|0'],
            },
          },
        ),
        players: const [Player(id: 'gp1', displayName: 'A', isHuman: true)],
      );
      view = buildPlayerView(game, topology, 'gp1');
      emptyOrders = const Orders();
    });

    test('suggestMoveOrders returns list', () {
      const api = DefaultOrderSuggestionAPI();
      final list = api.suggestMoveOrders(view, game, topology, emptyOrders);
      expect(list, isA<List<MoveOrder>>());
    });

    test('suggestWorkOrders returns list', () {
      const api = DefaultOrderSuggestionAPI();
      final list = api.suggestWorkOrders(view, game, topology, emptyOrders);
      expect(list, isA<List<WorkOrder>>());
    });

    test('suggestBuildOrders returns list', () {
      const api = DefaultOrderSuggestionAPI();
      final list = api.suggestBuildOrders(view, game, topology, emptyOrders);
      expect(list, isA<List<BuildUnitOrder>>());
    });

    test(
      'suggestBuildOrders includes ship types when player can afford a ship',
      () {
        const api = DefaultOrderSuggestionAPI();
        const ow = 'oldWorld';
        final affordableShipTreasury =
            ShipEconomyCatalog.byId['carrack']!.buildTreasuryCost;
        final stockpile = const Stockpile()
            .applyDelta(CommodityCatalog.lumber.id, 2)
            .applyDelta(CommodityCatalog.fabric.id, 2);
        final gameWithShip = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1')],
              units: [],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: 'gp1',
              displayName: 'A',
              isHuman: false,
              capitalProvinceId: '$ow|p1',
              workerPool: const WorkerPool(peasants: 1),
              treasury: affordableShipTreasury,
              stockpile: stockpile,
            ),
          ],
        );
        final topo = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final v = buildPlayerView(gameWithShip, topo, 'gp1');
        final list = api.suggestBuildOrders(v, gameWithShip, topo, emptyOrders);
        final shipBuilds = list
            .where((o) => ShipEconomyCatalog.byId.containsKey(o.unitType))
            .toList();
        expect(
          shipBuilds,
          isNotEmpty,
          reason: 'API should suggest ship builds when affordable',
        );
      },
    );

    test('suggestResearchOrders returns list', () {
      const api = DefaultOrderSuggestionAPI();
      final list = api.suggestResearchOrders(view, game, topology, emptyOrders);
      expect(list, isA<List<ResearchOrder>>());
    });

    test('suggestNavalMoveOrders returns list', () {
      const api = DefaultOrderSuggestionAPI();
      final list = api.suggestNavalMoveOrders(
        view,
        game,
        topology,
        emptyOrders,
      );
      expect(list, isA<List<NavalMoveOrder>>());
    });

    test('suggestNavalMissionOrders returns list', () {
      const api = DefaultOrderSuggestionAPI();
      final list = api.suggestNavalMissionOrders(
        view,
        game,
        topology,
        emptyOrders,
      );
      expect(list, isA<List<NavalMissionOrder>>());
    });

    test(
      'suggestNavalMoveOrders and suggestNavalMissionOrders match when '
      'caller supplies unitsById (Refs #2394)',
      () {
        const api = DefaultOrderSuggestionAPI();
        final unitsById = unitsByIdFromWorld(game.worldState);
        final moveDefault = api.suggestNavalMoveOrders(
          view,
          game,
          topology,
          emptyOrders,
        );
        final moveShared = api.suggestNavalMoveOrders(
          view,
          game,
          topology,
          emptyOrders,
          resolution: orderResolutionContextFromView(view, game, unitsById: unitsById),
        );
        expect(moveShared, moveDefault);
        final missionDefault = api.suggestNavalMissionOrders(
          view,
          game,
          topology,
          emptyOrders,
        );
        final missionShared = api.suggestNavalMissionOrders(
          view,
          game,
          topology,
          emptyOrders,
          resolution: orderResolutionContextFromView(view, game, unitsById: unitsById),
        );
        expect(missionShared, missionDefault);
      },
    );

    test('suggestDiplomaticOrders returns list', () {
      const api = DefaultOrderSuggestionAPI();
      final list = api.suggestDiplomaticOrders(
        view,
        game,
        topology,
        emptyOrders,
      );
      expect(list, isA<List<DiplomaticOrder>>());
    });

    test('suggestRecruitWorkerOrders returns list (#2692 S7)', () {
      const api = DefaultOrderSuggestionAPI();
      final list = api.suggestRecruitWorkerOrders(
        view,
        game,
        topology,
        emptyOrders,
      );
      expect(list, isA<List<RecruitWorkerOrder>>());
    });

    test(
      'suggestRecruitWorkerOrders includes peasant when fabric is affordable '
      '(#2692 S7)',
      () {
        const api = DefaultOrderSuggestionAPI();
        const ow = 'oldWorld';
        final stockpile = const Stockpile().applyDelta(
          CommodityCatalog.fabric.id,
          4,
        );
        final gameWithFabric = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: [Province(id: '$ow|p1', regionId: ow, ownerId: 'gp1')],
            ),
            newWorld: const RegionData(),
          ),
          players: [
            Player(
              id: 'gp1',
              displayName: 'A',
              isHuman: false,
              capitalProvinceId: '$ow|p1',
              stockpile: stockpile,
            ),
          ],
        );
        final topo = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'p1',
              regionId: 'oldWorld',
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [],
        );
        final v = buildPlayerView(gameWithFabric, topo, 'gp1');
        final list = api.suggestRecruitWorkerOrders(
          v,
          gameWithFabric,
          topo,
          const Orders(),
        );
        expect(
          list.any((o) => o.targetTier == WorkerTier.peasant),
          isTrue,
          reason:
              'API impl must surface peasant recruit when 2 fabric affords '
              'the cost row',
        );
      },
    );
  });
}
