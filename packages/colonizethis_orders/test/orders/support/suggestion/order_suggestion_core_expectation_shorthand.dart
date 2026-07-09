// Compact order_suggestion_core expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_core_fixtures.dart';

List<MoveOrder> oscSuggestMoves(
  Game game,
  MapTopology topology, [
  Orders orders = const Orders(),
]) {
  final view = oscView(game, topology);
  return suggestMoveOrders(view, game, topology, orders);
}

List<WorkOrder> oscSuggestWork(
  Game game,
  MapTopology topology, [
  Orders orders = const Orders(),
]) {
  final view = oscView(game, topology);
  return suggestWorkOrders(view, game, topology, orders);
}

List<BuildUnitOrder> oscSuggestBuild(
  Game game,
  MapTopology topology, [
  Orders orders = const Orders(),
]) {
  final view = oscView(game, topology);
  return suggestBuildOrders(view, game, topology, orders);
}

List<ResearchOrder> oscSuggestResearch(
  Game game,
  MapTopology topology, [
  Orders orders = const Orders(),
]) {
  final view = oscView(game, topology);
  return suggestResearchOrders(view, game, topology, orders);
}

List<NavalMissionOrder> oscSuggestNavalMission(
  Game game,
  MapTopology topology, [
  Orders orders = const Orders(),
]) {
  final view = oscView(game, topology);
  return suggestNavalMissionOrders(view, game, topology, orders);
}

List<NavalMoveOrder> oscSuggestNavalMove(
  Game game,
  MapTopology topology, [
  Orders orders = const Orders(),
]) {
  final view = oscView(game, topology);
  return suggestNavalMoveOrders(view, game, topology, orders);
}

void oscExpectFirstMove(
  List<MoveOrder> suggestions, {
  String unitId = 'u1',
  required String destinationTileKey,
}) {
  expect(suggestions.length, 1);
  expect(suggestions.first.unitId, unitId);
  expect(suggestions.first.destinationTileKey, destinationTileKey);
}

Iterable<WorkOrder> oscWorkWithTarget(
  List<WorkOrder> suggestions,
  String target,
) =>
    suggestions.where((o) => o.target == target);

void oscExpectWorkTargetEmpty(List<WorkOrder> suggestions, String target) {
  expect(oscWorkWithTarget(suggestions, target), isEmpty);
}

void oscExpectWorkTargetNotEmpty(List<WorkOrder> suggestions, String target) {
  expect(oscWorkWithTarget(suggestions, target), isNotEmpty);
}

void oscExpectThrowsSuggestMoveOnUnknownVisibility(
  Game game,
  MapTopology topology,
) {
  final view = oscView(game, topology);
  expect(
    () => suggestMoveOrders(view, game, topology, const Orders()),
    throwsStateError,
  );
}

void oscExpectProvinceViewMatchesAll(Game game, MapTopology topology) {
  final fromAll = allProvinces(game.worldState).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final fromView = oscView(game, topology).provincesById.values.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  expect(fromView.length, fromAll.length);
  expect(fromView.map((p) => p.id).toList(), fromAll.map((p) => p.id).toList());
}

void oscExpectExploreTargetsProvince(
  Game game,
  MapTopology topology,
  String provinceId,
) {
  final explore = oscWorkWithTarget(
    oscSuggestWork(game, topology),
    kWorkTargetExplore,
  );
  expect(explore, isNotEmpty);
  expect(
    Unit.provinceIdFromTileKey(explore.first.targetTileKey),
    provinceId,
  );
}

void oscExpectDualBuilderVisKeysExcludeReserved(OscDualBuilderGrainTiles setup) {
  final game = setup.game();
  final topology = setup.topology();
  final validB2 = getValidWorkOrderTileKeysWithVisibility(
    game: game,
    topology: topology,
    view: oscView(game, topology),
    unitId: 'b2',
    workTarget: kWorkTargetBuildImprovement,
    currentOrders: setup.ordersReservingTileA(),
  );
  expect(validB2, isNot(contains(setup.tileA)));
  expect(validB2, contains(setup.tileB));
}

void oscExpectDualBuilderSuggestSkipsReserved(OscDualBuilderGrainTiles setup) {
  final game = setup.game();
  final topology = setup.topology();
  final b2Build = oscWorkWithTarget(
    oscSuggestWork(game, topology, setup.ordersReservingTileA()),
    kWorkTargetBuildImprovement,
  ).where((o) => o.unitId == 'b2').toList();
  expect(b2Build, isNotEmpty);
  expect(b2Build.first.targetTileKey, setup.tileB);
}

void oscExpectBuildImprovementTargetsTile(
  Game game,
  MapTopology topology,
  String tileKey, {
  String? reason,
}) {
  final buildImp = oscWorkWithTarget(
    oscSuggestWork(game, topology),
    kWorkTargetBuildImprovement,
  );
  expect(buildImp, isNotEmpty);
  expect(buildImp.first.targetTileKey, tileKey, reason: reason);
}

void oscExpectSuggestListType<T>(
  List<T> suggestions,
) {
  expect(suggestions, isA<List<T>>());
}

void oscExpectBuildIncludesShipTypes(Game game, MapTopology topology) {
  final shipTypes = oscSuggestBuild(game, topology)
      .where((o) => ShipEconomyCatalog.byId.containsKey(o.unitType))
      .toList();
  expect(
    shipTypes,
    isNotEmpty,
    reason:
        'suggestBuildOrders should include ships when player has capital, treasury and stockpile for fluyte/carrack',
  );
}

