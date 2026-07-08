// Compact order_suggestion_core assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

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
  const playerId = 'gp1';
  const ow = 'oldWorld';
  final player = const Player(
    id: playerId,
    displayName: 'Test GP',
    isHuman: false,
  );

  final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
  final p2 = Province(id: '$ow|p2', regionId: ow);

  final unit = Unit(
    id: 'u1',
    type: kUnitTypeExplorer,
    ownerId: playerId,
    locationProvinceId: '$ow|p1',
  );

  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [p1, p2], units: [unit]),
    newWorld: const RegionData(),
    tileKeysByRegionAndProvince: {
      ow: {
        '$ow|p2': ['$ow|p2|0|0'],
      },
    },
    playerVisibilityByTile: const {
      playerId: {
        'oldWorld|p1|0|0': 'fullyVisible',
        'oldWorld|p2|0|0': 'fogged',
      },
    },
  );

  final game = Game(id: 'g1', worldState: world, players: [player]);

  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'p2',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
  );

  final view = buildPlayerView(game, topology, playerId);
  final suggestions = suggestMoveOrders(view, game, topology, const Orders());

  expect(suggestions.length, 1);
  expect(suggestions.first.unitId, 'u1');
  expect(suggestions.first.destinationTileKey, '$ow|p2|0|0');
}

void _suggestMoveOrdersThrowsWhenSourceProvinceHasUnknownVisibility() {
  const playerId = 'gp1';
  const ow = 'oldWorld';
  final player = const Player(
    id: playerId,
    displayName: 'Test GP',
    isHuman: false,
  );
  final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
  final p2 = Province(id: '$ow|p2', regionId: ow, ownerId: playerId);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeExplorer,
    ownerId: playerId,
    locationProvinceId: '$ow|p1',
  );
  // No visibility for p1: source province unknown → game raises.
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [p1, p2], units: [unit]),
    newWorld: const RegionData(),
  );
  final game = Game(id: 'g1', worldState: world, players: [player]);
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'p2',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
  );
  final view = buildPlayerView(game, topology, playerId);
  expect(
    () => suggestMoveOrders(view, game, topology, const Orders()),
    throwsStateError,
  );
}

void _moveSuggestionsUseUnitLocationProvinceIdTileKeyDerivedForCivilians() {
  const playerId = 'gp1';
  const ow = 'oldWorld';
  final player = const Player(
    id: playerId,
    displayName: 'Test GP',
    isHuman: false,
  );
  final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
  final p2 = Province(id: '$ow|p2', regionId: ow, ownerId: playerId);
  final p3 = Province(id: '$ow|p3', regionId: ow, ownerId: playerId);
  // Civilian in p2 by tileKey; provinceId can differ (e.g. legacy). Source = locationProvinceId = p2.
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeExplorer,
    ownerId: playerId,
    locationProvinceId: '$ow|p1',
    tileKey: 'oldWorld|p2|0|0',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [p1, p2, p3], units: [unit]),
    newWorld: const RegionData(),
    tileKeysByRegionAndProvince: {
      ow: {
        '$ow|p3': ['$ow|p3|0|0'],
      },
    },
    playerVisibilityByTile: const {
      playerId: {
        'oldWorld|p2|0|0': 'fullyVisible',
        'oldWorld|p3|0|0': 'fogged',
      },
    },
  );
  final game = Game(id: 'g1', worldState: world, players: [player]);
  // p2 adjacent to p3 only (so suggested moves are from p2 → p3, not from p1).
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'p2',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'p3',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [TopologyEdge(id1: 'p2', id2: 'p3')],
  );
  final view = buildPlayerView(game, topology, playerId);
  final suggestions = suggestMoveOrders(view, game, topology, const Orders());
  expect(suggestions.length, 1);
  expect(suggestions.first.unitId, 'u1');
  expect(suggestions.first.destinationTileKey, '$ow|p3|0|0');
  // Move is from p2 (unit's location province), not p1. Unit with tileKey uses compound id.
  expect(view.ownUnitsById['u1']!.locationProvinceId, 'oldWorld|p2');
}

