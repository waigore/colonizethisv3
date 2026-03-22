import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_logic/src/orders/validators/move_validator.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

void main() {
  group('MoveValidator', () {
    const ow = 'oldWorld';
    final topology = MapTopology(
      nodes: const [
        TopologyNode(id: 'P1', regionId: ow, type: TopologyNodeType.province),
        TopologyNode(id: 'P2', regionId: ow, type: TopologyNodeType.province),
      ],
      edges: const [TopologyEdge(id1: 'P1', id2: 'P2')],
    );

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
                  type: 'Builder',
                  ownerId: 'p1',
                  locationProvinceId: '$ow|P1'),
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
      final unitsById = {for (final u in game.worldState.oldWorld.units) u.id: u};
      final view = buildPlayerView(game, topology, 'p1');
      const validator = MoveValidator();
      final result = validator.validate(
        const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'),
        game,
        'p1',
        unitsById,
        [],
        view,
        topology,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, contains('Civilian cannot enter other Great Power'));
    });

    test('military cannot move into other GP province without war', () {
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
                  locationProvinceId: '$ow|P1'),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'revealed',
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
        const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'),
        game,
        'p1',
        unitsById,
        [],
        view,
        topology,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, contains('declare war'));
    });

    test('civilian cannot move into Minor/Tribe territory', () {
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
              Unit(id: 'u1', type: 'Builder', ownerId: 'p1', locationProvinceId: '$ow|P1'),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'revealed',
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
        const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'),
        game,
        'p1',
        unitsById,
        [],
        view,
        topology,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, contains('Civilian cannot enter Minor'));
    });

    test('military cannot move into Minor province without war', () {
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
              Unit(id: 'u1', type: 'pikemen', ownerId: 'p1', locationProvinceId: '$ow|P1'),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'revealed',
            },
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
        diplomacyRelations: const [],
      );
      final unitsById = {for (final u in game.worldState.oldWorld.units) u.id: u};
      final view = buildPlayerView(game, topology, 'p1');
      const validator = MoveValidator();
      final result = validator.validate(
        const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'),
        game,
        'p1',
        unitsById,
        [],
        view,
        topology,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, contains('declare war'));
    });

    test('military may move into other GP province with same-turn declareWar', () {
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
                  locationProvinceId: '$ow|P1'),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'revealed',
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
        const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'),
        game,
        'p1',
        unitsById,
        [
          DiplomaticOrder(
              type: DiplomaticOrderType.declareWar, targetFactionId: 'p2'),
        ],
        view,
        topology,
      );
      expect(result.status, OrderValidationStatus.accepted);
    });

    test('military cannot move into Minor/Tribe province without war', () {
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
                  locationProvinceId: '$ow|P1'),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              'oldWorld|P2|0|0': 'revealed',
            },
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        minorNations: const [
          MinorNation(id: 'minor1', displayName: 'Minor1', capitalProvinceId: 'oldWorld|P2'),
        ],
        tribes: const [],
        diplomacyRelations: const [],
      );
      final unitsById = {for (final u in game.worldState.oldWorld.units) u.id: u};
      final view = buildPlayerView(game, topology, 'p1');
      const validator = MoveValidator();
      final result = validator.validate(
        const MoveOrder(unitId: 'u1', destinationProvinceId: 'oldWorld|P2'),
        game,
        'p1',
        unitsById,
        [],
        view,
        topology,
      );
      expect(result.status, OrderValidationStatus.rejected);
      expect(result.reason, contains('declare war'));
      expect(result.reason, contains('Minor Nation or Tribe'));
    });
  });
}
