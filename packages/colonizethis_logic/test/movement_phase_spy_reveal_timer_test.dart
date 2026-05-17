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

    test('when no spy leaves an enemy province, spyRevealTurnsByPlayer is '
        'returned without an eager deep copy (Refs #2394 Category D)', () {
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

      // Seed an existing spy reveal entry so we can assert identity is
      // preserved across the move phase when no new spy event fires.
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
            // A non-spy unit moving within the player's own territory must
            // not arm a reveal timer and must not trigger any spy timer
            // mutation.
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

      // Same reference is reused: the move phase did not perform an
      // eager deep copy of spyRevealTurnsByPlayer when no spy moved.
      expect(
        identical(after.worldState.spyRevealTurnsByPlayer, existingSpyTimers),
        isTrue,
        reason:
            'No spy reveal events should preserve the existing map '
            'reference instead of deep-copying.',
      );
      expect(
        after.worldState.spyRevealTurnsByPlayer['spyOwner']?[p2],
        3,
        reason: 'Existing reveal timers must be carried through unchanged.',
      );
    });

    test('when a spy leaves an enemy province, prior reveal entries from other '
        'owners and provinces are preserved alongside the new entry', () {
      const ow = 'oldWorld';
      const p1 = '$ow|p1';
      const p2 = '$ow|p2';
      const p3 = '$ow|p3';
      const tileP1 = '$p1|0|0';
      const tileP2 = '$p2|0|0';

      final topology = MapTopology(
        nodes: const [
          TopologyNode(id: p1, regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: p2, regionId: ow, type: TopologyNodeType.province),
          TopologyNode(id: p3, regionId: ow, type: TopologyNodeType.province),
        ],
        edges: const [TopologyEdge(id1: p1, id2: p2)],
      );

      const existingSpyTimers = <String, Map<String, int>>{
        'spyOwner': {p3: 2},
        'otherOwner': {p3: 4},
      };

      final game = Game(
        id: 'g',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.movement, turnNumber: 2),
          oldWorld: RegionData(
            provinces: const [
              Province(id: p1, regionId: ow, ownerId: 'spyOwner'),
              Province(id: p2, regionId: ow, ownerId: 'enemy'),
              Province(id: p3, regionId: ow, ownerId: 'enemy'),
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
              p3: [],
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
            'spyOwner': [MoveOrder(unitId: 'spy1', destinationTileKey: tileP1)],
          },
        ),
      );

      final spyTimers = after.worldState.spyRevealTurnsByPlayer;
      expect(spyTimers['spyOwner']?[p2], 5, reason: 'New reveal armed.');
      expect(
        spyTimers['spyOwner']?[p3],
        2,
        reason: 'Pre-existing same-owner timer must be carried over.',
      );
      expect(
        spyTimers['otherOwner']?[p3],
        4,
        reason: 'Unrelated owner entries must be carried over.',
      );
      // The lazy copy must produce a new outer map (mutated separately).
      expect(
        identical(spyTimers, existingSpyTimers),
        isFalse,
        reason: 'Once a spy event fires we must not mutate the input map.',
      );
    });
  });
}
