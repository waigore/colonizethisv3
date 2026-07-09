// Compact OrderEngine move/work-context assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_engine_core_fixtures.dart';
import 'order_engine_move_and_work_context_expectation_shorthand.dart';
import 'order_engine_move_and_work_context_fixtures.dart';

/// Pins for [orderEngineMoveAndWorkContextScenarios] rows.
enum OrderEngineMoveAndWorkContextTarget {
  moveRejectedWhenDestinationProvinceUnknown,
  workExploreRejectedWhenProvinceUnknown,
  workExploreRejectedOnForeignGpTile,
  workProspectRejectedWhenProvinceNotFogged,
  workProspectRejectedWhenNotMineralEligible,
  workProspectAcceptedWhenMineralEligible,
  workProspectRejectedWithoutConsulate,
  workProspectRejectedOnForeignGpTile,
  moveRejectedWhenNotAdjacentNotOwn,
  civilianMoveAcceptedWhenNotAdjacentOwnProvince,
  workProspectRejectedWhenAlreadyProspected,
}

void runOrderEngineMoveAndWorkContextExpectation(
  OrderEngineMoveAndWorkContextTarget target,
) {
  switch (target) {
    case OrderEngineMoveAndWorkContextTarget
        .moveRejectedWhenDestinationProvinceUnknown:
      final topology = oecTwoProvinceTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$oemwcOw|P1', regionId: oemwcOw, ownerId: 'p1'),
              Province(id: '$oemwcOw|P2', regionId: oemwcOw, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$oemwcOw|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {'oldWorld|P1|0|0': 'fullyVisible'},
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      oemwcExpectMove(
        game,
        topology,
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
        status: OrderValidationStatus.rejected,
        reasonContains: 'visible',
      );

    case OrderEngineMoveAndWorkContextTarget
        .workExploreRejectedWhenProvinceUnknown:
      oemwcExpectWork(
        oemwcExplorerProvinceGame(tileVisibility: 'unknown'),
        oecSingleProvinceTopology(),
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetExplore,
          targetTileKey: oemwcTileP1,
        ),
        status: OrderValidationStatus.rejected,
        reasonContains: 'visible',
      );

    case OrderEngineMoveAndWorkContextTarget.workExploreRejectedOnForeignGpTile:
      const targetTileKey = 'oldWorld|P2|0|0';
      const p2OtherLand = 'oldWorld|P2|1|0';
      final topology = oecTwoProvinceTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$oemwcOw|P1', regionId: oemwcOw, ownerId: 'p1'),
              Province(id: '$oemwcOw|P2', regionId: oemwcOw, ownerId: 'p2'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$oemwcOw|P1',
                tileKey: oemwcTileP1,
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              oemwcTileP1: 'fullyVisible',
              targetTileKey: 'fullyVisible',
              p2OtherLand: 'unknown',
            },
          },
          tileKeysByRegionAndProvince: const {
            oemwcOw: {
              'oldWorld|P1': [oemwcTileP1],
              'oldWorld|P2': [targetTileKey, p2OtherLand],
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      );
      oemwcExpectWork(
        game,
        topology,
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetExplore,
          targetTileKey: targetTileKey,
        ),
        status: OrderValidationStatus.rejected,
        reasonContains: 'cannot occupy',
      );

    case OrderEngineMoveAndWorkContextTarget
        .workProspectRejectedWhenProvinceNotFogged:
      oemwcExpectWork(
        oemwcExplorerProvinceGame(
          tileVisibility: 'unknown',
          provinceOwnerId: 'tribe1',
          overtureStates: oemwcTribeConsulate,
        ),
        oecSingleProvinceTopology(),
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: oemwcTileP1,
        ),
        status: OrderValidationStatus.rejected,
        reasonContains: 'visible',
      );

    case OrderEngineMoveAndWorkContextTarget
        .workProspectRejectedWhenNotMineralEligible:
      oemwcExpectWork(
        oemwcExplorerProvinceGame(
          tileVisibility: 'fogged',
          provinceOwnerId: 'tribe1',
          resourceByTileKey: 'grain',
          overtureStates: oemwcTribeConsulate,
        ),
        oecSingleProvinceTopology(),
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: oemwcTileP1,
        ),
        status: OrderValidationStatus.rejected,
        reasonContains: 'mineral-eligible',
      );

    case OrderEngineMoveAndWorkContextTarget
        .workProspectAcceptedWhenMineralEligible:
      oemwcExpectWork(
        oemwcExplorerProvinceGame(
          tileVisibility: 'fogged',
          provinceOwnerId: 'tribe1',
          resourceByTileKey: 'iron',
          overtureStates: oemwcTribeConsulate,
        ),
        oecSingleProvinceTopology(),
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: oemwcTileP1,
        ),
        status: OrderValidationStatus.accepted,
      );

    case OrderEngineMoveAndWorkContextTarget
        .workProspectRejectedWithoutConsulate:
      oemwcExpectWork(
        oemwcExplorerProvinceGame(
          tileVisibility: 'fogged',
          provinceOwnerId: 'tribe1',
          resourceByTileKey: 'iron',
        ),
        oecSingleProvinceTopology(),
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: oemwcTileP1,
        ),
        status: OrderValidationStatus.rejected,
        reasonContains: 'Establish a consulate',
      );

    case OrderEngineMoveAndWorkContextTarget.workProspectRejectedOnForeignGpTile:
      const targetTileKey = 'oldWorld|P2|0|0';
      final topology = oecTwoProvinceTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$oemwcOw|P1', regionId: oemwcOw, ownerId: 'p1'),
              Province(id: '$oemwcOw|P2', regionId: oemwcOw, ownerId: 'p2'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$oemwcOw|P1',
                tileKey: oemwcTileP1,
              ),
            ],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: const {targetTileKey: 'iron'},
          playerVisibilityByTile: const {
            'p1': {oemwcTileP1: 'fullyVisible', targetTileKey: 'fogged'},
          },
          tileKeysByRegionAndProvince: const {
            oemwcOw: {
              'oldWorld|P1': [oemwcTileP1],
              'oldWorld|P2': [targetTileKey],
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      );
      oemwcExpectWork(
        game,
        topology,
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: targetTileKey,
        ),
        status: OrderValidationStatus.rejected,
        reasonContains: 'cannot occupy',
      );

    case OrderEngineMoveAndWorkContextTarget.moveRejectedWhenNotAdjacentNotOwn:
      oemwcExpectMove(
        oemwcThreeProvinceUnitGame(
          unitType: 'musketeers',
          p3OwnerId: 'p2',
        ),
        oemwcThreeProvinceChainTopology(),
        MoveOrder(unitId: 'u1', destinationTileKey: '$oemwcOw|P3|0|0'),
        status: OrderValidationStatus.rejected,
      );

    case OrderEngineMoveAndWorkContextTarget
        .civilianMoveAcceptedWhenNotAdjacentOwnProvince:
      oemwcExpectMove(
        oemwcThreeProvinceUnitGame(
          unitType: kUnitTypeBuilder,
          p3OwnerId: 'p1',
        ),
        oemwcThreeProvinceChainTopology(),
        MoveOrder(unitId: 'u1', destinationTileKey: '$oemwcOw|P3|0|0'),
        status: OrderValidationStatus.accepted,
      );

    case OrderEngineMoveAndWorkContextTarget
        .workProspectRejectedWhenAlreadyProspected:
      oemwcExpectWork(
        oemwcExplorerProvinceGame(
          tileVisibility: 'fogged',
          provinceOwnerId: 'tribe1',
          resourceByTileKey: 'iron',
          prospectedTiles: {oemwcTileP1},
          overtureStates: oemwcTribeConsulate,
        ),
        oecSingleProvinceTopology(),
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: oemwcTileP1,
        ),
        status: OrderValidationStatus.rejected,
        reasonContains: 'already prospected',
      );
  }
}
