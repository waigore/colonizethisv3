// Compact MoveValidator / ArmyMoveValidator assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'move_validator_fixtures.dart';
import 'move_validator_test_support.dart';
import 'move_validator_expectation_shorthand.dart';

/// Pins for [moveValidatorScenarios] rows.
enum MoveValidatorTarget {
  civilianCannotMoveIntoOtherGp,
  militaryRegimentMoveOrderRejected,
  armyMoveIntoOtherGpWithoutWar,
  civilianWorkerCannotMoveIntoMinor,
  explorerOntoMinor,
  spyOntoOtherGp,
  explorerCrossRegionTribe,
  builderCrossRegionTribeInvalid,
  shortCircuitPreviousRejected,
  armyMoveIntoMinorWithoutWar,
  armyMoveIntoGpWithDeclareWar,
  armyMoveIntoMinorWithDeclareWar,
  armyMoveIntoTribeWithDeclareWar,
  armyMoveIntoMinorTribeWithoutWar,
}

void runMoveValidatorExpectation(MoveValidatorTarget target) {
  switch (target) {
    case MoveValidatorTarget.civilianCannotMoveIntoOtherGp:
        mvExpectUnitMove(
          game: mvTwoProvinceUnitGame(
            unitType: kUnitTypeBuilder,
            unitId: 'u1',
            destOwnerId: 'p2',
            includeP2Player: true,
          ),
          topology: mvOwTopology,
          unitId: 'u1',
          destinationTileKey: mvDestTile,
          status: OrderValidationStatus.rejected,
          reasonContains: contains('Invalid move'),
        );
    case MoveValidatorTarget.militaryRegimentMoveOrderRejected:
        mvExpectUnitMove(
          game: mvTwoProvinceUnitGame(
            unitType: 'pikemen',
            unitId: 'u1',
            destOwnerId: 'p2',
            includeP2Player: true,
          ),
          topology: mvOwTopology,
          unitId: 'u1',
          destinationTileKey: mvDestTile,
          status: OrderValidationStatus.rejected,
          reasonContains: contains('army move'),
        );
    case MoveValidatorTarget.armyMoveIntoOtherGpWithoutWar:
        mvExpectArmyMove(
          game: mvTwoProvinceArmyGame(destOwnerId: 'p2', includeP2Player: true),
          topology: mvOwTopology,
          armyProvinceId: '$mvOw|P1',
          destinationProvinceId: '$mvOw|P2',
          status: OrderValidationStatus.rejected,
          reasonContains: contains('declare war'),
        );
    case MoveValidatorTarget.civilianWorkerCannotMoveIntoMinor:
        mvExpectUnitMove(
          game: mvTwoProvinceUnitGame(
            unitType: kUnitTypeBuilder,
            unitId: 'u1',
            destOwnerId: 'minor1',
            minorNations: const [mvMinor1],
          ),
          topology: mvOwTopology,
          unitId: 'u1',
          destinationTileKey: mvDestTile,
          status: OrderValidationStatus.rejected,
          reasonContains: contains('Invalid move'),
        );
    case MoveValidatorTarget.explorerOntoMinor:
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
          destinationTileKey: mvDestTile,
          status: OrderValidationStatus.accepted,
        );
    case MoveValidatorTarget.spyOntoOtherGp:
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
          destinationTileKey: mvDestTile,
          status: OrderValidationStatus.accepted,
        );
    case MoveValidatorTarget.explorerCrossRegionTribe:
        mvExpectUnitMove(
          game: mvCrossRegionTribeGame(unitType: kUnitTypeExplorer),
          topology: mvOwNwProvinceTopology(),
          unitId: 'u1',
          destinationTileKey: '$mvNw|P2|0|0',
          status: OrderValidationStatus.accepted,
        );
    case MoveValidatorTarget.builderCrossRegionTribeInvalid:
        mvExpectUnitMove(
          game: mvCrossRegionTribeGame(unitType: kUnitTypeBuilder),
          topology: mvOwNwProvinceTopology(),
          unitId: 'u1',
          destinationTileKey: '$mvNw|P2|0|0',
          status: OrderValidationStatus.rejected,
          reasonExact: 'Invalid move',
        );
    case MoveValidatorTarget.shortCircuitPreviousRejected:
        mvExpectUnitMove(
          game: mvTwoProvinceUnitGame(
            unitType: kUnitTypeBuilder,
            unitId: 'u1',
            destOwnerId: 'p1',
          ),
          topology: mvOwTopology,
          unitId: 'u1',
          destinationTileKey: mvDestTile,
          previousRejected: true,
          status: OrderValidationStatus.rejected,
          reasonExact: 'Previous invalid',
        );
    case MoveValidatorTarget.armyMoveIntoMinorWithoutWar:
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
    case MoveValidatorTarget.armyMoveIntoGpWithDeclareWar:
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
    case MoveValidatorTarget.armyMoveIntoMinorWithDeclareWar:
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
    case MoveValidatorTarget.armyMoveIntoTribeWithDeclareWar:
        mvExpectArmyMove(
          game: Game(
            id: 'g1',
            worldState: WorldState(
              turnState: const TurnState(
                phase: TurnPhase.orders,
                turnNumber: 0,
              ),
              oldWorld: const RegionData(),
              newWorld: RegionData(
                provinces: [
                  Province(
                    id: 'newWorld|P1',
                    regionId: 'newWorld',
                    ownerId: 'p1',
                  ),
                  Province(
                    id: 'newWorld|P2',
                    regionId: 'newWorld',
                    ownerId: 'tribe1',
                  ),
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
              armies: [
                moveValidatorTestFieldArmy('newWorld', 'p1', 'P1', 'u1'),
              ],
              playerVisibilityByTile: const {
                'p1': {
                  'newWorld|P1|0|0': 'fullyVisible',
                  'newWorld|P2|0|0': 'fogged',
                },
              },
            ),
            players: const [
              Player(id: 'p1', displayName: 'P1', isHuman: true),
            ],
            tribes: const [mvTribe1Capital],
            diplomacyRelations: const [],
          ),
          topology: const MapTopology(
            nodes: [
              TopologyNode(
                id: 'P1',
                regionId: 'newWorld',
                type: TopologyNodeType.province,
              ),
              TopologyNode(
                id: 'P2',
                regionId: 'newWorld',
                type: TopologyNodeType.province,
              ),
            ],
            edges: [TopologyEdge(id1: 'P1', id2: 'P2')],
          ),
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
    case MoveValidatorTarget.armyMoveIntoMinorTribeWithoutWar:
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
}
