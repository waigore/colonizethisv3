import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/src/ai/ai_control.dart';
import 'package:colonizethis_logic/src/ai/ai_planner.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

void main() {
  group('generateOrdersForGame', () {
    test(
      'matches per-AI generateOrdersForPlayer aggregate (army ensure parity)',
      () {
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

        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
            oldWorld: RegionData(
              provinces: const [
                Province(
                  id: 'oldWorld|P1',
                  regionId: 'oldWorld',
                  ownerId: 'gp1',
                ),
                Province(
                  id: 'oldWorld|P2',
                  regionId: 'oldWorld',
                  ownerId: 'gp2',
                ),
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
            Player(id: 'gp1', displayName: 'AI 1', isHuman: false),
            Player(id: 'gp2', displayName: 'AI 2', isHuman: false),
          ],
          diplomacyRelations: const [
            DiplomacyRelation(
              factionId1: 'gp1',
              factionId2: 'gp2',
              state: RelationState.atWar,
            ),
          ],
          globalGameSeed: 11,
          aiSeedByGpId: {'gp1': 101, 'gp2': 202},
        );

        final aggregated = generateOrdersForGame(game, topology);

        final moveByPlayer = <String, List<MoveOrder>>{};
        final armyMoveByPlayer = <String, List<ArmyMoveOrder>>{};
        final buildByPlayer = <String, List<BuildUnitOrder>>{};
        final workByPlayer = <String, List<WorkOrder>>{};
        final researchByPlayer = <String, List<ResearchOrder>>{};
        void addIfNonEmpty<T>(
          Map<String, List<T>> aggregate,
          String playerId,
          List<T>? list,
        ) {
          if (list != null && list.isNotEmpty) {
            aggregate[playerId] = list;
          }
        }

        for (final player in game.players) {
          if (!isAiControlled(game, player.id)) continue;
          final one = generateOrdersForPlayer(game, topology, player.id);
          addIfNonEmpty(
            moveByPlayer,
            player.id,
            one.moveOrdersByPlayerId[player.id],
          );
          addIfNonEmpty(
            armyMoveByPlayer,
            player.id,
            one.armyMoveOrdersByPlayerId[player.id],
          );
          addIfNonEmpty(
            buildByPlayer,
            player.id,
            one.buildUnitOrdersByPlayerId[player.id],
          );
          addIfNonEmpty(
            workByPlayer,
            player.id,
            one.workOrdersByPlayerId[player.id],
          );
          addIfNonEmpty(
            researchByPlayer,
            player.id,
            one.researchOrdersByPlayerId[player.id],
          );
        }

        final manual = Orders(
          moveOrdersByPlayerId: moveByPlayer,
          armyMoveOrdersByPlayerId: armyMoveByPlayer,
          buildUnitOrdersByPlayerId: buildByPlayer,
          workOrdersByPlayerId: workByPlayer,
          diplomaticOrdersByPlayerId: const {},
          researchOrdersByPlayerId: researchByPlayer,
          navalMoveOrdersByPlayerId: const {},
        );

        expect(aggregated, equals(manual));
      },
    );
  });
}
