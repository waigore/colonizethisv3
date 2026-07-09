part of 'move_validator_expectations.dart';

void _civilianCannotMoveIntoOtherGp() {
  mvExpectUnitMove(
    game: mvTwoProvinceUnitGame(
      unitType: kUnitTypeBuilder,
      unitId: 'u1',
      destOwnerId: 'p2',
      includeP2Player: true,
    ),
    topology: mvOwTopology,
    unitId: 'u1',
    destinationTileKey: '$mvOw|P2|0|0',
    status: OrderValidationStatus.rejected,
    reasonContains: contains('Invalid move'),
  );
}

void _militaryRegimentMoveOrderRejected() {
  mvExpectUnitMove(
    game: mvTwoProvinceUnitGame(
      unitType: 'pikemen',
      unitId: 'u1',
      destOwnerId: 'p2',
      includeP2Player: true,
    ),
    topology: mvOwTopology,
    unitId: 'u1',
    destinationTileKey: '$mvOw|P2|0|0',
    status: OrderValidationStatus.rejected,
    reasonContains: contains('army move'),
  );
}

void _armyMoveIntoOtherGpWithoutWar() {
  mvExpectArmyMove(
    game: mvTwoProvinceArmyGame(destOwnerId: 'p2', includeP2Player: true),
    topology: mvOwTopology,
    armyProvinceId: '$mvOw|P1',
    destinationProvinceId: '$mvOw|P2',
    status: OrderValidationStatus.rejected,
    reasonContains: contains('declare war'),
  );
}

void _civilianWorkerCannotMoveIntoMinor() {
  mvExpectUnitMove(
    game: mvTwoProvinceUnitGame(
      unitType: kUnitTypeBuilder,
      unitId: 'u1',
      destOwnerId: 'minor1',
      minorNations: const [mvMinor1],
    ),
    topology: mvOwTopology,
    unitId: 'u1',
    destinationTileKey: '$mvOw|P2|0|0',
    status: OrderValidationStatus.rejected,
    reasonContains: contains('Invalid move'),
  );
}

void _explorerOntoMinor() {
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
    destinationTileKey: '$mvOw|P2|0|0',
    status: OrderValidationStatus.accepted,
  );
}

void _spyOntoOtherGp() {
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
    destinationTileKey: '$mvOw|P2|0|0',
    status: OrderValidationStatus.accepted,
  );
}

void _explorerCrossRegionTribe() {
  mvExpectUnitMove(
    game: mvCrossRegionTribeGame(unitType: kUnitTypeExplorer),
    topology: mvOwNwProvinceTopology(),
    unitId: 'u1',
    destinationTileKey: '$mvNw|P2|0|0',
    status: OrderValidationStatus.accepted,
  );
}
