import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'move_validator_test_support.dart';

void main() {
  group('MoveValidator', () {
    const ow = 'oldWorld';
    final topology = moveValidatorTestTwoProvinceTopology(ow);

    test('civilian cannot move into other GP territory', () {
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
                id: 'u1',
                type: kUnitTypeBuilder,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
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
      );
      const validator = MoveValidator();
      final result = validator.validate(
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
        game,
        'p1',
        moveValidatorTestContext(game, topology, 'p1'),
        [],
        topology,
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, contains('Invalid move'));
    });

    test('military regiment MoveOrder is rejected; use army move', () {
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
                id: 'u1',
                type: 'pikemen',
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
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
      const validator = MoveValidator();
      final result = validator.validate(
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
        game,
        'p1',
        moveValidatorTestContext(game, topology, 'p1'),
        [],
        topology,
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, contains('army move'));
    });

    test(
      'ArmyMoveValidator military cannot move into other GP province without war',
      () {
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
                  id: 'u1',
                  type: 'pikemen',
                  ownerId: 'p1',
                  locationProvinceId: '$ow|P1',
                ),
              ],
            ),
            newWorld: const RegionData(),
            armies: [moveValidatorTestFieldArmy(ow, 'p1', 'P1', 'u1')],
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
        final view = buildPlayerView(game, topology, 'p1');
        const validator = ArmyMoveValidator();
        final result = validator.validate(
          ArmyMoveOrder(
            armyId: fieldArmyIdFor('p1', '$ow|P1'),
            destinationProvinceId: '$ow|P2',
          ),
          game,
          'p1',
          [],
          view,
          topology,
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, contains('declare war'));
      },
    );

    test('civilian worker cannot move into Minor/Tribe territory', () {
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
                type: kUnitTypeBuilder,
                ownerId: 'p1',
                locationProvinceId: '$ow|P1',
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
      const validator = MoveValidator();
      final result = validator.validate(
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
        game,
        'p1',
        moveValidatorTestContext(game, topology, 'p1'),
        [],
        topology,
        previousRejected: false,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, contains('Invalid move'));
    });
  });
}