void _noExploreSuggestionWhenProvinceUnknown() {
  const playerId = 'gp1';
  const ow = 'oldWorld';
  final player = const Player(id: playerId, displayName: 'GP', isHuman: false);
  final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeExplorer,
    ownerId: playerId,
    locationProvinceId: '$ow|p1',
  );
  // No visibility: p1 unknown, so explore not suggested.
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [p1], units: [unit]),
    newWorld: const RegionData(),
  );
  final game = Game(id: 'g1', worldState: world, players: [player]);
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
  final view = buildPlayerView(game, topology, playerId);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  expect(suggestions.where((o) => o.target == kWorkTargetExplore), isEmpty);
}

void _suggestWorkOrdersExploreTargetUsesKWorkTargetExplore() {
  const playerId = 'gp1';
  const ow = 'oldWorld';
  const p1Id = '$ow|p1';
  const t0 = 'oldWorld|p1|0|0';
  const t1 = 'oldWorld|p1|1|0';
  final player = const Player(id: playerId, displayName: 'GP', isHuman: false);
  final p1 = Province(id: p1Id, regionId: ow, ownerId: playerId);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeExplorer,
    ownerId: playerId,
    locationProvinceId: p1Id,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [p1], units: [unit]),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {
      playerId: {t0: 'fullyVisible', t1: 'unknown'},
    },
    tileKeysByRegionAndProvince: {
      ow: {
        p1Id: [t0, t1],
      },
    },
  );
  final game = Game(id: 'g1', worldState: world, players: [player]);
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
  final view = buildPlayerView(game, topology, playerId);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  final explore = suggestions.where((o) => o.target == kWorkTargetExplore);
  expect(explore, isNotEmpty);
}

void _suggestWorkOrdersExploreAlignsWithPartiallyRevealedProvinceCacheScope() {
  const playerId = 'gp1';
  const ow = 'oldWorld';
  const partialProvince = '$ow|p_partial';
  const fullyKnownProvince = '$ow|p_known';
  const partialKnownTile = 'oldWorld|p_partial|0|0';
  const partialUnknownTile = 'oldWorld|p_partial|1|0';
  const knownTile = 'oldWorld|p_known|0|0';

  final player = const Player(id: playerId, displayName: 'GP', isHuman: false);
  final explorer = Unit(
    id: 'u1',
    type: kUnitTypeExplorer,
    ownerId: playerId,
    locationProvinceId: partialProvince,
    tileKey: partialKnownTile,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [
        Province(id: partialProvince, regionId: ow, ownerId: 'tribe1'),
        Province(id: fullyKnownProvince, regionId: ow, ownerId: 'tribe1'),
      ],
      units: [explorer],
    ),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {
      playerId: {
        partialKnownTile: 'fogged',
        partialUnknownTile: 'unknown',
        knownTile: 'fullyVisible',
      },
    },
    tileKeysByRegionAndProvince: {
      ow: {
        partialProvince: [partialKnownTile, partialUnknownTile],
        fullyKnownProvince: [knownTile],
      },
    },
  );
  final game = Game(
    id: 'g-cache-scope',
    worldState: world,
    players: [player],
    tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
    // Refs #3753 R4: a Consulate is required to explore Tribe provinces.
    overtureStates: const [
      OvertureState(
        gpId: playerId,
        targetId: 'tribe1',
        stage: OvertureStage.tradeConsulate,
      ),
    ],
  );
  final topology = const MapTopology(nodes: [], edges: []);
  final view = buildPlayerView(game, topology, playerId);

  final suggestions = suggestWorkOrders(view, game, topology, const Orders());

  final explore = suggestions.where((o) => o.target == kWorkTargetExplore);
  expect(explore, isNotEmpty);
  final exploreOrder = explore.first;
  expect(
    Unit.provinceIdFromTileKey(exploreOrder.targetTileKey),
    partialProvince,
  );
}

