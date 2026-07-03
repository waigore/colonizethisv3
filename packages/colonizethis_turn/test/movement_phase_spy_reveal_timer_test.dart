import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_turn/src/turn/phases/movement_phase.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Spy fog is immediate at end-of-turn when no spy remains (Refs #3834 R3).
/// Movement no longer arms spyRevealTurnsByPlayer timers.
void main() {
  group('runMovementPhase spy province leave (immediate fog model)', () {
    test('when spy leaves an enemy province, movement does not arm reveal timers',
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
          turnState: const TurnState(
            phase: TurnPhase.movement,
            turnNumber: 2,
          ),
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
          Player(id: 'spyOwner', displayName: 'Human spy', isHuman: true),
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

      expect(after.worldState.spyRevealTurnsByPlayer['spyOwner'], isNull);
    });

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
            provinces: const [Province(id: p2, regionId: ow, ownerId: 'enemy')],
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
          Player(id: 'spyOwner', displayName: 'Human spy', isHuman: true),
          Player(id: 'enemy', displayName: 'Enemy', isHuman: false),
        ],
      );

      final after = runMovementPhase(
        game,
        topology,
        const Orders(
          moveOrdersByPlayerId: {
            'spyOwner': [MoveOrder(unitId: 'spy1', destinationTileKey: tileB)],
          },
        ),
      );

      expect(after.worldState.spyRevealTurnsByPlayer['spyOwner'], isNull);
    });

    test('when no spy moves, spyRevealTurnsByPlayer is unchanged (Refs #2394)',
        () {
      const ow = 'oldWorld';
      const p1 = '$ow|p1';
      const p2 = '$ow|p2';
      const tileP1a = '$p1|0|0';
      const tileP1b = '$p1|1|0';

      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: p1, regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: p2, regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: p1, id2: p2)],
      );

      const existingSpyTimers = <String, Map<String, int>>{
        'spyOwner': {p2: 3},
      };

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
                id: 'scout1',
                type: kUnitTypeExplorer,
                ownerId: 'spyOwner',
                locationProvinceId: p1,
                tileKey: tileP1a,
              ),
            ],
          ),
          newWorld: const RegionData(),
          tileKeysByRegionAndProvince: const {
            ow: {
              p1: [tileP1a, tileP1b],
              p2: [],
            },
          },
          spyRevealTurnsByPlayer: existingSpyTimers,
        ),
        players: const [
          Player(id: 'spyOwner', displayName: 'Human spy', isHuman: true),
          Player(id: 'enemy', displayName: 'Enemy', isHuman: false),
        ],
      );

      final after = runMovementPhase(
        game,
        topology,
        const Orders(
          moveOrdersByPlayerId: {
            'spyOwner': [
              MoveOrder(unitId: 'scout1', destinationTileKey: tileP1b),
            ],
          },
        ),
      );

      expect(
        identical(after.worldState.spyRevealTurnsByPlayer, existingSpyTimers),
        isTrue,
      );
    });
  });
}
