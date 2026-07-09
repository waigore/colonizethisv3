// Compact MoveValidator / ArmyMoveValidator expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'move_validator_test_support.dart';

const mvMinor1 = MinorNation(id: 'minor1', displayName: 'Minor');

const mvMinor1Capital = MinorNation(
  id: 'minor1',
  displayName: 'Minor1',
  capitalProvinceId: 'oldWorld|P2',
);

const mvTribe1Capital = Tribe(
  id: 'tribe1',
  displayName: 'Tribe1',
  capitalProvinceId: 'newWorld|P2',
);

MapTopology mvOwNwProvinceTopology() => const MapTopology(
  nodes: [
    TopologyNode(id: 'P1', regionId: 'oldWorld', type: TopologyNodeType.province),
    TopologyNode(id: 'P2', regionId: 'newWorld', type: TopologyNodeType.province),
  ],
  edges: [],
);

MapTopology mvNwTwoProvinceTopology() => const MapTopology(
  nodes: [
    TopologyNode(id: 'P1', regionId: 'newWorld', type: TopologyNodeType.province),
    TopologyNode(id: 'P2', regionId: 'newWorld', type: TopologyNodeType.province),
  ],
  edges: [TopologyEdge(id1: 'P1', id2: 'P2')],
);

Game mvTribeArmyDeclareWarGame() => Game(
  id: 'g1',
  worldState: WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
    oldWorld: const RegionData(),
    newWorld: RegionData(
      provinces: [
        Province(id: 'newWorld|P1', regionId: 'newWorld', ownerId: 'p1'),
        Province(id: 'newWorld|P2', regionId: 'newWorld', ownerId: 'tribe1'),
      ],
      units: [
        Unit(
          id: 'u1',
          type: 'pikemen',
          ownerId: 'p1',
          locationProvinceId: 'newWorld|P1',
        ),
      ],
    ),
    armies: [moveValidatorTestFieldArmy('newWorld', 'p1', 'P1', 'u1')],
    playerVisibilityByTile: const {
      'p1': {
        'newWorld|P1|0|0': 'fullyVisible',
        'newWorld|P2|0|0': 'fogged',
      },
    },
  ),
  players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
  tribes: const [mvTribe1Capital],
  diplomacyRelations: const [],
);

void mvExpectUnitMove({
  required Game game,
  required MapTopology topology,
  required String unitId,
  required String destinationTileKey,
  bool previousRejected = false,
  required OrderValidationStatus status,
  String? reasonExact,
  Matcher? reasonContains,
}) {
  const validator = MoveValidator();
  final result = validator.validate(
    MoveOrder(unitId: unitId, destinationTileKey: destinationTileKey),
    game,
    'p1',
    moveValidatorTestContext(game, topology, 'p1'),
    const [],
    topology,
    previousRejected: previousRejected,
  );
  expect(result.status, status);
  if (reasonExact != null) {
    expect(result.reason, reasonExact);
  }
  if (reasonContains != null) {
    expect(result.reason, reasonContains);
  }
}

void mvExpectArmyMove({
  required Game game,
  required MapTopology topology,
  required String armyProvinceId,
  required String destinationProvinceId,
  List<DiplomaticOrder> draftOrders = const [],
  required OrderValidationStatus status,
  String? reasonExact,
  Matcher? reasonContains,
  List<Matcher>? reasonContainsAll,
}) {
  final view = buildPlayerView(game, topology, 'p1');
  const validator = ArmyMoveValidator();
  final result = validator.validate(
    ArmyMoveOrder(
      armyId: fieldArmyIdFor('p1', armyProvinceId),
      destinationProvinceId: destinationProvinceId,
    ),
    game,
    'p1',
    draftOrders,
    view,
    topology,
  );
  expect(result.status, status);
  if (reasonExact != null) {
    expect(result.reason, reasonExact);
  }
  if (reasonContains != null) {
    expect(result.reason, reasonContains);
  }
  for (final matcher in reasonContainsAll ?? const <Matcher>[]) {
    expect(result.reason, matcher);
  }
}
