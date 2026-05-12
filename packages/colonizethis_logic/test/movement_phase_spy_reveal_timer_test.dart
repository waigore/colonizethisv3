import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/turn/phases/movement_phase.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('runMovementPhase spy province-leave reveal timer', () {
    test(
      'when spy leaves an enemy province via civilian move, sets spyRevealTurns',
      () {
        const ow = 'oldWorld';
        const p1 = '$ow|p1';
        const p2 = '$ow|p2';
        const tileP1 = '$p1|0|0';
        const tileP2 = '$p2|0|0';

        final topology = MapTopology(
          nodes: const [
            TopologyNode(id: p1, regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: p2, regionId: ow, type: TopologyNodeType.province),
          ],
          edges: const [TopologyEdge(id1: p1, id2: p2)],
        );

        final game = Game(
          id: 'g',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.movement, turnNumber: 2),
            oldWorld: RegionData(
              provinces: const [
                Province(id: p1, regionId: ow, ownerId: 'spyOwner'),
                Province(id: p2, regionId: ow, ownerId: 'enemy'),
              ],
              units: [
                Unit(
                  id: 'spy1',
                  type: kUnitTypeSpy,
                  ownerId: 'spyOwner',
                  locationProvinceId: p2,
                  tileKey: tileP2,
                ),
              ],
            ),
            newWorld: const RegionData(),
            tileKeysByRegionAndProvince: const {
              ow: {
                p1: [tileP1],
                p2: [tileP2],
              },
            },
          ),
          players: const [
            Player(id: 'spyOwner', displayName: 'Spy', isHuman: true),
            Player(id: 'enemy', displayName: 'Enemy', isHuman: false),
          ],
        );

        final after = runMovementPhase(
          game,
          topology,
          const Orders(
            moveOrdersByPlayerId: {
              'spyOwner': [
                MoveOrder(unitId: 'spy1', destinationTileKey: tileP1),
              ],
            },
          ),
        );

        expect(after.worldState.spyRevealTurnsByPlayer['spyOwner']?[p2], 5);
      },
    );

    test('spy move within same province does not arm reveal timer', () {
      const ow = 'oldWorld';
      const p2 = '$ow|p2';
      const tileA = '$p2|0|0';
      const tileB = '$p2|1|0';

      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: p2, regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [],
      );

      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.movement, turnNumber: 2),
          oldWorld: RegionData(
            provinces: const [
              Province(id: p2, regionId: ow, ownerId: 'enemy'),
            ],
            units: [
              Unit(
                id: 'spy1',
                type: kUnitTypeSpy,
                ownerId: 'spyOwner',
                locationProvinceId: p2,
                tileKey: tileA,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            ow: {
              p2: [tileA, tileB],
            },
          },
        ),
        players: const [
          Player(id: 'spyOwner', displayName: 'Spy', isHuman: true),
          Player(id: 'enemy', displayName: 'Enemy', isHuman: false),
        ],
      );

      final after = runMovementPhase(
        game,
        topology,
        const Orders(
          moveOrdersByPlayerId: {
            'spyOwner': [
              MoveOrder(unitId: 'spy1', destinationTileKey: tileB),
            ],
          },
        ),
      );

      expect(after.worldState.spyRevealTurnsByPlayer['spyOwner'], isNull);
    });
  });
}