void _noProspectSuggestionWhenProvinceNotAtLeastFogged() {
  const playerId = 'gp1';
  const ow = 'oldWorld';
  final player = const Player(id: playerId, displayName: 'GP', isHuman: false);
  final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: 'tribe1');
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeExplorer,
    ownerId: playerId,
    locationProvinceId: '$ow|p1',
  );
  // Province tiles unknown only — prospect requires fogged or better.
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [p1], units: [unit]),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {
      playerId: {'oldWorld|p1|0|0': 'unknown'},
    },
  );
  final game = Game(
    id: 'g1',
    worldState: world,
    players: [player],
    tribes: const [Tribe(id: 'tribe1', displayName: 'T1')],
  );
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
  final view = buildPlayerView(game, topology, playerId);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  expect(suggestions.where((o) => o.target == kWorkTargetProspect), isEmpty);
}

void _prospectSuggestionWhenProvinceFoggedAndTilesInProvince() {
  const playerId = 'gp1';
  const ow = 'oldWorld';
  final player = const Player(id: playerId, displayName: 'GP', isHuman: false);
  final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeExplorer,
    ownerId: playerId,
    locationProvinceId: '$ow|p1',
  );
  const tileKey = 'oldWorld|p1|0|0';
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [p1], units: [unit]),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {
      playerId: {tileKey: 'fogged'},
    },
    resourceByTileKey: const {tileKey: 'iron'},
    tileKeysByRegionAndProvince: {
      ow: {
        '$ow|p1': [tileKey],
      },
    },
  );
  final game = Game(id: 'g1', worldState: world, players: [player]);
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
  final view = buildPlayerView(game, topology, playerId);
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
  const playerId = 'gp1';
  const ow = 'oldWorld';
  final player = const Player(id: playerId, displayName: 'GP', isHuman: false);
  final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
  final p2 = Province(id: '$ow|p2', regionId: ow, ownerId: 'minor1');
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeExplorer,
    ownerId: playerId,
    locationProvinceId: '$ow|p1',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [p2, p1], units: [unit]),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {
      playerId: {'oldWorld|p1|0|0': 'fogged'},
    },
    tileKeysByRegionAndProvince: {
      ow: {
        '$ow|p1': const ['oldWorld|p1|0|0'],
        '$ow|p2': const ['oldWorld|p2|0|0'],
      },
    },
  );
  final game = Game(
    id: 'g1',
    worldState: world,
    players: [player],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'M1')],
  );
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'p2',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
  final view = buildPlayerView(game, topology, playerId);
  final fromAll = allProvinces(game.worldState).toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  final fromView = view.provincesById.values.toList()
    ..sort((a, b) => a.id.compareTo(b.id));
  expect(fromView.length, fromAll.length);
  expect(fromView.map((p) => p.id).toList(), fromAll.map((p) => p.id).toList());
}

