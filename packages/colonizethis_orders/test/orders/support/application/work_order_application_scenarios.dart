// Table-driven work-order application scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../scenario_runner.dart';
import 'work_application_fixtures.dart';
import 'work_order_application_expectation_shorthand.dart';

void waaRunProspectAddsTilePlayerProspectedTilesWhenTerrainEligible() {waaExpectProspect(expected: true,terrain: TerrainType.hills);}

void waaRunProspectOnNonMineralEligibleTerrainDoesNotAddTile() {waaExpectProspect(expected: false,terrain: TerrainType.plains);}

void waaRunProspectAddsTileWhenMineralResourcePresentWithoutTileMap() {waaExpectProspect(expected: true,resourceByTileKey: {WorkAppIds.tileKey: 'iron'},);}

void waaRunProspectDoesNotAddTileWhenNonMineralResourcePresentWithoutTileMap() {waaExpectProspect(expected: false,resourceByTileKey: {WorkAppIds.tileKey: 'grain'},);}

void waaRunBuildImprovementWorkOrderSetsCurrentWorkThenCompletesWhenTotalTurns1() =>
    waaExpectBuildImprovementCompletes();

void waaRunBuildFortAssignsCurrentWorkTotalTurnsFromTotalTurnsForWorkFortLevel() {final next = waaApply(waaEngineerFortGame(fortLevel: 1,techUnlocked: const {kTechIdMineEngineering: true},),workAppSingleWorkOrder(target: kWorkTargetBuildFort),); waaExpectCurrentWorkTiming(next,workTarget: kWorkTargetBuildFort,totalTurns: totalTurnsForWork(kWorkTargetBuildFort,fortLevel: 1),remainingTurns: 1,originTileKey: WorkAppIds.tileKey,assignedTileKey: WorkAppIds.tileKey,); expect(next.worldState.oldWorld.provinces.single.fortLevel,1);}

void waaRunCounterSpyWorkOrderSetsCurrentWorkForSpyUnit() {waaExpectCounterSpyTiming(game: workAppOwnedGame(units: [workAppUnit(id: 'spy1',type: kUnitTypeSpy)],provinces: [workAppOwnedProvince(ownerId: 'p2')],players: const [Player(id: 'p1',displayName: 'P1',isHuman: true),Player(id: 'p2',displayName: 'P2',isHuman: true),],),);}

void waaRunPurchaseLandSuccessTreasuryDeductedTileRecordedPurchasedTilesByTileKey() =>
    waaExpectPurchaseSuccess();

void waaRunPurchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe() {waaExpectPurchaseRejected();}

void waaRunPurchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe() {waaExpectPurchaseRejected(overtureStates: const [OvertureState(gpId: 'p1',targetId: 'minor1',stage: OvertureStage.embassy,sinceTurn: 0,),],diplomacyRelations: const [DiplomacyRelation(factionId1: 'p1',factionId2: 'minor1',state: RelationState.atWar,),],);}

void waaRunPurchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite() =>
    waaExpectDualPurchaseFirstWins();

void waaRunBuildFortWithSufficientMaterialsDeductsMaterials() {final game = waaEngineerFortGame(); waaExpectStockpileDeducted(game,waaApply(game,workAppSingleWorkOrder(target: kWorkTargetBuildFort)),workOrderCostBuildFort(0),);}

void waaRunBuildFortLevel2SkippedWithoutMineEngineering() {waaExpectFortSkipAtLevel(1);}

void waaRunBuildFortLevel3SkippedWithoutModernForts() {waaExpectFortSkipAtLevel(2);}

void waaRunUpgradeTownCompletionIncreasesProvinceTownDevelopmentLevel() {final next = waaApply(workAppOwnedGame(units: [workAppWorkingUnit(type: kUnitTypeBuilder,workTarget: kWorkTargetUpgradeTown,),],provinces: [workAppOwnedProvince(townDevelopmentLevel: 1)],players: [workAppPlayer(techUnlocked: const {kTechIdNationalBureaucracy: true}),],),workAppProcessWorkOrders(),); expect(next.worldState.oldWorld.provinces.single.townDevelopmentLevel,2);}

void waaRunCounterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork() {final units = waaApply(workAppOwnedGame(turnNumber: 1,globalGameSeed: 12345,units: [workAppWorkingUnit(id: 'spy1',type: kUnitTypeSpy,workTarget: kWorkTargetCounterSpy,totalTurns: 0,remainingTurns: 1,),workAppUnit(id: 'spy2',type: kUnitTypeSpy,ownerId: 'p2'),],tileKeysByRegionAndProvince: {WorkAppIds.ow: {WorkAppIds.provinceId: [WorkAppIds.tileKey],},},players: const [Player(id: 'p1',displayName: 'P1',isHuman: true),Player(id: 'p2',displayName: 'P2',isHuman: true),],),workAppProcessWorkOrders(playerIds: const ['p1','p2']),).worldState.oldWorld.units; expect(units.length,2); for (final id in const ['spy1','spy2']) {expect(units.any((u) => u.id == id),isTrue); }}

void waaRunUnknownWorkTargetSkippedUnitStaysIdle() {waaExpectUnitIdle(waaApply(workAppOwnedGame(units: [workAppUnit(type: kUnitTypeBuilder)]),workAppSingleWorkOrder(target: 'unknown_target'),),);}

void waaRunBuildRoadWithInsufficientMaterialsDoesNotSetCurrentWorkDeductStockpile() {final next = waaApply(workAppOwnedGame(units: [workAppUnit(type: kUnitTypeEngineer)],players: [workAppPlayer(stockpile: const Stockpile())],),workAppSingleWorkOrder(target: kWorkTargetBuildRoad),); waaExpectUnitIdle(next); expect(next.players.single.stockpile.quantityOf(CommodityCatalog.lumber.id),0,);}

void waaRunBuildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork() {final game = waaEngineerRoadGame(); final next = waaApply(game,workAppSingleWorkOrder(target: kWorkTargetBuildRoad),); waaExpectUnitIdle(next); waaExpectRoadLevel(next,1); waaExpectStockpileDeducted(game,next,workOrderCostBuildRoad);}

void waaRunCounterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince() {final next = waaApply(workAppOwnedGame(units: [workAppUnit(id: 'spy1',type: kUnitTypeSpy)],tileKeysByRegionAndProvince: const {WorkAppIds.ow: {WorkAppIds.provinceId: [WorkAppIds.tileKey],},},players: [workAppPlayer(capitalProvinceId: WorkAppIds.provinceId)],),workAppSingleWorkOrder(unitId: 'spy1',target: kWorkTargetCounterSpy),); expect(waaSingleUnit(next).currentWork?.workTarget,kWorkTargetCounterSpy);}

void waaRunExploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles() {final next = waaApply(workAppOwnedGame(units: [workAppUnit(type: kUnitTypeExplorer)],tileKeysByRegionAndProvince: {WorkAppIds.ow: {WorkAppIds.provinceId: [WorkAppIds.tileKey,WorkAppIds.originTileKey],},},),workAppSingleWorkOrder(target: kWorkTargetExplore),); final u = waaSingleUnit(next); expect(u.currentWork!.totalTurns,greaterThanOrEqualTo(1)); waaExpectExploreWork(next,remainingTurns: u.currentWork!.totalTurns - 1);}

void waaRunExploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion() =>
    waaExpectExploreFormulaTotalTurns2();

void waaRunEngineerBuildRoadWorkOrderSetsCurrentWork() {final next = waaApply(waaEngineerRoadGame(),workAppSingleWorkOrder(target: kWorkTargetBuildRoad),); waaExpectUnitIdle(next); waaExpectRoadLevel(next,1);}

void waaRunBuildPortWorkOrderSetsCurrentWorkWhenMaterialsSufficient() =>
    waaExpectPortCompletesWhenAffordable();

List<RunnableScenario> workOrderApplicationScenarios() => [
  // dart format off
  rs('prospect adds tile to playerProspectedTiles when terrain eligible', waaRunProspectAddsTilePlayerProspectedTilesWhenTerrainEligible),

  rs('prospect on non-mineral-eligible terrain does not add tile', waaRunProspectOnNonMineralEligibleTerrainDoesNotAddTile),

  rs('prospect adds tile when mineral resource present without tile map', waaRunProspectAddsTileWhenMineralResourcePresentWithoutTileMap),

  rs('prospect does not add tile when non-mineral resource present without tile map', waaRunProspectDoesNotAddTileWhenNonMineralResourcePresentWithoutTileMap),

  rs('build_improvement work order sets currentWork then completes when totalTurns=1', waaRunBuildImprovementWorkOrderSetsCurrentWorkThenCompletesWhenTotalTurns1),

  rs('build_fort assigns currentWork.totalTurns from totalTurnsForWork (fort level)', waaRunBuildFortAssignsCurrentWorkTotalTurnsFromTotalTurnsForWorkFortLevel),

  rs('counter_spy work order sets currentWork for Spy unit', waaRunCounterSpyWorkOrderSetsCurrentWorkForSpyUnit),

  rs('purchase_land success: treasury deducted and tile recorded in purchasedTilesByTileKey', waaRunPurchaseLandSuccessTreasuryDeductedTileRecordedPurchasedTilesByTileKey),

  rs('purchase_land rejected when no Embassy with province owner (Minor/Tribe)', waaRunPurchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe),

  rs('purchase_land rejected when at war with province owner (Minor/Tribe)', waaRunPurchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe),

  rs('purchase_land same tile by two GPs: first wins, second does not deduct or overwrite', waaRunPurchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite),

  rs('build_fort with sufficient materials deducts materials', waaRunBuildFortWithSufficientMaterialsDeductsMaterials),

  rs('build_fort to level 2 is skipped without Mine Engineering', waaRunBuildFortLevel2SkippedWithoutMineEngineering),

  rs('build_fort to level 3 is skipped without Modern Forts', waaRunBuildFortLevel3SkippedWithoutModernForts),

  rs('upgrade_town completion increases province townDevelopmentLevel', waaRunUpgradeTownCompletionIncreasesProvinceTownDevelopmentLevel),

  rs('counter_spy processWork keeps ongoing assignment without killing in build/work', waaRunCounterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork),

  rs('unknown work target is skipped and unit stays idle', waaRunUnknownWorkTargetSkippedUnitStaysIdle),

  rs('build_road with insufficient materials does not set currentWork or deduct stockpile', waaRunBuildRoadWithInsufficientMaterialsDoesNotSetCurrentWorkDeductStockpile),

  rs('build_road with sufficient materials deducts materials and sets currentWork', waaRunBuildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork),

  rs('counter_spy work order sets currentWork for Spy unit on owned capital province', waaRunCounterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince),

  rs('explore work order sets currentWork when province has tiles', waaRunExploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles),

  rs('explore work order totalTurns uses region-scoped formula ceil(3 * tilesInP / maxTilesInRegion)', waaRunExploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion),

  rs('Engineer build_road work order sets currentWork', waaRunEngineerBuildRoadWorkOrderSetsCurrentWork),

  rs('build_port work order sets currentWork when materials sufficient', waaRunBuildPortWorkOrderSetsCurrentWorkWhenMaterialsSufficient),

  // dart format on
];