void oscExpectBuildIncludesRegimentAndShip(Game game, MapTopology topology) {
  final suggestions = oscSuggestBuild(game, topology);
  expect(
    suggestions.any((o) => RegimentEconomyCatalog.byId.containsKey(o.unitType)),
    isTrue,
    reason: 'should suggest regiments when affordable',
  );
  expect(
    suggestions.any((o) => ShipEconomyCatalog.byId.containsKey(o.unitType)),
    isTrue,
    reason: 'should suggest ships when affordable',
  );
}

Game oscExplorerProvinceGame({
  String provinceLocal = 'p1',
  String? ownerId = OscIds.playerId,
  Map<String, String>? visibilityByTile,
  Map<String, List<String>>? tilesByLocal,
  List<String>? extraProvinceLocals,
  List<String>? extraOwners,
}) {
  final provinces = [
    oscProvince(provinceLocal, ownerId: ownerId),
    for (var i = 0; i < (extraProvinceLocals?.length ?? 0); i++)
      oscProvince(
        extraProvinceLocals![i],
        ownerId: extraOwners != null && i < extraOwners.length
            ? extraOwners[i]
            : ownerId,
      ),
  ];
  return oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: provinces,
        units: [oscExplorer(provinceLocal: provinceLocal)],
      ),
      playerVisibilityByTile:
          visibilityByTile != null ? oscVisibility(visibilityByTile) : null,
      tileKeysByRegionAndProvince:
          tilesByLocal != null ? oscTilesByProvince(tilesByLocal) : null,
    ),
  );
}

Game oscBuilderImprovementGame({
  required String tileNoResource,
  required String tileWithResource,
  String provinceLocal = 'p1',
  String? secondProvinceLocal,
  String? secondTile,
  String resource = 'grain',
}) {
  final provinces = [
    oscProvince(provinceLocal, ownerId: OscIds.playerId),
    if (secondProvinceLocal != null)
      oscProvince(secondProvinceLocal, ownerId: OscIds.playerId),
  ];
  final tilesByLocal = {
    provinceLocal: secondProvinceLocal == null
        ? [tileNoResource, tileWithResource]
        : [tileNoResource],
    if (secondProvinceLocal != null && secondTile != null)
      secondProvinceLocal: [secondTile],
  };
  final visibility = {
    tileNoResource: 'fullyVisible',
    tileWithResource: 'fullyVisible',
    if (secondTile != null) secondTile: 'fullyVisible',
  };
  return oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: provinces,
        units: [
          oscBuilder(provinceLocal: provinceLocal, tileKey: tileNoResource),
        ],
      ),
      playerVisibilityByTile: oscVisibility(visibility),
      tileKeysByRegionAndProvince: oscTilesByProvince(tilesByLocal),
      resourceByTileKey: {
        tileWithResource: resource,
        if (secondTile != null) secondTile: resource,
      },
      tileState: TileMapState(
        improvementByTile: {
          tileWithResource: 0,
          if (secondTile != null) secondTile: 0,
        },
      ),
    ),
    players: [oscBuilderPlayer()],
  );
}

Player oscAffordableShipPlayer() {
  final treasury = ShipEconomyCatalog.byId['carrack']!.buildTreasuryCost;
  final stockpile = const Stockpile()
      .applyDelta(CommodityCatalog.lumber.id, 2)
      .applyDelta(CommodityCatalog.fabric.id, 2);
  return oscPlayer(
    capitalProvinceId: OscIds.prov('p1'),
    workerPool: const WorkerPool(peasants: 1),
    treasury: treasury,
    stockpile: stockpile,
  );
}

Player oscAffordableBothPlayer() {
  final treasury =
      ShipEconomyCatalog.byId['carrack']!.buildTreasuryCost + 1000;
  final stockpile = const Stockpile()
      .applyDelta(CommodityCatalog.lumber.id, 5)
      .applyDelta(CommodityCatalog.fabric.id, 5)
      .applyDelta(CommodityCatalog.castIron.id, 5);
  return oscPlayer(
    capitalProvinceId: OscIds.prov('p1'),
    workerPool: const WorkerPool(peasants: 2, apprentices: 1),
    treasury: treasury,
    stockpile: stockpile,
  );
}

Game oscSpyInOwnedProvinceGame() {
  final tileKey = OscIds.tile('p1', 0, 0);
  return oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: [oscProvince('p1', ownerId: OscIds.playerId)],
        units: [
          Unit(
            id: 'u1',
            type: kUnitTypeSpy,
            ownerId: OscIds.playerId,
            locationProvinceId: OscIds.prov('p1'),
          ),
        ],
      ),
      playerVisibilityByTile: oscVisibility({tileKey: 'fullyVisible'}),
      tileKeysByRegionAndProvince: oscTilesByProvince({'p1': [tileKey]}),
    ),
  );
}

Game oscMerchantPurchaseLandGame() {
  final tileKey = OscIds.tile('minor1', 0, 0);
  return oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: [
          oscProvince('p1', ownerId: OscIds.playerId),
          oscProvince('minor1', ownerId: 'minor1'),
        ],
        units: [
          Unit(
            id: 'u1',
            type: kUnitTypeMerchant,
            ownerId: OscIds.playerId,
            locationProvinceId: OscIds.prov('p1'),
          ),
        ],
      ),
      playerVisibilityByTile: oscVisibility({
        OscIds.tile('p1', 0, 0): 'fullyVisible',
        tileKey: 'fullyVisible',
      }),
      tileKeysByRegionAndProvince: oscTilesByProvince({
        'p1': [OscIds.tile('p1', 0, 0)],
        'minor1': [tileKey],
      }),
      resourceByTileKey: {tileKey: 'grain'},
    ),
    players: [oscPlayer(treasury: 500)],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
    overtureStates: const [
      OvertureState(
        gpId: OscIds.playerId,
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
  );
}