void
_getValidWorkOrderTileKeysWithVisibilityExcludesTileReservedByAnotherUnitPendingOrder() {
  const playerId = 'gp1';
  const ow = 'oldWorld';
  const tileA = 'oldWorld|p1|0|0';
  const tileB = 'oldWorld|p1|1|0';
  final player = Player(
    id: playerId,
    displayName: 'GP',
    isHuman: false,
    stockpile: Stockpile(quantities: {'lumber': 20, 'castIron': 20}),
  );
  final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
  final b1 = Unit(
    id: 'b1',
    type: kUnitTypeBuilder,
    ownerId: playerId,
    locationProvinceId: '$ow|p1',
    tileKey: tileA,
  );
  final b2 = Unit(
    id: 'b2',
    type: kUnitTypeBuilder,
    ownerId: playerId,
    locationProvinceId: '$ow|p1',
    tileKey: tileA,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [p1], units: [b1, b2]),
    newWorld: const RegionData(),
    playerVisibilityByTile: {
      playerId: {tileA: 'fullyVisible', tileB: 'fullyVisible'},
    },
    tileKeysByRegionAndProvince: {
      ow: {
        '$ow|p1': [tileA, tileB],
      },
    },
    resourceByTileKey: {tileA: 'grain', tileB: 'grain'},
    tileState: TileMapState(improvementByTile: {tileA: 0, tileB: 0}),
  );
  final game = Game(id: 'g1', worldState: world, players: [player]);
  final topology = const MapTopology(nodes: [], edges: []);
  final view = buildPlayerView(game, topology, playerId);
  final orders = Orders(
    workOrdersByPlayerId: {
      playerId: [
        WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: tileA,
        ),
      ],
    },
  );
  final validB2 = getValidWorkOrderTileKeysWithVisibility(
    game: game,
    topology: topology,
    view: view,
    unitId: 'b2',
    workTarget: kWorkTargetBuildImprovement,
    currentOrders: orders,
  );
  expect(validB2, isNot(contains(tileA)));
  expect(validB2, contains(tileB));
}

void _workSuggestionsForWorkerUseUnitIdTargetsMayBeAnyValidTile() {
  const playerId = 'gp1';
  const ow = 'oldWorld';
  final player = Player(
    id: playerId,
    displayName: 'GP',
    isHuman: false,
    treasury: 500,
    stockpile: Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
  );
  final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeBuilder,
    ownerId: playerId,
    locationProvinceId: '$ow|p1',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [p1], units: [unit]),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {
      playerId: {'oldWorld|p1|0|0': 'fullyVisible'},
    },
    tileKeysByRegionAndProvince: {
      ow: {
        '$ow|p1': ['oldWorld|p1|0|0'],
      },
    },
  );
  final game = Game(id: 'g1', worldState: world, players: [player]);
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
  final view = buildPlayerView(game, topology, playerId);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  // All suggested work orders are for u1, which is in p1; no order targets another province.
  for (final o in suggestions) {
    expect(o.unitId, 'u1');
    final u = view.ownUnitsById[o.unitId];
    expect(u, isNotNull);
    expect(u!.locationProvinceId, 'oldWorld|p1');
  }
}

void
_suggestWorkOrdersIncludesBuildImprovementWhenFirstProvinceTileHasNoResourceButALaterTileDoes() {
  const playerId = 'gp1';
  const ow = 'oldWorld';
  const tileNoResource = 'oldWorld|p1|0|0';
  const tileWithResource = 'oldWorld|p1|1|0';
  final player = Player(
    id: playerId,
    displayName: 'GP',
    isHuman: false,
    stockpile: Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
  );
  final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeBuilder,
    ownerId: playerId,
    locationProvinceId: '$ow|p1',
    tileKey: tileNoResource,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [p1], units: [unit]),
    newWorld: const RegionData(),
    playerVisibilityByTile: {
      playerId: {
        tileNoResource: 'fullyVisible',
        tileWithResource: 'fullyVisible',
      },
    },
    tileKeysByRegionAndProvince: {
      ow: {
        '$ow|p1': [tileNoResource, tileWithResource],
      },
    },
    resourceByTileKey: {tileWithResource: 'grain'},
    tileState: TileMapState(improvementByTile: {tileWithResource: 0}),
  );
  final game = Game(id: 'g1', worldState: world, players: [player]);
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
  final view = buildPlayerView(game, topology, playerId);
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
  const playerId = 'gp1';
  const ow = 'oldWorld';
  const tileP1 = 'oldWorld|p1|0|0';
  const tileP2 = 'oldWorld|p2|0|0';
  final player = Player(
    id: playerId,
    displayName: 'GP',
    isHuman: false,
    stockpile: Stockpile(quantities: {'lumber': 10, 'castIron': 10}),
  );
  final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
  final p2 = Province(id: '$ow|p2', regionId: ow, ownerId: playerId);
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeBuilder,
    ownerId: playerId,
    locationProvinceId: '$ow|p1',
    tileKey: tileP1,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [p1, p2], units: [unit]),
    newWorld: const RegionData(),
    playerVisibilityByTile: {
      playerId: {tileP1: 'fullyVisible', tileP2: 'fullyVisible'},
    },
    tileKeysByRegionAndProvince: {
      ow: {
        '$ow|p1': [tileP1],
        '$ow|p2': [tileP2],
      },
    },
    resourceByTileKey: {tileP2: 'grain'},
    tileState: TileMapState(improvementByTile: {tileP2: 0}),
  );
  final game = Game(id: 'g1', worldState: world, players: [player]);
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'p2',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
  final view = buildPlayerView(game, topology, playerId);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  final buildImp = suggestions.where(
    (o) => o.target == kWorkTargetBuildImprovement,
  );
  expect(buildImp, isNotEmpty);
  expect(buildImp.first.targetTileKey, tileP2);
}

