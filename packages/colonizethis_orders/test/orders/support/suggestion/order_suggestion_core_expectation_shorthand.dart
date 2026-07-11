// Compact order_suggestion_core expectation shorthands (Refs #3971).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'order_suggestion_core_fixtures.dart';

List<MoveOrder> oscSuggestMoves(
  Game game,
  MapTopology topology, [
  Orders orders = const Orders(),
]) => suggestMoveOrders(oscView(game, topology), game, topology, orders);

List<WorkOrder> oscSuggestWork(
  Game game,
  MapTopology topology, [
  Orders orders = const Orders(),
]) => suggestWorkOrders(oscView(game, topology), game, topology, orders);

List<BuildUnitOrder> oscSuggestBuild(
  Game game,
  MapTopology topology, [
  Orders orders = const Orders(),
]) => suggestBuildOrders(oscView(game, topology), game, topology, orders);

Iterable<WorkOrder> oscWorkWithTarget(
  List<WorkOrder> suggestions,
  String target,
) => suggestions.where((o) => o.target == target);

void oscExpectWorkTargetSuggestions({
  required Game game,
  required MapTopology topology,
  required String target,
  required bool expectNonEmpty,
  String? expectedTileKey,
  Orders orders = const Orders(),
}) {
  final ordersForTarget = oscWorkWithTarget(
    oscSuggestWork(game, topology, orders),
    target,
  ).toList();
  expect(ordersForTarget, expectNonEmpty ? isNotEmpty : isEmpty);
  if (expectedTileKey != null && expectNonEmpty) {
    expect(ordersForTarget.first.targetTileKey, expectedTileKey);
  }
}

void oscExpectBuildImprovementFirstTile({
  required Game game,
  required MapTopology topology,
  required String expectedTileKey,
  Orders orders = const Orders(),
  String unitId = 'b2',
}) {
  final buildImp = oscWorkWithTarget(
    oscSuggestWork(game, topology, orders),
    kWorkTargetBuildImprovement,
  ).where((o) => o.unitId == unitId).toList();
  expect(buildImp, isNotEmpty);
  expect(buildImp.first.targetTileKey, expectedTileKey);
}

void oscExpectSingleMove({
  required Game game,
  required MapTopology topology,
  required String destTile,
  String unitId = 'u1',
}) {
  final moves = oscSuggestMoves(game, topology);
  expect(moves.length, 1);
  expect(moves.first.unitId, unitId);
  expect(moves.first.destinationTileKey, destTile);
}

void oscExpectSuggestListType<T>(
  List<T> Function(Game, MapTopology) suggest, {
  required Game game,
  required MapTopology topology,
}) => expect(suggest(game, topology), isA<List<T>>());

Stockpile oscShipStockpile({int lumber = 2, int fabric = 2, int castIron = 0}) {
  var s = const Stockpile()
      .applyDelta(CommodityCatalog.lumber.id, lumber)
      .applyDelta(CommodityCatalog.fabric.id, fabric);
  if (castIron > 0) {
    s = s.applyDelta(CommodityCatalog.castIron.id, castIron);
  }
  return s;
}

// dart format off
Game oscExplorerProvinceGame({String provinceLocal = 'p1', String? ownerId = OscIds.playerId, Map<String, String>? visibilityByTile, Map<String, List<String>>? tilesByLocal, List<String>? extraProvinceLocals, List<String>? extraOwners}) {
  final provinces = [oscProvince(provinceLocal, ownerId: ownerId), for (var i = 0; i < (extraProvinceLocals?.length ?? 0); i++) oscProvince(extraProvinceLocals![i], ownerId: extraOwners != null && i < extraOwners.length ? extraOwners[i] : ownerId)];
  return oscGame(worldState: oscWorld(oldWorld: RegionData(provinces: provinces, units: [oscExplorer(provinceLocal: provinceLocal)]), playerVisibilityByTile: visibilityByTile != null ? oscVisibility(visibilityByTile) : null, tileKeysByRegionAndProvince: tilesByLocal != null ? oscTilesByProvince(tilesByLocal) : null));
}

Game oscBuilderImprovementGame({required String tileNoResource, required String tileWithResource, String provinceLocal = 'p1', String? secondProvinceLocal, String? secondTile, String resource = 'grain'}) {
  final provinces = [oscProvince(provinceLocal, ownerId: OscIds.playerId), if (secondProvinceLocal != null) oscProvince(secondProvinceLocal, ownerId: OscIds.playerId)];
  final tilesByLocal = {provinceLocal: secondProvinceLocal == null ? [tileNoResource, tileWithResource] : [tileNoResource], if (secondProvinceLocal != null && secondTile != null) secondProvinceLocal: [secondTile]};
  final visibility = {tileNoResource: 'fullyVisible', tileWithResource: 'fullyVisible', if (secondTile != null) secondTile: 'fullyVisible'};
  return oscGame(worldState: oscWorld(oldWorld: RegionData(provinces: provinces, units: [oscBuilder(provinceLocal: provinceLocal, tileKey: tileNoResource)]), playerVisibilityByTile: oscVisibility(visibility), tileKeysByRegionAndProvince: oscTilesByProvince(tilesByLocal), resourceByTileKey: {tileWithResource: resource, if (secondTile != null) secondTile: resource}, tileState: TileMapState(improvementByTile: {tileWithResource: 0, if (secondTile != null) secondTile: 0})), players: [oscBuilderPlayer()]);
}

