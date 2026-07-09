part of 'move_validator_expectations.dart';

void _civilianCannotMoveIntoOtherGp() {
        final game = _twoProvinceUnitGame(
          unitType: kUnitTypeBuilder,
          unitId: 'u1',
          destOwnerId: 'p2',
          includeP2Player: true,
        );
        final result = _validateUnitMove(
          game: game,
          topology: owTopology,
          unitId: 'u1',
          destinationTileKey: '$_ow|P2|0|0',
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, contains('Invalid move'));
}

void _militaryRegimentMoveOrderRejected() {
        final game = _twoProvinceUnitGame(
          unitType: 'pikemen',
          unitId: 'u1',
          destOwnerId: 'p2',
          includeP2Player: true,
        );
        final result = _validateUnitMove(
          game: game,
          topology: owTopology,
          unitId: 'u1',
          destinationTileKey: '$_ow|P2|0|0',
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, contains('army move'));
}

void _armyMoveIntoOtherGpWithoutWar() {
        final game = _twoProvinceArmyGame(
          destOwnerId: 'p2',
          includeP2Player: true,
        );
        final result = _validateArmyMove(
          game: game,
          topology: owTopology,
          armyProvinceId: '$_ow|P1',
          destinationProvinceId: '$_ow|P2',
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, contains('declare war'));
}

void _civilianWorkerCannotMoveIntoMinor() {
        final game = _twoProvinceUnitGame(
          unitType: kUnitTypeBuilder,
          unitId: 'u1',
          destOwnerId: 'minor1',
          minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
        );
        final result = _validateUnitMove(
          game: game,
          topology: owTopology,
          unitId: 'u1',
          destinationTileKey: '$_ow|P2|0|0',
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, contains('Invalid move'));
}

void _explorerOntoMinor() {
        final game = _twoProvinceUnitGame(
          unitType: kUnitTypeExplorer,
          unitId: 'u1',
          destOwnerId: 'minor1',
          unitTileKey: '$_ow|P1|0|0',
          minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
        );
        final result = _validateUnitMove(
          game: game,
          topology: owTopology,
          unitId: 'u1',
          destinationTileKey: '$_ow|P2|0|0',
        );
        expect(result.status, OrderValidationStatus.accepted);
}

void _spyOntoOtherGp() {
        final game = _twoProvinceUnitGame(
          unitType: kUnitTypeSpy,
          unitId: 's1',
          destOwnerId: 'p2',
          includeP2Player: true,
          unitTileKey: '$_ow|P1|0|0',
        );
        final result = _validateUnitMove(
          game: game,
          topology: owTopology,
          unitId: 's1',
          destinationTileKey: '$_ow|P2|0|0',
        );
        expect(result.status, OrderValidationStatus.accepted);
}

void _explorerCrossRegionTribe() {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(id: 'P1', regionId: _ow, type: TopologyNodeType.province),
            TopologyNode(id: 'P2', regionId: _nw, type: TopologyNodeType.province),
          ],
          edges: const [],
        );
        final game = _crossRegionTribeGame(unitType: kUnitTypeExplorer);
        final result = _validateUnitMove(
          game: game,
          topology: topology,
          unitId: 'u1',
          destinationTileKey: '$_nw|P2|0|0',
        );
        expect(result.status, OrderValidationStatus.accepted);
}

