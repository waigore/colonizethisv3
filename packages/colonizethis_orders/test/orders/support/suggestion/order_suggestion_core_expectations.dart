// Compact order_suggestion_core assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_suggestion_core_fixtures.dart';

/// Pins for [orderSuggestionCoreScenarios] rows.
enum OrderSuggestionCoreTarget {
  suggestMoveOrdersOnlyReturnsMovesThatPassValidation,
  suggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility,
  moveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians,
  noExploreSuggestionWhenProvinceUnknown,
  suggestWorkOrdersExploreTargetUsesKWorkTargetExplore,
  suggestWorkOrdersExploreAlignsWithPartiallyRevealedProvinceCacheScope,
  noProspectSuggestionWhenProvinceNotAtLeastFogged,
  prospectSuggestionWhenProvinceFoggedAndTilesInProvince,
  playerViewProvincesByIdMatchesAllProvincesForProspectIterationOrder,
  getValidWorkOrderTileKeysWithVisibilityExcludesTileReservedByAnotherUnitPendingOrder,
  workSuggestionsForWorkerUseUnitIdTargetsMayBeAnyValidTile,
  suggestWorkOrdersIncludesBuildImprovementWhenFirstProvinceTileHasNoResourceButALaterTileDoes,
  suggestWorkOrdersIncludesBuildImprovementOnAnotherOwnedProvinceWhenTheBuilderSProvinceHasNoValidResourceTile,
  suggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder,
  suggestNavalMissionOrdersReturnsList,
  suggestBuildOrdersReturnsList,
  suggestBuildOrdersReturnsShipWhenAffordable,
  suggestBuildOrdersCanReturnBothRegimentAndShipWhenBothAffordable,
  suggestResearchOrdersReturnsList,
  suggestNavalMoveOrdersReturnsList,
  counterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles,
  purchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile,
}

void runOrderSuggestionCoreExpectation(OrderSuggestionCoreTarget target) {
  switch (target) {
    case OrderSuggestionCoreTarget
        .suggestMoveOrdersOnlyReturnsMovesThatPassValidation:
      _suggestMoveOrdersOnlyReturnsMovesThatPassValidation();
    case OrderSuggestionCoreTarget
        .suggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility:
      _suggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility();
    case OrderSuggestionCoreTarget
        .moveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians:
      _moveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians();
    case OrderSuggestionCoreTarget.noExploreSuggestionWhenProvinceUnknown:
      _noExploreSuggestionWhenProvinceUnknown();
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersExploreTargetUsesKWorkTargetExplore:
      _suggestWorkOrdersExploreTargetUsesKWorkTargetExplore();
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersExploreAlignsWithPartiallyRevealedProvinceCacheScope:
      _suggestWorkOrdersExploreAlignsWithPartiallyRevealedProvinceCacheScope();
    case OrderSuggestionCoreTarget
        .noProspectSuggestionWhenProvinceNotAtLeastFogged:
      _noProspectSuggestionWhenProvinceNotAtLeastFogged();
    case OrderSuggestionCoreTarget
        .prospectSuggestionWhenProvinceFoggedAndTilesInProvince:
      _prospectSuggestionWhenProvinceFoggedAndTilesInProvince();
    case OrderSuggestionCoreTarget
        .playerViewProvincesByIdMatchesAllProvincesForProspectIterationOrder:
      _playerViewProvincesByIdMatchesAllProvincesForProspectIterationOrder();
    case OrderSuggestionCoreTarget
        .getValidWorkOrderTileKeysWithVisibilityExcludesTileReservedByAnotherUnitPendingOrder:
      _getValidWorkOrderTileKeysWithVisibilityExcludesTileReservedByAnotherUnitPendingOrder();
    case OrderSuggestionCoreTarget
        .workSuggestionsForWorkerUseUnitIdTargetsMayBeAnyValidTile:
      _workSuggestionsForWorkerUseUnitIdTargetsMayBeAnyValidTile();
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersIncludesBuildImprovementWhenFirstProvinceTileHasNoResourceButALaterTileDoes:
      _suggestWorkOrdersIncludesBuildImprovementWhenFirstProvinceTileHasNoResourceButALaterTileDoes();
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersIncludesBuildImprovementOnAnotherOwnedProvinceWhenTheBuilderSProvinceHasNoValidResourceTile:
      _suggestWorkOrdersIncludesBuildImprovementOnAnotherOwnedProvinceWhenTheBuilderSProvinceHasNoValidResourceTile();
    case OrderSuggestionCoreTarget
        .suggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder:
      _suggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder();
    case OrderSuggestionCoreTarget.suggestNavalMissionOrdersReturnsList:
      _suggestNavalMissionOrdersReturnsList();
    case OrderSuggestionCoreTarget.suggestBuildOrdersReturnsList:
      _suggestBuildOrdersReturnsList();
    case OrderSuggestionCoreTarget.suggestBuildOrdersReturnsShipWhenAffordable:
      _suggestBuildOrdersReturnsShipWhenAffordable();
    case OrderSuggestionCoreTarget
        .suggestBuildOrdersCanReturnBothRegimentAndShipWhenBothAffordable:
      _suggestBuildOrdersCanReturnBothRegimentAndShipWhenBothAffordable();
    case OrderSuggestionCoreTarget.suggestResearchOrdersReturnsList:
      _suggestResearchOrdersReturnsList();
    case OrderSuggestionCoreTarget.suggestNavalMoveOrdersReturnsList:
      _suggestNavalMoveOrdersReturnsList();
    case OrderSuggestionCoreTarget
        .counterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles:
      _counterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles();
    case OrderSuggestionCoreTarget
        .purchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile:
      _purchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile();
  }
}

