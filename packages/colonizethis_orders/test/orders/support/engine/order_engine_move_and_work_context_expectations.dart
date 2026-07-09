// Compact OrderEngine move/work-context assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_engine_core_fixtures.dart';
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
    case OrderEngineMoveAndWorkContextTarget.moveRejectedWhenDestinationProvinceUnknown:
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
      final engine = OrderEngine();
      engine.addMoveOrder(
        'p1',
        const MoveOrder(unitId: 'u1', destinationTileKey: 'oldWorld|P2|0|0'),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('visible'));

    case OrderEngineMoveAndWorkContextTarget.workExploreRejectedWhenProvinceUnknown:
      final topology = oecSingleProvinceTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$oemwcOw|P1', regionId: oemwcOw, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$oemwcOw|P1',
                tileKey: 'oldWorld|P1|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final engine = OrderEngine();
      engine.addWorkOrder(
        'p1',
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetExplore,
          targetTileKey: 'oldWorld|P1|0|0',
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('visible'));

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
                tileKey: 'oldWorld|P1|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {
              'oldWorld|P1|0|0': 'fullyVisible',
              targetTileKey: 'fullyVisible',
              p2OtherLand: 'unknown',
            },
          },
          tileKeysByRegionAndProvince: const {
            oemwcOw: {
              'oldWorld|P1': ['oldWorld|P1|0|0'],
              'oldWorld|P2': [targetTileKey, p2OtherLand],
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      );
      final engine = OrderEngine();
      engine.addWorkOrder(
        'p1',
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetExplore,
          targetTileKey: targetTileKey,
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('cannot occupy'));

    case OrderEngineMoveAndWorkContextTarget.workProspectRejectedWhenProvinceNotFogged:
      final topology = oecSingleProvinceTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$oemwcOw|P1', regionId: oemwcOw, ownerId: 'tribe1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$oemwcOw|P1',
                tileKey: 'oldWorld|P1|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: const {
            'p1': {'oldWorld|P1|0|0': 'unknown'},
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
        overtureStates: oemwcTribeConsulate,
      );
      final engine = OrderEngine();
      engine.addWorkOrder(
        'p1',
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: 'oldWorld|P1|0|0',
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('visible'));

    case OrderEngineMoveAndWorkContextTarget.workProspectRejectedWhenNotMineralEligible:
      const tileKey = 'oldWorld|P1|0|0';
      final topology = oecSingleProvinceTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$oemwcOw|P1', regionId: oemwcOw, ownerId: 'tribe1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$oemwcOw|P1',
                tileKey: tileKey,
              ),
            ],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: const {tileKey: 'grain'},
          playerVisibilityByTile: const {
            'p1': {tileKey: 'fogged'},
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
        overtureStates: oemwcTribeConsulate,
      );
      final engine = OrderEngine();
      engine.addWorkOrder(
        'p1',
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: tileKey,
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('mineral-eligible'));

    case OrderEngineMoveAndWorkContextTarget.workProspectAcceptedWhenMineralEligible:
      const tileKey = 'oldWorld|P1|0|0';
      final topology = oecSingleProvinceTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$oemwcOw|P1', regionId: oemwcOw, ownerId: 'tribe1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$oemwcOw|P1',
                tileKey: tileKey,
              ),
            ],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: const {tileKey: 'iron'},
          playerVisibilityByTile: const {
            'p1': {tileKey: 'fogged'},
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
        overtureStates: oemwcTribeConsulate,
      );
      final engine = OrderEngine();
      engine.addWorkOrder(
        'p1',
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: tileKey,
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.accepted);

    case OrderEngineMoveAndWorkContextTarget.workProspectRejectedWithoutConsulate:
      const tileKey = 'oldWorld|P1|0|0';
      final topology = oecSingleProvinceTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$oemwcOw|P1', regionId: oemwcOw, ownerId: 'tribe1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$oemwcOw|P1',
                tileKey: tileKey,
              ),
            ],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: const {tileKey: 'iron'},
          playerVisibilityByTile: const {
            'p1': {tileKey: 'fogged'},
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
      );
      final engine = OrderEngine();
      engine.addWorkOrder(
        'p1',
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: tileKey,
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('Establish a consulate'));

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
                tileKey: 'oldWorld|P1|0|0',
              ),
            ],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: const {targetTileKey: 'iron'},
          playerVisibilityByTile: const {
            'p1': {'oldWorld|P1|0|0': 'fullyVisible', targetTileKey: 'fogged'},
          },
          tileKeysByRegionAndProvince: const {
            oemwcOw: {
              'oldWorld|P1': ['oldWorld|P1|0|0'],
              'oldWorld|P2': [targetTileKey],
            },
          },
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      );
      final engine = OrderEngine();
      engine.addWorkOrder(
        'p1',
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: targetTileKey,
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('cannot occupy'));

    case OrderEngineMoveAndWorkContextTarget.moveRejectedWhenNotAdjacentNotOwn:
      final topology = oemwcThreeProvinceChainTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$oemwcOw|P1', regionId: oemwcOw, ownerId: 'p1'),
              Province(id: '$oemwcOw|P2', regionId: oemwcOw, ownerId: 'p1'),
              Province(id: '$oemwcOw|P3', regionId: oemwcOw, ownerId: 'p2'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: 'musketeers',
                ownerId: 'p1',
                locationProvinceId: '$oemwcOw|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: oemwcThreeTilesVisible,
        ),
        players: const [
          Player(id: 'p1', displayName: 'P1', isHuman: true),
          Player(id: 'p2', displayName: 'P2', isHuman: true),
        ],
      );
      final engine = OrderEngine();
      engine.addMoveOrder(
        'p1',
        MoveOrder(unitId: 'u1', destinationTileKey: '$oemwcOw|P3|0|0'),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.single.status, OrderValidationStatus.rejected);

    case OrderEngineMoveAndWorkContextTarget.civilianMoveAcceptedWhenNotAdjacentOwnProvince:
      final topology = oemwcThreeProvinceChainTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$oemwcOw|P1', regionId: oemwcOw, ownerId: 'p1'),
              Province(id: '$oemwcOw|P2', regionId: oemwcOw, ownerId: 'p1'),
              Province(id: '$oemwcOw|P3', regionId: oemwcOw, ownerId: 'p1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeBuilder,
                ownerId: 'p1',
                locationProvinceId: '$oemwcOw|P1',
              ),
            ],
          ),
          newWorld: const RegionData(),
          playerVisibilityByTile: oemwcThreeTilesVisible,
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
      );
      final engine = OrderEngine();
      engine.addMoveOrder(
        'p1',
        MoveOrder(unitId: 'u1', destinationTileKey: '$oemwcOw|P3|0|0'),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.single.status, OrderValidationStatus.accepted);

    case OrderEngineMoveAndWorkContextTarget.workProspectRejectedWhenAlreadyProspected:
      const tileKey = 'oldWorld|P1|0|0';
      final topology = oecSingleProvinceTopology();
      final game = Game(
        id: 'g1',
        worldState: WorldState(
          turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
          oldWorld: RegionData(
            provinces: [
              Province(id: '$oemwcOw|P1', regionId: oemwcOw, ownerId: 'tribe1'),
            ],
            units: [
              Unit(
                id: 'u1',
                type: kUnitTypeExplorer,
                ownerId: 'p1',
                locationProvinceId: '$oemwcOw|P1',
                tileKey: tileKey,
              ),
            ],
          ),
          newWorld: const RegionData(),
          resourceByTileKey: const {tileKey: 'iron'},
          playerProspectedTiles: const {
            'p1': {tileKey},
          },
          playerVisibilityByTile: const {
            'p1': {tileKey: 'fogged'},
          },
        ),
        players: const [Player(id: 'p1', displayName: 'P1', isHuman: true)],
        tribes: const [Tribe(id: 'tribe1', displayName: 'Tribe 1')],
        overtureStates: oemwcTribeConsulate,
      );
      final engine = OrderEngine();
      engine.addWorkOrder(
        'p1',
        const WorkOrder(
          unitId: 'u1',
          target: kWorkTargetProspect,
          targetTileKey: tileKey,
        ),
      );
      final results = engine.validatePlayerOrdersWithContext(
        game,
        topology,
        'p1',
      );
      expect(results.length, 1);
      expect(results[0].status, OrderValidationStatus.rejected);
      expect(results[0].reason, contains('already prospected'));
  }
}
