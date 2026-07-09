part of 'move_validator_expectations.dart';

void _builderCrossRegionTribeInvalid() {
  mvExpectUnitMove(
    game: mvCrossRegionTribeGame(unitType: kUnitTypeBuilder),
    topology: mvOwNwProvinceTopology(),
    unitId: 'u1',
    destinationTileKey: '$mvNw|P2|0|0',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid move',
  );
}

void _shortCircuitPreviousRejected() {
  mvExpectUnitMove(
    game: mvTwoProvinceUnitGame(
      unitType: kUnitTypeBuilder,
      unitId: 'u1',
      destOwnerId: 'p1',
    ),
    topology: mvOwTopology,
    unitId: 'u1',
    destinationTileKey: '$mvOw|P2|0|0',
    previousRejected: true,
    status: OrderValidationStatus.rejected,
    reasonExact: 'Previous invalid',
  );
}

void _armyMoveIntoMinorWithoutWar() {
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

void _armyMoveIntoGpWithDeclareWar() {
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

void _armyMoveIntoMinorWithDeclareWar() {
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

void _armyMoveIntoTribeWithDeclareWar() {
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

void _armyMoveIntoMinorTribeWithoutWar() {
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