void _suggestMoveOrdersOnlyReturnsMovesThatPassValidation() {
  final p1 = oscProvince('p1', ownerId: OscIds.playerId);
  final p2 = oscProvince('p2');
  final unit = oscExplorer();
  final game = oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(provinces: [p1, p2], units: [unit]),
      tileKeysByRegionAndProvince: oscTilesByProvince({
        'p2': [OscIds.tile('p2', 0, 0)],
      }),
      playerVisibilityByTile: oscVisibility({
        OscIds.tile('p1', 0, 0): 'fullyVisible',
        OscIds.tile('p2', 0, 0): 'fogged',
      }),
    ),
  );
  final topology = oscTwoProvincesConnected('p1', 'p2');
  final view = oscView(game, topology);
  final suggestions = suggestMoveOrders(view, game, topology, const Orders());
  expect(suggestions.length, 1);
  expect(suggestions.first.unitId, 'u1');
  expect(suggestions.first.destinationTileKey, OscIds.tile('p2', 0, 0));
}

void _suggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility() {
  final p1 = oscProvince('p1', ownerId: OscIds.playerId);
  final p2 = oscProvince('p2', ownerId: OscIds.playerId);
  final game = oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(provinces: [p1, p2], units: [oscExplorer()]),
    ),
  );
  final topology = oscTwoProvincesConnected('p1', 'p2');
  final view = oscView(game, topology);
  expect(
    () => suggestMoveOrders(view, game, topology, const Orders()),
    throwsStateError,
  );
}

void _moveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians() {
  final unit = oscExplorer(provinceLocal: 'p1', tileKey: OscIds.tile('p2', 0, 0));
  final game = oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: [
          oscProvince('p1', ownerId: OscIds.playerId),
          oscProvince('p2', ownerId: OscIds.playerId),
          oscProvince('p3', ownerId: OscIds.playerId),
        ],
        units: [unit],
      ),
      tileKeysByRegionAndProvince: oscTilesByProvince({
        'p3': [OscIds.tile('p3', 0, 0)],
      }),
      playerVisibilityByTile: oscVisibility({
        OscIds.tile('p2', 0, 0): 'fullyVisible',
        OscIds.tile('p3', 0, 0): 'fogged',
      }),
    ),
  );
  final topology = oscProvinceTopology(
    ['p1', 'p2', 'p3'],
    edges: const [TopologyEdge(id1: 'p2', id2: 'p3')],
  );
  final view = oscView(game, topology);
  final suggestions = suggestMoveOrders(view, game, topology, const Orders());
  expect(suggestions.length, 1);
  expect(suggestions.first.unitId, 'u1');
  expect(suggestions.first.destinationTileKey, OscIds.tile('p3', 0, 0));
  expect(view.ownUnitsById['u1']!.locationProvinceId, OscIds.prov('p2'));
}

void _noExploreSuggestionWhenProvinceUnknown() {
  final game = oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: [oscProvince('p1', ownerId: OscIds.playerId)],
        units: [oscExplorer()],
      ),
    ),
  );
  final topology = oscProvinceTopology(['p1']);
  final view = oscView(game, topology);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  expect(suggestions.where((o) => o.target == kWorkTargetExplore), isEmpty);
}

