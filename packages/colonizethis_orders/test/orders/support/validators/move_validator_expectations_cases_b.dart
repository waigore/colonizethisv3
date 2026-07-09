part of 'move_validator_expectations.dart';

void _builderCrossRegionTribeInvalid() {
        final topology = MapTopology(
          nodes: const [
            TopologyNode(id: 'P1', regionId: _ow, type: TopologyNodeType.province),
            TopologyNode(id: 'P2', regionId: _nw, type: TopologyNodeType.province),
          ],
          edges: const [],
        );
        final game = _crossRegionTribeGame(unitType: kUnitTypeBuilder);
        final result = _validateUnitMove(
          game: game,
          topology: topology,
          unitId: 'u1',
          destinationTileKey: '$_nw|P2|0|0',
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Invalid move');
}

void _shortCircuitPreviousRejected() {
        final game = _twoProvinceUnitGame(
          unitType: kUnitTypeBuilder,
          unitId: 'u1',
          destOwnerId: 'p1',
        );
        final result = _validateUnitMove(
          game: game,
          topology: owTopology,
          unitId: 'u1',
          destinationTileKey: '$_ow|P2|0|0',
          previousRejected: true,
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, 'Previous invalid');
}

void _armyMoveIntoMinorWithoutWar() {
        final game = _twoProvinceArmyGame(
          destOwnerId: 'minor1',
          minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
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

void _armyMoveIntoGpWithDeclareWar() {
        final game = _twoProvinceArmyGame(
          destOwnerId: 'p2',
          includeP2Player: true,
        );
        final result = _validateArmyMove(
          game: game,
          topology: owTopology,
          armyProvinceId: '$_ow|P1',
          destinationProvinceId: '$_ow|P2',
          draftOrders: const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'p2',
            ),
          ],
        );
        expect(result.status, OrderValidationStatus.accepted);
}

void _armyMoveIntoMinorWithDeclareWar() {
        final game = _twoProvinceArmyGame(
          destOwnerId: 'minor1',
          minorNations: const [
            MinorNation(
              id: 'minor1',
              displayName: 'Minor1',
              capitalProvinceId: 'oldWorld|P2',
            ),
          ],
        );
        final result = _validateArmyMove(
          game: game,
          topology: owTopology,
          armyProvinceId: '$_ow|P1',
          destinationProvinceId: '$_ow|P2',
          draftOrders: const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'minor1',
            ),
          ],
        );
        expect(result.status, OrderValidationStatus.accepted);
}

void _armyMoveIntoTribeWithDeclareWar() {
        final nwTopology = MapTopology(
          nodes: const [
            TopologyNode(id: 'P1', regionId: _nw, type: TopologyNodeType.province),
            TopologyNode(id: 'P2', regionId: _nw, type: TopologyNodeType.province),
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
                Province(id: '$_nw|P1', regionId: _nw, ownerId: 'p1'),
                Province(id: '$_nw|P2', regionId: _nw, ownerId: 'tribe1'),
              ],
              units: [
                Unit(
                  id: 'u1',
                  type: 'pikemen',
                  ownerId: 'p1',
                  locationProvinceId: '$_nw|P1',
                ),
              ],
            ),
            armies: [moveValidatorTestFieldArmy(_nw, 'p1', 'P1', 'u1')],
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
        final result = _validateArmyMove(
          game: game,
          topology: nwTopology,
          armyProvinceId: '$_nw|P1',
          destinationProvinceId: '$_nw|P2',
          draftOrders: const [
            DiplomaticOrder(
              type: DiplomaticOrderType.declareWar,
              targetFactionId: 'tribe1',
            ),
          ],
        );
        expect(result.status, OrderValidationStatus.accepted);
}

void _armyMoveIntoMinorTribeWithoutWar() {
        final game = _twoProvinceArmyGame(
          destOwnerId: 'minor1',
          minorNations: const [
            MinorNation(
              id: 'minor1',
              displayName: 'Minor1',
              capitalProvinceId: 'oldWorld|P2',
            ),
          ],
          tribes: const [],
        );
        final result = _validateArmyMove(
          game: game,
          topology: owTopology,
          armyProvinceId: '$_ow|P1',
          destinationProvinceId: '$_ow|P2',
        );
        expect(result.status, OrderValidationStatus.rejected);
        expect(result.reason, contains('declare war'));
        expect(result.reason, contains('Minor Nation or Tribe'));
}

