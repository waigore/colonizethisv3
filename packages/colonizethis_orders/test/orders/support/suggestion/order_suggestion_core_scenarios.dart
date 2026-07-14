// Table-driven order suggestion core scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../scenario_runner.dart';
import 'order_suggestion_core_expectation_shorthand.dart';
import 'order_suggestion_core_fixtures.dart';

void oscRunSuggestMoveOrdersOnlyReturnsMovesThatPassValidation() {oscExpectSingleMove(game: oscValidatedMoveGame(),topology: oscTwoProvincesConnected('p1','p2'),destTile: OscIds.tile('p2',0,0),);}

void oscRunSuggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility() =>
    oscExpectMoveThrowsUnknownVisibility();

void oscRunMoveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians() =>
    oscExpectCivilianTileKeyDerivedMove();

void oscRunNoExploreSuggestionWhenProvinceUnknown() {oscExpectWorkTargetSuggestions(game: oscExplorerProvinceGame(),topology: oscProvinceTopology(['p1']),target: kWorkTargetExplore,expectNonEmpty: false,);}

void oscRunSuggestWorkOrdersExploreTargetUsesKWorkTargetExplore() {final t0 = OscIds.tile('p1',0,0); final t1 = OscIds.tile('p1',1,0); expect(oscWorkWithTarget(oscSuggestWork(oscExplorerProvinceGame(visibilityByTile: {t0: 'fullyVisible',t1: 'unknown'},tilesByLocal: {'p1': [t0,t1],},),oscProvinceTopology(['p1']),),kWorkTargetExplore,),isNotEmpty,);}

void oscRunSuggestWorkOrdersExploreAlignsWithPartiallyRevealedProvinceCacheScope() {final game = oscPartialRevealExploreCacheGame(); final topology = oscEmptyTopology(); final explore = oscWorkWithTarget(oscSuggestWork(game,topology),kWorkTargetExplore,); expect(explore,isNotEmpty); expect(Unit.provinceIdFromTileKey(explore.first.targetTileKey),OscIds.prov('p_partial'),);}

void oscRunNoProspectSuggestionWhenProvinceNotAtLeastFogged() {oscExpectWorkTargetSuggestions(game: oscExplorerProvinceGame(ownerId: 'tribe1',visibilityByTile: {OscIds.tile('p1',0,0): 'unknown'},),topology: oscProvinceTopology(['p1']),target: kWorkTargetProspect,expectNonEmpty: false,);}

void oscRunProspectSuggestionWhenProvinceFoggedAndTilesInProvince() {final tileKey = OscIds.tile('p1',0,0); oscExpectWorkTargetSuggestions(game: oscGame(worldState: oscExplorerProvinceGame(visibilityByTile: {tileKey: 'fogged'},tilesByLocal: {'p1': [tileKey],},).worldState.copyWith(resourceByTileKey: {tileKey: 'iron'}),),topology: oscProvinceTopology(['p1']),target: kWorkTargetProspect,expectNonEmpty: true,expectedTileKey: tileKey,);}

void oscRunPlayerViewProvincesByIdMatchesAllProvincesForProspectIterationOrder() {final game = oscGame(worldState: oscExplorerProvinceGame(extraProvinceLocals: ['p2'],extraOwners: ['minor1'],visibilityByTile: {OscIds.tile('p1',0,0): 'fogged'},tilesByLocal: {'p1': [OscIds.tile('p1',0,0)],'p2': [OscIds.tile('p2',0,0)],},).worldState,minorNations: const [MinorNation(id: 'minor1',displayName: 'M1')],); final fromAll = allProvinces(game.worldState).toList()..sort((a,b) => a.id.compareTo(b.id)); final fromView = oscView(game,oscProvinceTopology(['p1','p2']),).provincesById.values.toList()..sort((a,b) => a.id.compareTo(b.id)); expect(fromView.map((p) => p.id).toList(),fromAll.map((p) => p.id).toList());}

