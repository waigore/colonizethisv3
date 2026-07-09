part of 'move_validator_expectations.dart';

void _civilianCannotMoveIntoOtherGp() {
  mvExpectUnitMove(
    game: _twoProvinceUnitGame(
      unitType: kUnitTypeBuilder,
      unitId: 'u1',
      destOwnerId: 'p2',
      includeP2Player: true,
    ),
    topology: owTopology,
    unitId: 'u1',
    destinationTileKey: '$_ow|P2|0|0',
    status: OrderValidationStatus.rejected,
    reasonContains: contains('Invalid move'),
  );
}

void _militaryRegimentMoveOrderRejected() {
  mvExpectUnitMove(
    game: _twoProvinceUnitGame(
      unitType: 'pikemen',
      unitId: 'u1',
      destOwnerId: 'p2',
      includeP2Player: true,
    ),
    topology: owTopology,
    unitId: 'u1',
    destinationTileKey: '$_ow|P2|0|0',
    status: OrderValidationStatus.rejected,
    reasonContains: contains('army move'),
  );
}

void _armyMoveIntoOtherGpWithoutWar() {
  mvExpectArmyMove(
    game: _twoProvinceArmyGame(destOwnerId: 'p2', includeP2Player: true),
    topology: owTopology,
    armyProvinceId: '$_ow|P1',
    destinationProvinceId: '$_ow|P2',
    status: OrderValidationStatus.rejected,
    reasonContains: contains('declare war'),
  );
}

void _civilianWorkerCannotMoveIntoMinor() {
  mvExpectUnitMove(
    game: _twoProvinceUnitGame(
      unitType: kUnitTypeBuilder,
      unitId: 'u1',
      destOwnerId: 'minor1',
      minorNations: const [mvMinor1],
    ),
    topology: owTopology,
    unitId: 'u1',
    destinationTileKey: '$_ow|P2|0|0',
    status: OrderValidationStatus.rejected,
    reasonContains: contains('Invalid move'),
  );
}

void _explorerOntoMinor() {
  mvExpectUnitMove(
    game: _twoProvinceUnitGame(
      unitType: kUnitTypeExplorer,
      unitId: 'u1',
      destOwnerId: 'minor1',
      unitTileKey: '$_ow|P1|0|0',
      minorNations: const [mvMinor1],
    ),
    topology: owTopology,
    unitId: 'u1',
    destinationTileKey: '$_ow|P2|0|0',
    status: OrderValidationStatus.accepted,
  );
}

void _spyOntoOtherGp() {
  mvExpectUnitMove(
    game: _twoProvinceUnitGame(
      unitType: kUnitTypeSpy,
      unitId: 's1',
      destOwnerId: 'p2',
      includeP2Player: true,
      unitTileKey: '$_ow|P1|0|0',
    ),
    topology: owTopology,
    unitId: 's1',
    destinationTileKey: '$_ow|P2|0|0',
    status: OrderValidationStatus.accepted,
  );
}

void _explorerCrossRegionTribe() {
  mvExpectUnitMove(
    game: _crossRegionTribeGame(unitType: kUnitTypeExplorer),
    topology: mvOwNwProvinceTopology(),
    unitId: 'u1',
    destinationTileKey: '$_nw|P2|0|0',
    status: OrderValidationStatus.accepted,
  );
}