void
_suggestWorkOrdersSecondBuilderSkipsTileReservedByAnotherBuilderPendingWorkOrder() {
  const playerId = 'gp1';
  const ow = 'oldWorld';
  const tileA = 'oldWorld|p1|0|0';
  const tileB = 'oldWorld|p1|1|0';
  final player = Player(
    id: playerId,
    displayName: 'GP',
    isHuman: false,
    stockpile: Stockpile(quantities: {'lumber': 20, 'castIron': 20}),
  );
  final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
  final b1 = Unit(
    id: 'b1',
    type: kUnitTypeBuilder,
    ownerId: playerId,
    locationProvinceId: '$ow|p1',
    tileKey: tileA,
  );
  final b2 = Unit(
    id: 'b2',
    type: kUnitTypeBuilder,
    ownerId: playerId,
    locationProvinceId: '$ow|p1',
    tileKey: tileA,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [p1], units: [b1, b2]),
    newWorld: const RegionData(),
    playerVisibilityByTile: {
      playerId: {tileA: 'fullyVisible', tileB: 'fullyVisible'},
    },
    tileKeysByRegionAndProvince: {
      ow: {
        '$ow|p1': [tileA, tileB],
      },
    },
    resourceByTileKey: {tileA: 'grain', tileB: 'grain'},
    tileState: TileMapState(improvementByTile: {tileA: 0, tileB: 0}),
  );
  final game = Game(id: 'g1', worldState: world, players: [player]);
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
  final view = buildPlayerView(game, topology, playerId);
  final orders = Orders(
    workOrdersByPlayerId: {
      playerId: [
        WorkOrder(
          unitId: 'b1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: tileA,
        ),
      ],
    },
  );
  final suggestions = suggestWorkOrders(view, game, topology, orders);
  final b2Build = suggestions
      .where((o) => o.unitId == 'b2' && o.target == kWorkTargetBuildImprovement)
      .toList();
  expect(b2Build, isNotEmpty);
  expect(b2Build.first.targetTileKey, tileB);
}

void _suggestNavalMissionOrdersReturnsList() {
  const playerId = 'gp1';
  const ow = 'oldWorld';
  final player = const Player(id: playerId, displayName: 'GP', isHuman: false);
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
    fleets: [
      Fleet(
        id: 'fleet_gp1',
        ownerId: playerId,
        seaZoneId: 'sea1',
        regionId: ow,
        shipTypeIds: ['fluyte'],
      ),
    ],
  );
  final game = Game(id: 'g1', worldState: world, players: [player]);
  final topology = MapTopology(
    nodes: [
      TopologyNode(id: 'sea1', regionId: ow, type: TopologyNodeType.seaZone),
    ],
    edges: const [],
  );
  final view = buildPlayerView(game, topology, playerId);
  final suggestions = suggestNavalMissionOrders(
    view,
    game,
    topology,
    const Orders(),
  );
  expect(suggestions, isA<List<NavalMissionOrder>>());
}