void _suggestWorkOrdersExploreTargetUsesKWorkTargetExplore() {
  final t0 = OscIds.tile('p1', 0, 0);
  final t1 = OscIds.tile('p1', 1, 0);
  final game = oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: [oscProvince('p1', ownerId: OscIds.playerId)],
        units: [oscExplorer()],
      ),
      playerVisibilityByTile: oscVisibility({t0: 'fullyVisible', t1: 'unknown'}),
      tileKeysByRegionAndProvince: oscTilesByProvince({'p1': [t0, t1]}),
    ),
  );
  final topology = oscProvinceTopology(['p1']);
  final view = oscView(game, topology);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  expect(
    suggestions.where((o) => o.target == kWorkTargetExplore),
    isNotEmpty,
  );
}

void _suggestWorkOrdersExploreAlignsWithPartiallyRevealedProvinceCacheScope() {
  final partialProvince = OscIds.prov('p_partial');
  final fullyKnownProvince = OscIds.prov('p_known');
  final partialKnownTile = OscIds.tile('p_partial', 0, 0);
  final partialUnknownTile = OscIds.tile('p_partial', 1, 0);
  final knownTile = OscIds.tile('p_known', 0, 0);

  final game = oscGame(
    id: 'g-cache-scope',
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: [
          oscProvince('p_partial', ownerId: 'tribe1'),
          oscProvince('p_known', ownerId: 'tribe1'),
        ],
        units: [
          oscExplorer(
            provinceLocal: 'p_partial',
            tileKey: partialKnownTile,
          ),
        ],
      ),
      playerVisibilityByTile: oscVisibility({
        partialKnownTile: 'fogged',
        partialUnknownTile: 'unknown',
        knownTile: 'fullyVisible',
      }),
      tileKeysByRegionAndProvince: {
        OscIds.ow: {
          partialProvince: [partialKnownTile, partialUnknownTile],
          fullyKnownProvince: [knownTile],
        },
      },
    ),
    tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
    overtureStates: const [
      OvertureState(
        gpId: OscIds.playerId,
        targetId: 'tribe1',
        stage: OvertureStage.tradeConsulate,
      ),
    ],
  );
  final topology = oscEmptyTopology();
  final view = oscView(game, topology);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  final explore = suggestions.where((o) => o.target == kWorkTargetExplore);
  expect(explore, isNotEmpty);
  expect(
    Unit.provinceIdFromTileKey(explore.first.targetTileKey),
    partialProvince,
  );
}

void _noProspectSuggestionWhenProvinceNotAtLeastFogged() {
  final game = oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: [oscProvince('p1', ownerId: 'tribe1')],
        units: [oscExplorer()],
      ),
      playerVisibilityByTile: oscVisibility({
        OscIds.tile('p1', 0, 0): 'unknown',
      }),
    ),
    tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
  );
  final topology = oscProvinceTopology(['p1']);
  final view = oscView(game, topology);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  expect(suggestions.where((o) => o.target == kWorkTargetProspect), isEmpty);
}

void _prospectSuggestionWhenProvinceFoggedAndTilesInProvince() {
  final tileKey = OscIds.tile('p1', 0, 0);
  final game = oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: [oscProvince('p1', ownerId: OscIds.playerId)],
        units: [oscExplorer()],
      ),
      playerVisibilityByTile: oscVisibility({tileKey: 'fogged'}),
      resourceByTileKey: {tileKey: 'iron'},
      tileKeysByRegionAndProvince: oscTilesByProvince({'p1': [tileKey]}),
    ),
  );
  final topology = oscProvinceTopology(['p1']);
  final view = oscView(game, topology);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  expect(suggestions.where((o) => o.target == kWorkTargetProspect), isNotEmpty);
  expect(
    suggestions
        .firstWhere((o) => o.target == kWorkTargetProspect)
        .targetTileKey,
    tileKey,
  );
}

void _playerViewProvincesByIdMatchesAllProvincesForProspectIterationOrder() {
  final game = oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: [
          oscProvince('p2', ownerId: 'minor1'),
          oscProvince('p1', ownerId: OscIds.playerId),
        ],
        units: [oscExplorer()],
      ),
      playerVisibilityByTile: oscVisibility({
        OscIds.tile('p1', 0, 0): 'fogged',
      }),
      tileKeysByRegionAndProvince: oscTilesByProvince({
        'p1': [OscIds.tile('p1', 0, 0)],
        'p2': [OscIds.tile('p2', 0, 0)],
      }),
    ),
    minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
  );
  final topology = oscProvinceTopology(['p1', 'p2']);
  final view = oscView(game, topology);
  final fromAll = allProvinces(game.worldState).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final fromView = view.provincesById.values.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  expect(fromView.length, fromAll.length);
  expect(fromView.map((p) => p.id).toList(), fromAll.map((p) => p.id).toList());
}

