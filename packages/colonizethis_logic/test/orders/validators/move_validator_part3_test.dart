import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'move_validator_test_support.dart';

void main() {
  group('MoveValidator', () {
    const ow = 'oldWorld';
    final topology = moveValidatorTestTwoProvinceTopology(ow);

    test('short-circuits when previous order rejected', () {
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$ow|P1', regionId: ow, ownerId: 'p1'),
              Province(id: '$ow|P2', regionId: ow, ownerId: 'p1'),
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
      );
      const validator = MoveValidator();
      final result = validator.validate(
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
        game,
        'p1',
        moveValidatorTestContext(game, topology, 'p1'),
        [],
        topology,
        previousRejected: true,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, 'Previous invalid');
    });

    test(
      'ArmyMoveValidator military cannot move into Minor province without war',
      () {
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
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
          minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
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

    test(
      'ArmyMoveValidator military may move into other GP province with same-turn declareWar',
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
          [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'p2',
            ),
          ],
          view,
          topology,
        );
        expect(result.status, OrderValidationStatus.accepted);
      },
    );

    test(
      'ArmyMoveValidator military may move into Minor province with same-turn declareWar',
      () {
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
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
          minorNations: const [
            MinorNation(
              id: 'minor1',
              displayName: 'Minor1',
              capitalProvinceId: 'oldWorld|P2',
            ),
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
          [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'minor1',
            ),
          ],
          view,
          topology,
        );
        expect(result.status, OrderValidationStatus.accepted);
      },
    );

    test(
      'ArmyMoveValidator military may move into Tribe province with same-turn declareWar',
      () {
        const nw = 'newWorld';
        final nwTopology = MapTopology(
          nodes: const [
            TopologyNode(
              id: 'P1',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
            TopologyNode(
              id: 'P2',
              regionId: nw,
              type: TopologyNodeType.province,
            ),
          ],
          edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
        );
        final game = Game(
          id: 'g1',
          worldState: WorldState(
            turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
            oldWorld: const RegionData(),
            newWorld: RegionData(
              provinces: [
                Province(id: '$nw|P1', regionId: nw, ownerId: 'p1'),
                Province(id: '$nw|P2', regionId: nw, ownerId: 'tribe1'),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: 'pikemen',
                  ownerId: 'p1',
                  locationProvinceId: '$nw|P1',
                ),
              ],
            ),
            armies: [moveValidatorTestFieldArmy(nw, 'p1', 'P1', 'u1')],
            playerVisibilityByTile: const {
              'p1': {
                'newWorld|P1|0|0': 'fullyVisible',
                'newWorld|P2|0|0': 'fogged',
              },
            },
          ),
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
          tribes: const [
            Tribe(
              id: 'tribe1',
              displayName: 'Tribe1',
              capitalProvinceId: 'newWorld|P2',
            ),
          ],
          diplomacyRelations: const [],
        );
        final view = buildPlayerView(game, nwTopology, 'p1');
        const validator = ArmyMoveValidator();
        final result = validator.validate(
          ArmyMoveOrder(
            armyId: fieldArmyIdFor('p1', '$nw|P1'),
            destinationProvinceId: '$nw|P2',
          ),
          game,
          'p1',
          [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'tribe1',
            ),
          ],
          view,
          nwTopology,
        );
        expect(result.status, OrderValidationStatus.accepted);
      },
    );

    test(
      'ArmyMoveValidator military cannot move into Minor/Tribe province without war',
      () {
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
          players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
          minorNations: const [
            MinorNation(
              id: 'minor1',
              displayName: 'Minor1',
              capitalProvinceId: 'oldWorld|P2',
            ),
          ],
          tribes: const [],
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
        expect(result.reason, contains('Minor Nation or Tribe'));
      },
    );
  });
}
