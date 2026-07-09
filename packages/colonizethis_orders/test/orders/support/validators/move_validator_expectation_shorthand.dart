// Compact MoveValidator / ArmyMoveValidator expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'move_validator_fixtures.dart';
import 'move_validator_test_support.dart';

const mvMinor1 = MinorNation(id: 'minor1', displayName: 'Minor');

const _mvDestTile = '$mvOw|P2|0|0';

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

void mvExpectBuilderCannotEnterGp() {
  mvExpectUnitMove(
    game: mvTwoProvinceUnitGame(
      unitType: kUnitTypeBuilder,
      unitId: 'u1',
      destOwnerId: 'p2',
      includeP2Player: true,
    ),
    topology: mvOwTopology,
    unitId: 'u1',
    destinationTileKey: _mvDestTile,
    status: OrderValidationStatus.rejected,
    reasonContains: contains('Invalid move'),
  );
}

void mvExpectMilitaryRegimentRejected() {
  mvExpectUnitMove(
    game: mvTwoProvinceUnitGame(
      unitType: 'pikemen',
      unitId: 'u1',
      destOwnerId: 'p2',
      includeP2Player: true,
    ),
    topology: mvOwTopology,
    unitId: 'u1',
    destinationTileKey: _mvDestTile,
    status: OrderValidationStatus.rejected,
    reasonContains: contains('army move'),
  );
}

void mvExpectArmyIntoGpNoWar() {
  mvExpectArmyMove(
    game: mvTwoProvinceArmyGame(destOwnerId: 'p2', includeP2Player: true),
    topology: mvOwTopology,
    armyProvinceId: '$mvOw|P1',
    destinationProvinceId: '$mvOw|P2',
    status: OrderValidationStatus.rejected,
    reasonContains: contains('declare war'),
  );
}

void mvExpectBuilderCannotEnterMinor() {
  mvExpectUnitMove(
    game: mvTwoProvinceUnitGame(
      unitType: kUnitTypeBuilder,
      unitId: 'u1',
      destOwnerId: 'minor1',
      minorNations: const [mvMinor1],
    ),
    topology: mvOwTopology,
    unitId: 'u1',
    destinationTileKey: _mvDestTile,
    status: OrderValidationStatus.rejected,
    reasonContains: contains('Invalid move'),
  );
}

void mvExpectExplorerOntoMinor() {
  mvExpectUnitMove(
    game: mvTwoProvinceUnitGame(
      unitType: kUnitTypeExplorer,
      unitId: 'u1',
      destOwnerId: 'minor1',
      unitTileKey: '$mvOw|P1|0|0',
      minorNations: const [mvMinor1],
    ),
    topology: mvOwTopology,
    unitId: 'u1',
    destinationTileKey: _mvDestTile,
    status: OrderValidationStatus.accepted,
  );
}

void mvExpectSpyOntoOtherGp() {
  mvExpectUnitMove(
    game: mvTwoProvinceUnitGame(
      unitType: kUnitTypeSpy,
      unitId: 's1',
      destOwnerId: 'p2',
      includeP2Player: true,
      unitTileKey: '$mvOw|P1|0|0',
    ),
    topology: mvOwTopology,
    unitId: 's1',
    destinationTileKey: _mvDestTile,
    status: OrderValidationStatus.accepted,
  );
}

void mvExpectExplorerCrossRegionTribe() {
  mvExpectUnitMove(
    game: mvCrossRegionTribeGame(unitType: kUnitTypeExplorer),
    topology: mvOwNwProvinceTopology(),
    unitId: 'u1',
    destinationTileKey: '$mvNw|P2|0|0',
    status: OrderValidationStatus.accepted,
  );
}

void mvExpectBuilderCrossRegionTribeInvalid() {
  mvExpectUnitMove(
    game: mvCrossRegionTribeGame(unitType: kUnitTypeBuilder),
    topology: mvOwNwProvinceTopology(),
    unitId: 'u1',
    destinationTileKey: '$mvNw|P2|0|0',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid move',
  );
}

void mvExpectShortCircuitPreviousRejected() {
  mvExpectUnitMove(
    game: mvTwoProvinceUnitGame(
      unitType: kUnitTypeBuilder,
      unitId: 'u1',
      destOwnerId: 'p1',
    ),
    topology: mvOwTopology,
    unitId: 'u1',
    destinationTileKey: _mvDestTile,
    previousRejected: true,
    status: OrderValidationStatus.rejected,
    reasonExact: 'Previous invalid',
  );
}

void mvExpectArmyIntoMinorNoWar() {
  mvExpectArmyMove(
    game: mvTwoProvinceArmyGame(
      destOwnerId: 'minor1',
      minorNations: const [mvMinor1],
    ),
    topology: mvOwTopology,
    armyProvinceId: '$mvOw|P1',
    destinationProvinceId: '$mvOw|P2',
    status: OrderValidationStatus.rejected,
    reasonContains: contains('declare war'),
  );
}

void mvExpectArmyIntoGpWithDeclareWar() {
  mvExpectArmyMove(
    game: mvTwoProvinceArmyGame(destOwnerId: 'p2', includeP2Player: true),
    topology: mvOwTopology,
    armyProvinceId: '$mvOw|P1',
    destinationProvinceId: '$mvOw|P2',
    draftOrders: const [
      DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: 'p2',
      ),
    ],
    status: OrderValidationStatus.accepted,
  );
}

void mvExpectArmyIntoMinorWithDeclareWar() {
  mvExpectArmyMove(
    game: mvTwoProvinceArmyGame(
      destOwnerId: 'minor1',
      minorNations: const [mvMinor1Capital],
    ),
    topology: mvOwTopology,
    armyProvinceId: '$mvOw|P1',
    destinationProvinceId: '$mvOw|P2',
    draftOrders: const [
      DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: 'minor1',
      ),
    ],
    status: OrderValidationStatus.accepted,
  );
}

void mvExpectArmyIntoTribeWithDeclareWar() {
  mvExpectArmyMove(
    game: mvTribeArmyDeclareWarGame(),
    topology: mvNwTwoProvinceTopology(),
    armyProvinceId: '$mvNw|P1',
    destinationProvinceId: '$mvNw|P2',
    draftOrders: const [
      DiplomaticOrder(
        type: DiplomaticOrderType.declareWar,
        targetFactionId: 'tribe1',
      ),
    ],
    status: OrderValidationStatus.accepted,
  );
}

void mvExpectArmyIntoMinorTribeNoWar() {
  mvExpectArmyMove(
    game: mvTwoProvinceArmyGame(
      destOwnerId: 'minor1',
      minorNations: const [mvMinor1Capital],
    ),
    topology: mvOwTopology,
    armyProvinceId: '$mvOw|P1',
    destinationProvinceId: '$mvOw|P2',
    status: OrderValidationStatus.rejected,
    reasonContainsAll: [
      contains('declare war'),
      contains('Minor Nation or Tribe'),
    ],
  );
}
