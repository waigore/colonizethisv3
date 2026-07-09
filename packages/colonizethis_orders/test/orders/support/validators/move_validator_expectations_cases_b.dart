part of 'move_validator_expectations.dart';

void _builderCrossRegionTribeInvalid() {
  mvExpectUnitMove(
    game: _crossRegionTribeGame(unitType: kUnitTypeBuilder),
    topology: mvOwNwProvinceTopology(),
    unitId: 'u1',
    destinationTileKey: '$_nw|P2|0|0',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid move',
  );
}

void _shortCircuitPreviousRejected() {
  mvExpectUnitMove(
    game: _twoProvinceUnitGame(
      unitType: kUnitTypeBuilder,
      unitId: 'u1',
      destOwnerId: 'p1',
    ),
    topology: owTopology,
    unitId: 'u1',
    destinationTileKey: '$_ow|P2|0|0',
    previousRejected: true,
    status: OrderValidationStatus.rejected,
    reasonExact: 'Previous invalid',
  );
}

void _armyMoveIntoMinorWithoutWar() {
  mvExpectArmyMove(
    game: _twoProvinceArmyGame(
      destOwnerId: 'minor1',
      minorNations: const [mvMinor1],
    ),
    topology: owTopology,
    armyProvinceId: '$_ow|P1',
    destinationProvinceId: '$_ow|P2',
    status: OrderValidationStatus.rejected,
    reasonContains: contains('declare war'),
  );
}

void _armyMoveIntoGpWithDeclareWar() {
  mvExpectArmyMove(
    game: _twoProvinceArmyGame(destOwnerId: 'p2', includeP2Player: true),
    topology: owTopology,
    armyProvinceId: '$_ow|P1',
    destinationProvinceId: '$_ow|P2',
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
    game: _twoProvinceArmyGame(
      destOwnerId: 'minor1',
      minorNations: const [mvMinor1Capital],
    ),
    topology: owTopology,
    armyProvinceId: '$_ow|P1',
    destinationProvinceId: '$_ow|P2',
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
    armyProvinceId: '$_nw|P1',
    destinationProvinceId: '$_nw|P2',
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
    game: _twoProvinceArmyGame(
      destOwnerId: 'minor1',
      minorNations: const [mvMinor1Capital],
    ),
    topology: owTopology,
    armyProvinceId: '$_ow|P1',
    destinationProvinceId: '$_ow|P2',
    status: OrderValidationStatus.rejected,
    reasonContainsAll: [
      contains('declare war'),
      contains('Minor Nation or Tribe'),
    ],
  );
}