void _suggestBuildOrdersReturnsList() {
  const playerId = 'gp1';
  const ow = 'oldWorld';
  final player = Player(
    id: playerId,
    displayName: 'GP',
    isHuman: false,
    capitalProvinceId: '$ow|p1',
    workerPool: const WorkerPool(peasants: 2),
    treasury: 500,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [Province(id: '$ow|p1', regionId: ow, ownerId: playerId)],
      units: [],
    ),
    newWorld: const RegionData(),
  );
  final game = Game(id: 'g1', worldState: world, players: [player]);
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
  final view = buildPlayerView(game, topology, playerId);
  final suggestions = suggestBuildOrders(view, game, topology, const Orders());
  expect(suggestions, isA<List<BuildUnitOrder>>());
}

void _suggestBuildOrdersReturnsShipWhenAffordable() {
  const playerId = 'gp1';
  const ow = 'oldWorld';
  final affordableShipTreasury =
      ShipEconomyCatalog.byId['carrack']!.buildTreasuryCost;
  final stockpile = const Stockpile()
      .applyDelta(CommodityCatalog.lumber.id, 2)
      .applyDelta(CommodityCatalog.fabric.id, 2);
  final player = Player(
    id: playerId,
    displayName: 'GP',
    isHuman: false,
    capitalProvinceId: '$ow|p1',
    workerPool: const WorkerPool(peasants: 1),
    treasury: affordableShipTreasury,
    stockpile: stockpile,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [Province(id: '$ow|p1', regionId: ow, ownerId: playerId)],
      units: [],
    ),
    newWorld: const RegionData(),
  );
  final game = Game(id: 'g1', worldState: world, players: [player]);
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
  final view = buildPlayerView(game, topology, playerId);
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
  const playerId = 'gp1';
  const ow = 'oldWorld';
  final affordableBothTreasury =
      ShipEconomyCatalog.byId['carrack']!.buildTreasuryCost + 1000;
  final stockpile = const Stockpile()
      .applyDelta(CommodityCatalog.lumber.id, 5)
      .applyDelta(CommodityCatalog.fabric.id, 5)
      .applyDelta(CommodityCatalog.castIron.id, 5);
  final player = Player(
    id: playerId,
    displayName: 'GP',
    isHuman: false,
    capitalProvinceId: '$ow|p1',
    workerPool: const WorkerPool(peasants: 2, apprentices: 1),
    treasury: affordableBothTreasury,
    stockpile: stockpile,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [Province(id: '$ow|p1', regionId: ow, ownerId: playerId)],
      units: [],
    ),
    newWorld: const RegionData(),
  );
  final game = Game(id: 'g1', worldState: world, players: [player]);
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
  final view = buildPlayerView(game, topology, playerId);
  final suggestions = suggestBuildOrders(view, game, topology, const Orders());
  final hasRegiment = suggestions.any(
    (o) => RegimentEconomyCatalog.byId.containsKey(o.unitType),
  );
  final hasShip = suggestions.any(
    (o) => ShipEconomyCatalog.byId.containsKey(o.unitType),
  );
  expect(
    hasRegiment,
    isTrue,
    reason: 'should suggest regiments when affordable',
  );
  expect(hasShip, isTrue, reason: 'should suggest ships when affordable');
}

void _suggestResearchOrdersReturnsList() {
  const playerId = 'gp1';
  final player = const Player(
    id: playerId,
    displayName: 'GP',
    isHuman: false,
    treasury: 1000,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
  );
  final game = Game(id: 'g1', worldState: world, players: [player]);
  final topology = MapTopology(nodes: const [], edges: const []);
  final view = buildPlayerView(game, topology, playerId);
  final suggestions = suggestResearchOrders(
    view,
    game,
    topology,
    const Orders(),
  );
  expect(suggestions, isA<List<ResearchOrder>>());
}