void oscExpectMoveThrowsUnknownVisibility() {
  final game = oscGame(worldState: oscWorld(oldWorld: RegionData(provinces: [oscProvince('p1', ownerId: OscIds.playerId), oscProvince('p2', ownerId: OscIds.playerId)], units: [oscExplorer()])));
  expect(() => suggestMoveOrders(oscView(game, oscTwoProvincesConnected('p1', 'p2')), game, oscTwoProvincesConnected('p1', 'p2'), const Orders()), throwsStateError);
}

Game oscValidatedMoveGame() => oscGame(worldState: oscWorld(oldWorld: RegionData(provinces: [oscProvince('p1', ownerId: OscIds.playerId), oscProvince('p2')], units: [oscExplorer()]), tileKeysByRegionAndProvince: oscTilesByProvince({'p2': [OscIds.tile('p2', 0, 0)]}), playerVisibilityByTile: oscVisibility({OscIds.tile('p1', 0, 0): 'fullyVisible', OscIds.tile('p2', 0, 0): 'fogged'})));

void oscExpectCivilianTileKeyDerivedMove() {
  final game = oscGame(worldState: oscWorld(oldWorld: RegionData(provinces: [oscProvince('p1', ownerId: OscIds.playerId), oscProvince('p2', ownerId: OscIds.playerId), oscProvince('p3', ownerId: OscIds.playerId)], units: [oscExplorer(provinceLocal: 'p1', tileKey: OscIds.tile('p2', 0, 0))]), tileKeysByRegionAndProvince: oscTilesByProvince({'p3': [OscIds.tile('p3', 0, 0)]}), playerVisibilityByTile: oscVisibility({OscIds.tile('p2', 0, 0): 'fullyVisible', OscIds.tile('p3', 0, 0): 'fogged'})));
  final topology = oscProvinceTopology(['p1', 'p2', 'p3'], edges: const [TopologyEdge(id1: 'p2', id2: 'p3')]);
  oscExpectSingleMove(game: game, topology: topology, destTile: OscIds.tile('p3', 0, 0));
  expect(oscView(game, topology).ownUnitsById['u1']!.locationProvinceId, OscIds.prov('p2'));
}

void oscExpectAffordableShipBuild() {
  final types = oscSuggestBuild(oscCapitalProvinceGame(oscPlayer(capitalProvinceId: OscIds.prov('p1'), workerPool: const WorkerPool(peasants: 1), treasury: ShipEconomyCatalog.byId['carrack']!.buildTreasuryCost, stockpile: oscShipStockpile())), oscCapitalTopology()).where((o) => ShipEconomyCatalog.byId.containsKey(o.unitType)).toList();
  expect(types, isNotEmpty, reason: 'suggestBuildOrders should include ships when player has capital, treasury and stockpile for fluyte/carrack');
}

void oscExpectRegimentAndShipBuild() {
  final suggestions = oscSuggestBuild(oscCapitalProvinceGame(oscPlayer(capitalProvinceId: OscIds.prov('p1'), workerPool: const WorkerPool(peasants: 2, apprentices: 1), treasury: ShipEconomyCatalog.byId['carrack']!.buildTreasuryCost + 1000, stockpile: oscShipStockpile(lumber: 5, fabric: 5, castIron: 5))), oscCapitalTopology());
  expect(suggestions.any((o) => RegimentEconomyCatalog.byId.containsKey(o.unitType)), isTrue, reason: 'should suggest regiments when affordable');
  expect(suggestions.any((o) => ShipEconomyCatalog.byId.containsKey(o.unitType)), isTrue, reason: 'should suggest ships when affordable');
}

void oscExpectCounterSpySuggested() {
  final tile = OscIds.tile('p1', 0, 0);
  oscExpectWorkTargetSuggestions(game: oscGame(worldState: oscWorld(oldWorld: RegionData(provinces: [oscProvince('p1', ownerId: OscIds.playerId)], units: [Unit(id: 'u1', type: kUnitTypeSpy, ownerId: OscIds.playerId, locationProvinceId: OscIds.prov('p1'))]), playerVisibilityByTile: oscVisibility({tile: 'fullyVisible'}), tileKeysByRegionAndProvince: oscTilesByProvince({'p1': [tile]}))), topology: oscProvinceTopology(['p1']), target: kWorkTargetCounterSpy, expectNonEmpty: true);
}

void oscExpectPurchaseLandSuggested() {
  final purchaseTile = OscIds.tile('minor1', 0, 0);
  oscExpectWorkTargetSuggestions(
    game: oscGame(worldState: oscWorld(oldWorld: RegionData(provinces: [oscProvince('p1', ownerId: OscIds.playerId), oscProvince('minor1', ownerId: 'minor1')], units: [Unit(id: 'u1', type: kUnitTypeMerchant, ownerId: OscIds.playerId, locationProvinceId: OscIds.prov('p1'))]), playerVisibilityByTile: oscVisibility({OscIds.tile('p1', 0, 0): 'fullyVisible', purchaseTile: 'fullyVisible'}), tileKeysByRegionAndProvince: oscTilesByProvince({'p1': [OscIds.tile('p1', 0, 0)], 'minor1': [purchaseTile]}), resourceByTileKey: {purchaseTile: 'grain'}), players: [oscPlayer(treasury: 500)], minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')], overtureStates: const [OvertureState(gpId: OscIds.playerId, targetId: 'minor1', stage: OvertureStage.embassy, sinceTurn: 0)]),
    topology: oscProvinceTopology(['p1', 'minor1']),
    target: kWorkTargetPurchaseLand,
    expectNonEmpty: true,
  );
}
// dart format on
