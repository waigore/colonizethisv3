// Table-driven MoveValidator / ArmyMoveValidator scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'move_validator_expectation_shorthand.dart';
import 'move_validator_fixtures.dart';
import 'move_validator_test_support.dart';

void mvRunCivilianCannotMoveIntoOtherGpTerritory() {
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
}

void mvRunMilitaryRegimentMoveOrderRejectedUseArmyMove() {
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
}

void mvRunArmyMoveIntoOtherGpProvinceWithoutWar() {
  mvExpectArmyMove(
    game: mvTwoProvinceArmyGame(destOwnerId: 'p2', includeP2Player: true),
    topology: mvOwTopology,
    armyProvinceId: '$mvOw|P1',
    destinationProvinceId: '$mvOw|P2',
    status: OrderValidationStatus.rejected,
    reasonContains: contains('declare war'),
  );
}

void mvRunCivilianWorkerCannotMoveIntoMinorTribeTerritory() {
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
}

void mvRunExplorerMayMoveOntoMinorProvinceTile() {
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
}

void mvRunSpyMayMoveOntoOtherGreatPowerProvinceTileWithoutDeclareWar() {
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
}

void mvRunExplorerCanMoveCrossRegionIntoTribeOwnedProvince() {
  mvExpectUnitMove(
    game: mvCrossRegionTribeGame(unitType: kUnitTypeExplorer),
    topology: mvOwNwProvinceTopology(),
    unitId: 'u1',
    destinationTileKey: '$mvNw|P2|0|0',
    status: OrderValidationStatus.accepted,
  );
}

void mvRunBuilderCrossRegionIntoTribeOwnedProvinceStillInvalid() {
  mvExpectUnitMove(
    game: mvCrossRegionTribeGame(unitType: kUnitTypeBuilder),
    topology: mvOwNwProvinceTopology(),
    unitId: 'u1',
    destinationTileKey: '$mvNw|P2|0|0',
    status: OrderValidationStatus.rejected,
    reasonExact: 'Invalid move',
  );
}

void mvRunShortCircuitsWhenPreviousOrderRejected() {
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
}

void mvRunArmyMoveIntoMinorProvinceWithoutWar() {
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

void mvRunArmyMoveIntoOtherGpProvinceWithSameTurnDeclareWar() {
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

void mvRunArmyMoveIntoMinorProvinceWithSameTurnDeclareWar() {
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

void mvRunArmyMoveIntoTribeProvinceWithSameTurnDeclareWar() {
  mvExpectArmyMove(
    game: Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: const RegionData(),
        newWorld: RegionData(
          provinces: [
            Province(id: 'newWorld|P1', regionId: 'newWorld', ownerId: 'p1'),
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
}

void mvRunArmyMoveIntoMinorTribeProvinceWithoutWar() {
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

/// Canonical scenarios for [MoveValidator] / [ArmyMoveValidator] family tests.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] entries and former
/// `move_validator_part*_test.dart` descriptions (single-line `label:` for CI).
List<RunnableScenario> moveValidatorScenarios() => [
  rs('civilian cannot move into other GP territory', mvRunCivilianCannotMoveIntoOtherGpTerritory),
  rs('military regiment MoveOrder is rejected; use army move', mvRunMilitaryRegimentMoveOrderRejectedUseArmyMove),
  rs('ArmyMoveValidator military cannot move into other GP province without war', mvRunArmyMoveIntoOtherGpProvinceWithoutWar),
  rs('civilian worker cannot move into Minor/Tribe territory', mvRunCivilianWorkerCannotMoveIntoMinorTribeTerritory),
  rs('Explorer may move onto Minor province tile (cross-region style)', mvRunExplorerMayMoveOntoMinorProvinceTile),
  rs('Spy may move onto other Great Power province tile without declare war', mvRunSpyMayMoveOntoOtherGreatPowerProvinceTileWithoutDeclareWar),
  rs('explorer can move cross-region into tribe-owned province', mvRunExplorerCanMoveCrossRegionIntoTribeOwnedProvince),
  rs('builder cross-region into tribe-owned province is still invalid', mvRunBuilderCrossRegionIntoTribeOwnedProvinceStillInvalid),
  rs('short-circuits when previous order rejected', mvRunShortCircuitsWhenPreviousOrderRejected),
  rs('ArmyMoveValidator military cannot move into Minor province without war', mvRunArmyMoveIntoMinorProvinceWithoutWar),
  rs('ArmyMoveValidator military may move into other GP province with same-turn declareWar', mvRunArmyMoveIntoOtherGpProvinceWithSameTurnDeclareWar),
  rs('ArmyMoveValidator military may move into Minor province with same-turn declareWar', mvRunArmyMoveIntoMinorProvinceWithSameTurnDeclareWar),
  rs('ArmyMoveValidator military may move into Tribe province with same-turn declareWar', mvRunArmyMoveIntoTribeProvinceWithSameTurnDeclareWar),
  rs('ArmyMoveValidator military cannot move into Minor/Tribe province without war', mvRunArmyMoveIntoMinorTribeProvinceWithoutWar),
];