void
_getValidWorkOrderTileKeysWithVisibilityExcludesTileReservedByAnotherUnitPendingOrder() {
  final setup = OscDualBuilderGrainTiles();
  final game = setup.game();
  final topology = setup.topology();
  final view = oscView(game, topology);
  final validB2 = getValidWorkOrderTileKeysWithVisibility(
    game: game,
    topology: topology,
    view: view,
    unitId: 'b2',
    workTarget: kWorkTargetBuildImprovement,
    currentOrders: setup.ordersReservingTileA(),
  );
  expect(validB2, isNot(contains(setup.tileA)));
  expect(validB2, contains(setup.tileB));
}

void _workSuggestionsForWorkerUseUnitIdTargetsMayBeAnyValidTile() {
  final game = oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: [oscProvince('p1', ownerId: OscIds.playerId)],
        units: [oscBuilder()],
      ),
      playerVisibilityByTile: oscVisibility({
        OscIds.tile('p1', 0, 0): 'fullyVisible',
      }),
      tileKeysByRegionAndProvince: oscTilesByProvince({
        'p1': [OscIds.tile('p1', 0, 0)],
      }),
    ),
    players: [oscBuilderPlayer()],
  );
  final topology = oscProvinceTopology(['p1']);
  final view = oscView(game, topology);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  for (final o in suggestions) {
    expect(o.unitId, 'u1');
    final u = view.ownUnitsById[o.unitId];
    expect(u, isNotNull);
    expect(u!.locationProvinceId, OscIds.prov('p1'));
  }
}

void
_suggestWorkOrdersIncludesBuildImprovementWhenFirstProvinceTileHasNoResourceButALaterTileDoes() {
  final tileNoResource = OscIds.tile('p1', 0, 0);
  final tileWithResource = OscIds.tile('p1', 1, 0);
  final game = oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: [oscProvince('p1', ownerId: OscIds.playerId)],
        units: [oscBuilder(provinceLocal: 'p1', tileKey: tileNoResource)],
      ),
      playerVisibilityByTile: oscVisibility({
        tileNoResource: 'fullyVisible',
        tileWithResource: 'fullyVisible',
      }),
      tileKeysByRegionAndProvince: oscTilesByProvince({
        'p1': [tileNoResource, tileWithResource],
      }),
      resourceByTileKey: {tileWithResource: 'grain'},
      tileState: TileMapState(improvementByTile: {tileWithResource: 0}),
    ),
    players: [oscBuilderPlayer()],
  );
  final topology = oscProvinceTopology(['p1']);
  final view = oscView(game, topology);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  final buildImp = suggestions.where(
    (o) => o.target == kWorkTargetBuildImprovement,
  );
  expect(buildImp, isNotEmpty);
  expect(
    buildImp.first.targetTileKey,
    tileWithResource,
    reason: 'should pick first valid tile, not the empty-resource tile',
  );
}

void
_suggestWorkOrdersIncludesBuildImprovementOnAnotherOwnedProvinceWhenTheBuilderSProvinceHasNoValidResourceTile() {
  final tileP1 = OscIds.tile('p1', 0, 0);
  final tileP2 = OscIds.tile('p2', 0, 0);
  final game = oscGame(
    worldState: oscWorld(
      oldWorld: RegionData(
        provinces: [
          oscProvince('p1', ownerId: OscIds.playerId),
          oscProvince('p2', ownerId: OscIds.playerId),
        ],
        units: [oscBuilder(provinceLocal: 'p1', tileKey: tileP1)],
      ),
      playerVisibilityByTile: oscVisibility({
        tileP1: 'fullyVisible',
        tileP2: 'fullyVisible',
      }),
      tileKeysByRegionAndProvince: oscTilesByProvince({
        'p1': [tileP1],
        'p2': [tileP2],
      }),
      resourceByTileKey: {tileP2: 'grain'},
      tileState: TileMapState(improvementByTile: {tileP2: 0}),
    ),
    players: [oscBuilderPlayer()],
  );
  final topology = oscProvinceTopology(['p1', 'p2']);
  final view = oscView(game, topology);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  final buildImp = suggestions.where(
    (o) => o.target == kWorkTargetBuildImprovement,
  );
  expect(buildImp, isNotEmpty);
  expect(buildImp.first.targetTileKey, tileP2);
}

void
_suggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder() {
  final setup = OscDualBuilderGrainTiles();
  final game = setup.game();
  final topology = setup.topology();
  final view = oscView(game, topology);
  final suggestions = suggestWorkOrders(
    view,
    game,
    topology,
    setup.ordersReservingTileA(),
  );
  final b2Build = suggestions
      .where((o) => o.unitId == 'b2' && o.target == kWorkTargetBuildImprovement)
      .toList();
  expect(b2Build, isNotEmpty);
  expect(b2Build.first.targetTileKey, setup.tileB);
}

