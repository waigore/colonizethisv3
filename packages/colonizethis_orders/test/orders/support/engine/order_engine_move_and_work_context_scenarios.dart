// Table-driven OrderEngine move/work-context scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import '../scenario_runner.dart';
import 'order_engine_core_fixtures.dart';
import 'order_engine_move_and_work_context_expectation_shorthand.dart';
import 'order_engine_move_and_work_context_fixtures.dart';
// dart format off

void oemwcRunMoveRejectedWhenDestinationProvinceUnknown() {final topology = oecTwoProvinceTopology(); final game = Game(id: 'g1',worldState: WorldState(turnState: const TurnState(phase: TurnPhase.orders,turnNumber: 0),oldWorld: RegionData(provinces: [Province(id: '$oemwcOw|P1',regionId: oemwcOw,ownerId: 'p1'),Province(id: '$oemwcOw|P2',regionId: oemwcOw,ownerId: 'p1'),],units: [Unit(id: 'u1',type: kUnitTypeExplorer,ownerId: 'p1',locationProvinceId: '$oemwcOw|P1',),],),newWorld: const RegionData(),playerVisibilityByTile: const {'p1': {'oldWorld|P1|0|0': 'fullyVisible'},},),players: const [Player(id: 'p1',displayName: 'P1',isHuman: true)],); oemwcExpectMove(game,topology,const MoveOrder(unitId: 'u1',destinationTileKey: 'oldWorld|P2|0|0'),status: OrderValidationStatus.rejected,reasonContains: 'visible',);}

void oemwcRunWorkExploreRejectedWhenProvinceUnknown() {oemwcExpectWork(oemwcExplorerProvinceGame(tileVisibility: 'unknown'),oecSingleProvinceTopology(),const WorkOrder(unitId: 'u1',target: kWorkTargetExplore,targetTileKey: oemwcTileP1,),status: OrderValidationStatus.rejected,reasonContains: 'visible',);}

void oemwcRunWorkExploreRejectedOnForeignGpTile() {
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
}

void oemwcRunWorkProspectRejectedWhenProvinceNotFogged() {oemwcExpectWork(oemwcExplorerProvinceGame(tileVisibility: 'unknown',provinceOwnerId: 'tribe1',overtureStates: oemwcTribeConsulate,),oecSingleProvinceTopology(),const WorkOrder(unitId: 'u1',target: kWorkTargetProspect,targetTileKey: oemwcTileP1,),status: OrderValidationStatus.rejected,reasonContains: 'visible',);}

void oemwcRunWorkProspectRejectedWhenNotMineralEligible() {oemwcExpectWork(oemwcExplorerProvinceGame(tileVisibility: 'fogged',provinceOwnerId: 'tribe1',resourceByTileKey: 'grain',overtureStates: oemwcTribeConsulate,),oecSingleProvinceTopology(),const WorkOrder(unitId: 'u1',target: kWorkTargetProspect,targetTileKey: oemwcTileP1,),status: OrderValidationStatus.rejected,reasonContains: 'mineral-eligible',);}

void oemwcRunWorkProspectAcceptedWhenMineralEligible() {oemwcExpectWork(oemwcExplorerProvinceGame(tileVisibility: 'fogged',provinceOwnerId: 'tribe1',resourceByTileKey: 'iron',overtureStates: oemwcTribeConsulate,),oecSingleProvinceTopology(),const WorkOrder(unitId: 'u1',target: kWorkTargetProspect,targetTileKey: oemwcTileP1,),status: OrderValidationStatus.accepted,);}

void oemwcRunWorkProspectRejectedWithoutConsulate() {oemwcExpectWork(oemwcExplorerProvinceGame(tileVisibility: 'fogged',provinceOwnerId: 'tribe1',resourceByTileKey: 'iron',),oecSingleProvinceTopology(),const WorkOrder(unitId: 'u1',target: kWorkTargetProspect,targetTileKey: oemwcTileP1,),status: OrderValidationStatus.rejected,reasonContains: 'Establish a consulate',);}

void oemwcRunWorkProspectRejectedOnForeignGpTile() {
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
}

void oemwcRunMoveRejectedWhenNotAdjacentNotOwn() {oemwcExpectMove(oemwcThreeProvinceUnitGame(unitType: 'musketeers',p3OwnerId: 'p2'),oemwcThreeProvinceChainTopology(),MoveOrder(unitId: 'u1',destinationTileKey: '$oemwcOw|P3|0|0'),status: OrderValidationStatus.rejected,);}

void oemwcRunCivilianMoveAcceptedWhenNotAdjacentOwnProvince() {oemwcExpectMove(oemwcThreeProvinceUnitGame(unitType: kUnitTypeBuilder,p3OwnerId: 'p1'),oemwcThreeProvinceChainTopology(),MoveOrder(unitId: 'u1',destinationTileKey: '$oemwcOw|P3|0|0'),status: OrderValidationStatus.accepted,);}

void oemwcRunWorkProspectRejectedWhenAlreadyProspected() {oemwcExpectWork(oemwcExplorerProvinceGame(tileVisibility: 'fogged',provinceOwnerId: 'tribe1',resourceByTileKey: 'iron',prospectedTiles: {oemwcTileP1},overtureStates: oemwcTribeConsulate,),oecSingleProvinceTopology(),const WorkOrder(unitId: 'u1',target: kWorkTargetProspect,targetTileKey: oemwcTileP1,),status: OrderValidationStatus.rejected,reasonContains: 'already prospected',);}

/// Canonical scenarios for OrderEngine move/work-context family tests.
/// Labels must match wave-3 [DESCRIPTION_BASELINE.txt] entries and former
/// `order_engine_move_and_work_context_part*_test.dart` descriptions.
List<RunnableScenario> orderEngineMoveAndWorkContextScenarios() => [
  rs('move order rejected when destination province unknown', oemwcRunMoveRejectedWhenDestinationProvinceUnknown),
  rs('work order explore rejected when province unknown', oemwcRunWorkExploreRejectedWhenProvinceUnknown),
  rs('work order explore rejected on foreign GP tile for explorer', oemwcRunWorkExploreRejectedOnForeignGpTile),
  rs('work order prospect rejected when province not fogged or better', oemwcRunWorkProspectRejectedWhenProvinceNotFogged),
  rs('work order prospect rejected when tile is not mineral-eligible', oemwcRunWorkProspectRejectedWhenNotMineralEligible),
  rs('work order prospect accepted when mineral-eligible and visibility ok', oemwcRunWorkProspectAcceptedWhenMineralEligible),
  rs('work order prospect rejected in Tribe province without a consulate (Refs #3753 R4)', oemwcRunWorkProspectRejectedWithoutConsulate, '#3753'),
  rs('work order prospect rejected on foreign GP tile for explorer', oemwcRunWorkProspectRejectedOnForeignGpTile),
  rs('move order rejected when destination not adjacent and not own province', oemwcRunMoveRejectedWhenNotAdjacentNotOwn),
  rs('civilian move order accepted when destination not adjacent but own province', oemwcRunCivilianMoveAcceptedWhenNotAdjacentOwnProvince),
  rs('work order prospect rejected when tile already prospected', oemwcRunWorkProspectRejectedWhenAlreadyProspected),
];
