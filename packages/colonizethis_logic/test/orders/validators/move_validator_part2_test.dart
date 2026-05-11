import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'move_validator_test_support.dart';

void main() {
  group('MoveValidator', () {
    const ow = 'oldWorld';
    final topology = moveValidatorTestTwoProvinceTopology(ow);

    test('Explorer may move onto Minor province tile (cross-region style)', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'minor1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                tileKey: 'oldWorld|P1|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'fogged',
            },
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
      );
      final unitsById = {for (final u in game.worldState.oldWorld.units) u.id: u};
      final view = buildPlayerView(game, topology, 'p1');
      const validator = MoveValidator();
      final result = validator.validate(
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
        game,
        'p1',
        unitsById,
        [],
        view,
        topology,
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.accepted);
    });

    test('Spy may move onto other Great Power province tile without declare war', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p2'),
            ],
            units: [
              Unit(
                id: 's1',
                type: kUnitTypeSpy,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
                tileKey: 'oldWorld|P1|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'fogged',
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
        diplomacyRelations: const [],
      );
      final unitsById = {for (final u in game.worldState.oldWorld.units) u.id: u};
      final view = buildPlayerView(game, topology, 'p1');
      const validator = MoveValidator();
      final result = validator.validate(
        const MoveOrder(unitId: 's1', destinationTileKey: 'oldWorld|P2|0|0'),
        game,
        'p1',
        unitsById,
        [],
        view,
        topology,
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.accepted);
    });

    test(
      'explorer can move cross-region into tribe-owned province',
      () {
        const nw = 'newWorld';
        final combinedTopology = MapTopology(
          nodes: const [
            TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: 'P2', regionId: nw, type: TopologyNodeType.province),
          ],
          edges: const [],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: kUnitTypeExplorer,
                  ownerId: 'p1',
                  locationProvinceId: '$ow|P1',
                  tileKey: '$ow|P1|0|0',
                ),
              ],
            ),
            newWorld: const RegionData(
              provinces: [
                Province(id: '$nw|P2', regionId: nw, ownerId: 'tribe1'),
              ],
            ),
            playerVisibilityByTile: const {
              'p1': {
                'oldWorld|P1|0|0': 'fullyVisible',
                'newWorld|P2|0|0': 'fogged',
              },
            },
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
          tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe1')],
        );
        final unitsById = {
          for (final u in [...game.worldState.oldWorld.units, ...game.worldState.newWorld.units]) u.id: u,
        };
        final view = buildPlayerView(game, combinedTopology, 'p1');
        const validator = MoveValidator();
        final result = validator.validate(
          const MoveOrder(unitId: 'u1', destinationTileKey: 'newWorld|P2|0|0'),
          game,
          'p1',
          unitsById,
          const [],
          view,
          combinedTopology,
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.accepted);
      },
    );

    test(
      'builder cross-region into tribe-owned province is still invalid',
      () {
        const nw = 'newWorld';
        final combinedTopology = MapTopology(
          nodes: const [
            TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
            TopologyNode(id: 'P2', regionId: nw, type: TopologyNodeType.province),
          ],
          edges: const [],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: RegionData(
              provinces: [
                Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: kUnitTypeBuilder,
                  ownerId: 'p1',
                  locationProvinceId: '$ow|P1',
                  tileKey: '$ow|P1|0|0',
                ),
              ],
            ),
            newWorld: const RegionData(
              provinces: [
                Province(id: '$nw|P2', regionId: nw, ownerId: 'tribe1'),
              ],
            ),
            playerVisibilityByTile: const {
              'p1': {
                'oldWorld|P1|0|0': 'fullyVisible',
                'newWorld|P2|0|0': 'fogged',
              },
            },
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
          tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe1')],
        );
        final unitsById = {
          for (final u in [...game.worldState.oldWorld.units, ...game.worldState.newWorld.units]) u.id: u,
        };
        final view = buildPlayerView(game, combinedTopology, 'p1');
        const validator = MoveValidator();
        final result = validator.validate(
          const MoveOrder(unitId: 'u1', destinationTileKey: 'newWorld|P2|0|0'),
          game,
          'p1',
          unitsById,
          const [],
          view,
          combinedTopology,
          previousRejected: false,
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Invalid move');
      },
    );
  });
}
