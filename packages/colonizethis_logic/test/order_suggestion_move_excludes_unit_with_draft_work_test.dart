import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// Refs #2082 regression: Full AI applies work before move planning; move
/// suggestions must not include the same civilian [unitId] as an existing
/// draft [WorkOrder] (move/work XOR via order engine validation).
void main() {
  test(
    'suggestMoveOrders emits no MoveOrder for a unit that already has a '
    'draft WorkOrder',
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
          Player(id: playerId, displayName: 'GP', isHuman: false),
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

      final withDraftWork = Orders(
        workOrdersByPlayerId: {
          playerId: [
            WorkOrder(
              unitId: 'u1',
              target: kWorkTargetExplore,
              targetTileKey: tileB,
            ),
          ],
        },
      );

      final suggestions = suggestMoveOrders(
        view,
        game,
        topology,
        withDraftWork,
      );

      expect(
        suggestions.where((m) => m.unitId == 'u1'),
        isEmpty,
        reason: 'civilian_move_xor_work_order: no move for same unit as work',
      );
    },
  );
}