void _suggestNavalMissionOrdersReturnsList() {
  final game = oscGame(
    worldState: oscWorld(fleets: [oscFleetAtSea('sea1')]),
  );
  final topology = oscSeaTopology(['sea1']);
  final view = oscView(game, topology);
  final suggestions = suggestNavalMissionOrders(
    view,
    game,
    topology,
    const Orders(),
  );
  expect(suggestions, isA<List<NavalMissionOrder>>());
}

void _suggestBuildOrdersReturnsList() {
  final player = oscPlayer(
    capitalProvinceId: OscIds.prov('p1'),
    workerPool: const WorkerPool(peasants: 2),
    treasury: 500,
  );
  final game = oscCapitalProvinceGame(player);
  final topology = oscCapitalTopology();
  final view = oscView(game, topology);
  final suggestions = suggestBuildOrders(view, game, topology, const Orders());
  expect(suggestions, isA<List<BuildUnitOrder>>());
}

void _suggestBuildOrdersReturnsShipWhenAffordable() {
  final affordableShipTreasury =
      ShipEconomyCatalog.byId['carrack']!.buildTreasuryCost;
  final stockpile = const Stockpile()
      .applyDelta(CommodityCatalog.lumber.id, 2)
      .applyDelta(CommodityCatalog.fabric.id, 2);
  final player = oscPlayer(
    capitalProvinceId: OscIds.prov('p1'),
    workerPool: const WorkerPool(peasants: 1),
    treasury: affordableShipTreasury,
    stockpile: stockpile,
  );
  final game = oscCapitalProvinceGame(player);
  final topology = oscCapitalTopology();
  final view = oscView(game, topology);
  final suggestions = suggestBuildOrders(view, game, topology, const Orders());
  final shipTypes = suggestions
      .where((o) => ShipEconomyCatalog.byId.containsKey(o.unitType))
      .toList();
  expect(
    shipTypes,
    isNotEmpty,
    reason:
        'suggestBuildOrders should include ships when player has capital, treasury and stockpile for fluyte/carrack',
  );
}

void _suggestBuildOrdersCanReturnBothRegimentAndShipWhenBothAffordable() {
  final affordableBothTreasury =
      ShipEconomyCatalog.byId['carrack']!.buildTreasuryCost + 1000;
  final stockpile = const Stockpile()
      .applyDelta(CommodityCatalog.lumber.id, 5)
      .applyDelta(CommodityCatalog.fabric.id, 5)
      .applyDelta(CommodityCatalog.castIron.id, 5);
  final player = oscPlayer(
    capitalProvinceId: OscIds.prov('p1'),
    workerPool: const WorkerPool(peasants: 2, apprentices: 1),
    treasury: affordableBothTreasury,
    stockpile: stockpile,
  );
  final game = oscCapitalProvinceGame(player);
  final topology = oscCapitalTopology();
  final view = oscView(game, topology);
  final suggestions = suggestBuildOrders(view, game, topology, const Orders());
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

void _suggestResearchOrdersReturnsList() {
  final game = oscGame(
    worldState: oscWorld(),
    players: [oscPlayer(treasury: 1000)],
  );
  final topology = oscEmptyTopology();
  final view = oscView(game, topology);
  final suggestions = suggestResearchOrders(
    view,
    game,
    topology,
    const Orders(),
  );
  expect(suggestions, isA<List<ResearchOrder>>());
}

void _suggestNavalMoveOrdersReturnsList() {
  final game = oscGame(
    worldState: oscWorld(fleets: [oscFleetAtSea('sea1')]),
  );
  final topology = oscSeaTopology(
    ['sea1', 'sea2'],
    edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
  );
  final view = oscView(game, topology);
  final suggestions = suggestNavalMoveOrders(
    view,
    game,
    topology,
    const Orders(),
  );
  expect(suggestions, isA<List<NavalMoveOrder>>());
}

void _counterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles() {
  final tileKey = OscIds.tile('p1', 0, 0);
  final game = oscGame(
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
  final topology = oscProvinceTopology(['p1']);
  final view = oscView(game, topology);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  expect(
    suggestions.where((o) => o.target == kWorkTargetCounterSpy),
    isNotEmpty,
  );
}

void _purchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile() {
  final tileKey = OscIds.tile('minor1', 0, 0);
  final game = oscGame(
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
  final topology = oscProvinceTopology(['p1', 'minor1']);
  final view = oscView(game, topology);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  expect(
    suggestions.where((o) => o.target == kWorkTargetPurchaseLand),
    isNotEmpty,
  );
}
