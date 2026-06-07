import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/ai/ai_planner.dart';
import 'package:colonizethis_world/src/world/ai_control.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// [generateOrdersForGame] must match stitching [generateOrdersForPlayer] per
/// AI GP on the original [Game] (each call runs its own ensure). Batch path
/// hoists [ensureMilitaryArmiesForGame] once (Refs #2394).
void main() {
  test('generateOrdersForGame equals per-player stitched orders', () {
    final game = Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
        oldWorld: RegionData(
          provinces: const [
            Province(id: 'oldWorld|P1', regionId: 'oldWorld', ownerId: 'gp1'),
            Province(id: 'oldWorld|P2', regionId: 'oldWorld', ownerId: 'gp2'),
          ],
          units: [
            Unit(
              id: 'u1',
              type: 'grenadiers',
              ownerId: 'gp1',
              locationProvinceId: 'oldWorld|P1',
            ),
            Unit(
              id: 'u2',
              type: 'grenadiers',
              ownerId: 'gp2',
              locationProvinceId: 'oldWorld|P2',
            ),
          ],
        ),
        newWorld: const RegionData(),
        playerVisibilityByTile: const {
          'gp1': {
            'oldWorld|P1|0|0': 'fullyVisible',
            'oldWorld|P2|0|0': 'fullyVisible',
          },
          'gp2': {
            'oldWorld|P1|0|0': 'fullyVisible',
            'oldWorld|P2|0|0': 'fullyVisible',
          },
        },
      ),
      players: const [
        Player(id: 'gp1', displayName: 'AI1', isHuman: false),
        Player(id: 'gp2', displayName: 'AI2', isHuman: false),
      ],
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          state: RelationState.atWar,
        ),
      ],
      globalGameSeed: 0,
      aiSeedByGpId: {'gp1': 11, 'gp2': 22},
    );

    const topology = MapTopology(
      nodes: [
        TopologyNode(
          id: 'P1',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
        TopologyNode(
          id: 'P2',
          regionId: 'oldWorld',
          type: TopologyNodeType.province,
        ),
      ],
      edges: [TopologyEdge(id1: 'P1', id2: 'P2')],
    );

    final batched = generateOrdersForGame(game, topology);

    final moveByPlayer = <String, List<MoveOrder>>{};
    final armyMoveByPlayer = <String, List<ArmyMoveOrder>>{};
    final buildByPlayer = <String, List<BuildUnitOrder>>{};
    final workByPlayer = <String, List<WorkOrder>>{};
    final researchByPlayer = <String, List<ResearchOrder>>{};
    for (final player in game.players) {
      if (!isAiControlled(game, player.id)) continue;
      final o = generateOrdersForPlayer(game, topology, player.id);
      final pid = player.id;
      final m = o.moveOrdersByPlayerId[pid];
      if (m != null && m.isNotEmpty) moveByPlayer[pid] = m;
      final a = o.armyMoveOrdersByPlayerId[pid];
      if (a != null && a.isNotEmpty) armyMoveByPlayer[pid] = a;
      final b = o.buildUnitOrdersByPlayerId[pid];
      if (b != null && b.isNotEmpty) buildByPlayer[pid] = b;
      final w = o.workOrdersByPlayerId[pid];
      if (w != null && w.isNotEmpty) workByPlayer[pid] = w;
      final r = o.researchOrdersByPlayerId[pid];
      if (r != null && r.isNotEmpty) researchByPlayer[pid] = r;
    }
    final stitched = Orders(
      moveOrdersByPlayerId: moveByPlayer,
      armyMoveOrdersByPlayerId: armyMoveByPlayer,
      buildUnitOrdersByPlayerId: buildByPlayer,
      workOrdersByPlayerId: workByPlayer,
      diplomaticOrdersByPlayerId: const {},
      researchOrdersByPlayerId: researchByPlayer,
      navalMoveOrdersByPlayerId: const {},
    );

    expect(batched, equals(stitched));
  });
}