void oscRunGetValidWorkOrderTileKeysWithVisibilityExcludesTileReservedByAnotherUnitPendingOrder() {final setup = OscDualBuilderGrainTiles(); final validB2 = getValidWorkOrderTileKeysWithVisibility(game: setup.game(),topology: setup.topology(),view: oscView(setup.game(),setup.topology()),unitId: 'b2',workTarget: kWorkTargetBuildImprovement,currentOrders: setup.ordersReservingTileA(),); expect(validB2,isNot(contains(setup.tileA))); expect(validB2,contains(setup.tileB));}

void oscRunWorkSuggestionsForWorkerUseUnitIdTargetsMayBeAnyValidTile() {final tile = OscIds.tile('p1',0,0); final game = oscGame(worldState: oscWorld(oldWorld: RegionData(provinces: [oscProvince('p1',ownerId: OscIds.playerId)],units: [oscBuilder()],),playerVisibilityByTile: oscVisibility({tile: 'fullyVisible'}),tileKeysByRegionAndProvince: oscTilesByProvince({'p1': [tile],}),),players: [oscBuilderPlayer()],); final topology = oscProvinceTopology(['p1']); for (final o in oscSuggestWork(game,topology)) {expect(o.unitId,'u1'); expect(oscView(game,topology).ownUnitsById[o.unitId]!.locationProvinceId,OscIds.prov('p1'),); }}

void oscRunSuggestWorkOrdersIncludesBuildImprovementWhenFirstProvinceTileHasNoResourceButALaterTileDoes() {final noRes = OscIds.tile('p1',0,0); final withRes = OscIds.tile('p1',1,0); oscExpectBuildImprovementFirstTile(game: oscBuilderImprovementGame(tileNoResource: noRes,tileWithResource: withRes,),topology: oscProvinceTopology(['p1']),expectedTileKey: withRes,unitId: 'u1',);}

void oscRunSuggestWorkOrdersIncludesBuildImprovementOnAnotherOwnedProvinceWhenTheBuilderSProvinceHasNoValidResourceTile() {final tileP1 = OscIds.tile('p1',0,0); final tileP2 = OscIds.tile('p2',0,0); oscExpectBuildImprovementFirstTile(game: oscBuilderImprovementGame(tileNoResource: tileP1,tileWithResource: tileP2,secondProvinceLocal: 'p2',secondTile: tileP2,),topology: oscProvinceTopology(['p1','p2']),expectedTileKey: tileP2,unitId: 'u1',);}

void oscRunSuggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder() {final setup = OscDualBuilderGrainTiles(); oscExpectBuildImprovementFirstTile(game: setup.game(),topology: setup.topology(),expectedTileKey: setup.tileB,orders: setup.ordersReservingTileA(),);}

void oscRunSuggestNavalMissionOrdersReturnsList() {final game = oscGame(worldState: oscWorld(fleets: [oscFleetAtSea('sea1')])); final topology = oscSeaTopology(['sea1']); expect(suggestNavalMissionOrders(oscView(game,topology),game,topology,const Orders(),),isA<List<NavalMissionOrder>>(),);}

void oscRunSuggestBuildOrdersReturnsList() {expect(oscSuggestBuild(oscCapitalProvinceGame(oscPlayer(capitalProvinceId: OscIds.prov('p1'),workerPool: const WorkerPool(peasants: 2),treasury: 500,),),oscCapitalTopology(),),isA<List<BuildUnitOrder>>(),);}

void oscRunSuggestBuildOrdersReturnsShipWhenAffordable() =>
    oscExpectAffordableShipBuild();

void oscRunSuggestBuildOrdersCanReturnBothRegimentAndShipWhenBothAffordable() =>
    oscExpectRegimentAndShipBuild();

void oscRunSuggestResearchOrdersReturnsList() {final game = oscGame(worldState: oscWorld(),players: [oscPlayer(treasury: 1000)],); expect(suggestResearchOrders(oscView(game,oscEmptyTopology()),game,oscEmptyTopology(),const Orders(),),isA<List<ResearchOrder>>(),);}

