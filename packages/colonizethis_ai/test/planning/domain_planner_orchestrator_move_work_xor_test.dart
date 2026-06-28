import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../support/planner_test_helpers.dart';

/// [DefaultOrderSuggestionAPI] with fixed civilian work rows so Full AI assigns
/// work first; move suggestions still use production [suggestMoveOrders] (draft
/// work excludes same-unit moves).
final class _InjectedCivilianWorkSuggestionApi extends DefaultOrderSuggestionAPI {
  _InjectedCivilianWorkSuggestionApi(this._work);
  final List<WorkOrder> _work;

  @override
  List<WorkOrder> suggestWorkOrders(
    PlayerView view,
    Game game,
    MapTopology topology,
    Orders currentOrders, {
    Map<String, TileMapResult>? tileMapByRegion,
  }) => List<WorkOrder>.unmodifiable(_work);
}

void main() {
  test(
    'runDomainPlanners emits no MoveOrder for a unit that receives a civilian '
    'WorkOrder in the same pass (move/work XOR)',
    () {
      const playerId = 'gp1';
      const regionId = 'oldWorld';
      const p1 = '$regionId|P1';
      const p2 = '$regionId|P2';
      const tileA = '$p1|0|0';
      const tileB = '$p2|0|0';

      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
          oldWorld: RegionData(
            provinces: [
              Province(id: p1, regionId: regionId, ownerId: playerId),
              Province(id: p2, regionId: regionId, ownerId: playerId),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: playerId,
                locationProvinceId: p1,
                tileKey: tileA,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: {
            regionId: {
              p1: [tileA],
              p2: [tileB],
            },
          },
          playerVisibilityByTile: const {
            playerId: {
              tileA: 'fullyVisible',
              tileB: 'fullyVisible',
            },
          },
        ),
        players: const [
          Player(
            id: playerId,
            displayName: 'GP',
            isHuman: false,
            leaderKey: 'victoria',
          ),
        ],
      );

      final topology = MapTopology(
        nodes: const [
          TopologyNode(
            id: 'P1',
            regionId: regionId,
            type: TopologyNodeType.province,
          ),
          TopologyNode(
            id: 'P2',
            regionId: regionId,
            type: TopologyNodeType.province,
          ),
        ],
        edges: const [
          TopologyEdge(id1: 'P1', id2: 'P2'),
        ],
      );

      final view = buildPlayerView(game, topology, playerId);
      const injectedWork = <WorkOrder>[
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetExplore,
          targetTileKey: tileB,
        ),
      ];
      final api = _InjectedCivilianWorkSuggestionApi(injectedWork);

      final moveIfNoWork = api.suggestMoveOrders(
        view,
        game,
        topology,
        const Orders(),
      );
      expect(
        moveIfNoWork.any((m) => m.unitId == 'u1'),
        isTrue,
        reason: 'fixture should yield at least one move candidate for u1 when '
            'draft orders omit work so XOR behavior is meaningful',
      );

      final orders = runDomainPlannersInTest(
        game: game,
        topology: topology,
        nationId: playerId,
        view: view,
        turnSeed: 902104,
        suggestionAPI: api,
      );

      final workList = orders.workOrdersByPlayerId[playerId] ?? const [];
      expect(workList, isNotEmpty);
      expect(workList.single.unitId, 'u1');

      final moveList = orders.moveOrdersByPlayerId[playerId] ?? const [];
      expect(
        moveList.where((m) => m.unitId == 'u1'),
        isEmpty,
        reason: 'civilian move/work XOR: no MoveOrder for same unitId as draft '
            'WorkOrder after Full AI civilian work in the same planner pass',
      );
    },
  );
}