void _suggestNavalMoveOrdersReturnsList() {
  const playerId = 'gp1';
  const ow = 'oldWorld';
  final player = const Player(id: playerId, displayName: 'GP', isHuman: false);
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: const RegionData(),
    newWorld: const RegionData(),
    fleets: [
      Fleet(
        id: 'fleet_gp1',
        ownerId: playerId,
        seaZoneId: 'sea1',
        regionId: ow,
        shipTypeIds: ['fluyte'],
      ),
    ],
  );
  final game = Game(id: 'g1', worldState: world, players: [player]);
  final topology = MapTopology(
    nodes: const [
      TopologyNode(id: 'sea1', regionId: ow, type: TopologyNodeType.seaZone),
      TopologyNode(id: 'sea2', regionId: ow, type: TopologyNodeType.seaZone),
    ],
    edges: const [TopologyEdge(id1: 'sea1', id2: 'sea2')],
  );
  final view = buildPlayerView(game, topology, playerId);
  final suggestions = suggestNavalMoveOrders(
    view,
    game,
    topology,
    const Orders(),
  );
  expect(suggestions, isA<List<NavalMoveOrder>>());
}

void _counterSpyWorkSuggestedForSpyInOwnedProvinceWithTiles() {
  const playerId = 'gp1';
  const ow = 'oldWorld';
  final player = const Player(id: playerId, displayName: 'GP', isHuman: false);
  final p1 = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
  const tileKey = 'oldWorld|p1|0|0';
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeSpy,
    ownerId: playerId,
    locationProvinceId: '$ow|p1',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [p1], units: [unit]),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {
      playerId: {tileKey: 'fullyVisible'},
    },
    tileKeysByRegionAndProvince: {
      ow: {
        '$ow|p1': [tileKey],
      },
    },
  );
  final game = Game(id: 'g1', worldState: world, players: [player]);
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
  final view = buildPlayerView(game, topology, playerId);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  expect(
    suggestions.where((o) => o.target == kWorkTargetCounterSpy),
    isNotEmpty,
  );
}

void _purchaseLandWorkSuggestedForMerchantWhenMinorProvinceHasResourceTile() {
  const playerId = 'gp1';
  const ow = 'oldWorld';
  final player = Player(
    id: playerId,
    displayName: 'GP',
    isHuman: false,
    treasury: 500,
  );
  final ownProvince = Province(id: '$ow|p1', regionId: ow, ownerId: playerId);
  final minorProvince = Province(
    id: '$ow|minor1',
    regionId: ow,
    ownerId: 'minor1',
  );
  const tileKey = 'oldWorld|minor1|0|0';
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeMerchant,
    ownerId: playerId,
    locationProvinceId: '$ow|p1',
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(
      provinces: [ownProvince, minorProvince],
      units: [unit],
    ),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {
      playerId: {'oldWorld|p1|0|0': 'fullyVisible', tileKey: 'fullyVisible'},
    },
    tileKeysByRegionAndProvince: {
      ow: {
        '$ow|p1': ['oldWorld|p1|0|0'],
        '$ow|minor1': [tileKey],
      },
    },
    resourceByTileKey: {tileKey: 'grain'},
  );
  final game = Game(
    id: 'g1',
    worldState: world,
    players: [player],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor 1')],
    overtureStates: const [
      OvertureState(
        gpId: 'gp1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
  );
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'p1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'minor1',
        regionId: 'oldWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [],
  );
  final view = buildPlayerView(game, topology, playerId);
  final suggestions = suggestWorkOrders(view, game, topology, const Orders());
  expect(
    suggestions.where((o) => o.target == kWorkTargetPurchaseLand),
    isNotEmpty,
  );
}