void oscRunSuggestNavalMoveOrdersReturnsList() {final game = oscGame(worldState: oscWorld(fleets: [oscFleetAtSea('sea1')])); final topology = oscSeaTopology(['sea1','sea2'],edges: const [TopologyEdge(id1: 'sea1',id2: 'sea2')],); expect(suggestNavalMoveOrders(oscView(game,topology),game,topology,const Orders(),),isA<List<NavalMoveOrder>>(),);}

void oscRunCounterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles() =>
    oscExpectCounterSpySuggested();

void oscRunPurchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile() =>
    oscExpectPurchaseLandSuggested();

List<RunnableScenario> orderSuggestionCoreScenarios() => [
  // dart format off
  rs('suggestMoveOrders only returns moves that pass validation', oscRunSuggestMoveOrdersOnlyReturnsMovesThatPassValidation),

  rs('suggestMoveOrders throws when source province has unknown visibility', oscRunSuggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility),

  rs('move suggestions use unit locationProvinceId (tileKey-derived for civilians)', oscRunMoveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians),

  rs('no explore suggestion when province unknown', oscRunNoExploreSuggestionWhenProvinceUnknown),

  rs('suggestWorkOrders explore target uses kWorkTargetExplore', oscRunSuggestWorkOrdersExploreTargetUsesKWorkTargetExplore),

  rs('suggestWorkOrders explore aligns with partially revealed province cache scope', oscRunSuggestWorkOrdersExploreAlignsWithPartiallyRevealedProvinceCacheScope),

  rs('no prospect suggestion when province not at least fogged', oscRunNoProspectSuggestionWhenProvinceNotAtLeastFogged),

  rs('prospect suggestion when province fogged and tiles in province', oscRunProspectSuggestionWhenProvinceFoggedAndTilesInProvince),

  rs('PlayerView.provincesById matches allProvinces for prospect iteration order', oscRunPlayerViewProvincesByIdMatchesAllProvincesForProspectIterationOrder),

  rs('getValidWorkOrderTileKeysWithVisibility excludes tile reserved by another unit pending order', oscRunGetValidWorkOrderTileKeysWithVisibilityExcludesTileReservedByAnotherUnitPendingOrder),

  rs('work suggestions for worker use unit id; targets may be any valid tile', oscRunWorkSuggestionsForWorkerUseUnitIdTargetsMayBeAnyValidTile),

  rs('suggestWorkOrders includes build_improvement when first province tile has no resource but a later tile does', oscRunSuggestWorkOrdersIncludesBuildImprovementWhenFirstProvinceTileHasNoResourceButALaterTileDoes),

  rs('suggestWorkOrders includes build_improvement on another owned province when the builder’s province has no valid resource tile', oscRunSuggestWorkOrdersIncludesBuildImprovementOnAnotherOwnedProvinceWhenTheBuilderSProvinceHasNoValidResourceTile),

  rs('suggestWorkOrders second Builder skips tile reserved by another Builder pending work order', oscRunSuggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder),

  rs('suggestNavalMissionOrders returns list', oscRunSuggestNavalMissionOrdersReturnsList),

  rs('suggestBuildOrders returns list', oscRunSuggestBuildOrdersReturnsList),

  rs('suggestBuildOrders returns ship when affordable', oscRunSuggestBuildOrdersReturnsShipWhenAffordable),

  rs('suggestBuildOrders can return both regiment and ship when both affordable', oscRunSuggestBuildOrdersCanReturnBothRegimentAndShipWhenBothAffordable),

  rs('suggestResearchOrders returns list', oscRunSuggestResearchOrdersReturnsList),

  rs('suggestNavalMoveOrders returns list', oscRunSuggestNavalMoveOrdersReturnsList),

  rs('counter_spy work suggested for Spy in owned province with tiles', oscRunCounterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles),

  rs('purchase_land work suggested for Merchant when minor province has resource tile', oscRunPurchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile),

  // dart format on
];
