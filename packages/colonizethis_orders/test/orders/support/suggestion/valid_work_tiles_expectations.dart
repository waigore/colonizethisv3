// Compact getValidWorkOrderTileKeys / suggestWorkOrders assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'valid_work_tiles_test_support.dart';

/// Pins for [validWorkTilesScenarios] rows.
enum ValidWorkTilesTarget {
  returnsEmptyForUnknownUnitId,
  returnsEmptyWhenWorkTargetNotAllowedForUnitType,
  returnsEmptyForUnknownUnitIdWithVisibility,
  returnsEmptyWhenWorkTargetNotAllowedForUnitTypeWithVisibility,
  filtersByVisibilityBeforeOrderEngineValidation,
  buildImprovementReturnsOnlyControlledTilesWithResources,
  buildImprovementExcludesOwnedMineralTileUntilProspectedIncludesAfterProspected,
  buildImprovementIncludesPurchasedTilesWithResources,
  buildImprovementExcludesSeaZoneTiles,
  getvalidworkordertilekeyswithvisibilityProspectExcludesNonMineralAndAlreadyProspected,
  getvalidworkordertilekeyswithvisibilityProspectIncludesEligibleTile,
  getvalidworkordertilekeyswithvisibilityProspectExcludesWoolOnHillsWhenTileMapMarksHillsTerrainOnlyEligibility,
  getvalidworkordertilekeyswithvisibilityExploreOnlyScansPartiallyRevealedProvinces,
  getvalidworkordertilekeyswithvisibilityExploreRemainsUnderOneSecondOnLargeMapFixture,
  suggestmoveordersExcludesMovesToOtherGreatPowerProvinces,
  suggestworkordersSortsByTargetTileKeyWhenUnitIdAndTargetMatch,
  suggestworkordersExcludesTargetsFromExistingWorkOrdersForSameUnit,
  suggestworkordersExploreIncludesPartiallyRevealedProvinceWhenFirstSortedEntryTileIsUnknownBut,
  suggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation,
  suggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile,
  suggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral,
  suggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy,
  suggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail,
}

void runValidWorkTilesExpectation(ValidWorkTilesTarget target) {
  switch (target) {
    case ValidWorkTilesTarget.returnsEmptyForUnknownUnitId:
      _returnsEmptyForUnknownUnitId();
    case ValidWorkTilesTarget.returnsEmptyWhenWorkTargetNotAllowedForUnitType:
      _returnsEmptyWhenWorkTargetNotAllowedForUnitType();
    case ValidWorkTilesTarget.returnsEmptyForUnknownUnitIdWithVisibility:
      _returnsEmptyForUnknownUnitIdWithVisibility();
    case ValidWorkTilesTarget.returnsEmptyWhenWorkTargetNotAllowedForUnitTypeWithVisibility:
      _returnsEmptyWhenWorkTargetNotAllowedForUnitTypeWithVisibility();
    case ValidWorkTilesTarget.filtersByVisibilityBeforeOrderEngineValidation:
      _filtersByVisibilityBeforeOrderEngineValidation();
    case ValidWorkTilesTarget.buildImprovementReturnsOnlyControlledTilesWithResources:
      _buildImprovementReturnsOnlyControlledTilesWithResources();
    case ValidWorkTilesTarget.buildImprovementExcludesOwnedMineralTileUntilProspectedIncludesAfterProspected:
      _buildImprovementExcludesOwnedMineralTileUntilProspectedIncludesAfterProspected();
    case ValidWorkTilesTarget.buildImprovementIncludesPurchasedTilesWithResources:
      _buildImprovementIncludesPurchasedTilesWithResources();
    case ValidWorkTilesTarget.buildImprovementExcludesSeaZoneTiles:
      _buildImprovementExcludesSeaZoneTiles();
    case ValidWorkTilesTarget.getvalidworkordertilekeyswithvisibilityProspectExcludesNonMineralAndAlreadyProspected:
      _getvalidworkordertilekeyswithvisibilityProspectExcludesNonMineralAndAlreadyProspected();
    case ValidWorkTilesTarget.getvalidworkordertilekeyswithvisibilityProspectIncludesEligibleTile:
      _getvalidworkordertilekeyswithvisibilityProspectIncludesEligibleTile();
    case ValidWorkTilesTarget.getvalidworkordertilekeyswithvisibilityProspectExcludesWoolOnHillsWhenTileMapMarksHillsTerrainOnlyEligibility:
      _getvalidworkordertilekeyswithvisibilityProspectExcludesWoolOnHillsWhenTileMapMarksHillsTerrainOnlyEligibility();
    case ValidWorkTilesTarget.getvalidworkordertilekeyswithvisibilityExploreOnlyScansPartiallyRevealedProvinces:
      _getvalidworkordertilekeyswithvisibilityExploreOnlyScansPartiallyRevealedProvinces();
    case ValidWorkTilesTarget.getvalidworkordertilekeyswithvisibilityExploreRemainsUnderOneSecondOnLargeMapFixture:
      _getvalidworkordertilekeyswithvisibilityExploreRemainsUnderOneSecondOnLargeMapFixture();
    case ValidWorkTilesTarget.suggestmoveordersExcludesMovesToOtherGreatPowerProvinces:
      _suggestmoveordersExcludesMovesToOtherGreatPowerProvinces();
    case ValidWorkTilesTarget.suggestworkordersSortsByTargetTileKeyWhenUnitIdAndTargetMatch:
      _suggestworkordersSortsByTargetTileKeyWhenUnitIdAndTargetMatch();
    case ValidWorkTilesTarget.suggestworkordersExcludesTargetsFromExistingWorkOrdersForSameUnit:
      _suggestworkordersExcludesTargetsFromExistingWorkOrdersForSameUnit();
    case ValidWorkTilesTarget.suggestworkordersExploreIncludesPartiallyRevealedProvinceWhenFirstSortedEntryTileIsUnknownBut:
      _suggestworkordersExploreIncludesPartiallyRevealedProvinceWhenFirstSortedEntryTileIsUnknownBut();
    case ValidWorkTilesTarget.suggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation:
      _suggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation();
    case ValidWorkTilesTarget.suggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile:
      _suggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile();
    case ValidWorkTilesTarget.suggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral:
      _suggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral();
    case ValidWorkTilesTarget.suggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy:
      _suggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy();
    case ValidWorkTilesTarget.suggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail:
      _suggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail();
  }
}

void _returnsEmptyForUnknownUnitId() {

  final game = ValidWorkTilesTestSupport.minimalValidWorkTilesGame(
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince(
      {
        ValidWorkTilesTestSupport.provinceId('p1'): [
          ValidWorkTilesTestSupport.tileKey('p1', 0, 0),
        ],
      },
    ),
  );
  final valid = getValidWorkOrderTileKeys(
    game,
    ValidWorkTilesTestSupport.emptyTopology,
    ValidWorkTilesTestSupport.playerId,
    'no-such-unit',
    kWorkTargetExplore,
    const Orders(),
  );
  expect(valid, isEmpty);
}

void _returnsEmptyWhenWorkTargetNotAllowedForUnitType() {

  final provinceId = ValidWorkTilesTestSupport.provinceId('p1');
  final tile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final unit = ValidWorkTilesTestSupport.explorerUnit(
    locationProvinceId: provinceId,
    tileKey: tile,
  );
  final game = ValidWorkTilesTestSupport.minimalValidWorkTilesGame(
    oldWorld: RegionData(
      provinces: [
        Province(
          id: provinceId,
          regionId: ValidWorkTilesTestSupport.ow,
          ownerId: ValidWorkTilesTestSupport.playerId,
        ),
      ],
      units: [unit],
    ),
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince(
      {provinceId: [tile]},
    ),
  );
  final valid = getValidWorkOrderTileKeys(
    game,
    ValidWorkTilesTestSupport.emptyTopology,
    ValidWorkTilesTestSupport.playerId,
    'u1',
    kWorkTargetBuildImprovement,
    const Orders(),
  );
  expect(valid, isEmpty);
}

void _returnsEmptyForUnknownUnitIdWithVisibility() {

  final game = ValidWorkTilesTestSupport.minimalValidWorkTilesGame(
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince(
      {
        ValidWorkTilesTestSupport.provinceId('p1'): [
          ValidWorkTilesTestSupport.tileKey('p1', 0, 0),
        ],
      },
    ),
  );
  final view = buildPlayerView(
    game,
    ValidWorkTilesTestSupport.emptyTopology,
    ValidWorkTilesTestSupport.playerId,
  );
  final valid = getValidWorkOrderTileKeysWithVisibility(
    game: game,
    topology: ValidWorkTilesTestSupport.emptyTopology,
    view: view,
    unitId: 'no-such-unit',
    workTarget: kWorkTargetExplore,
    currentOrders: const Orders(),
  );
  expect(valid, isEmpty);
}

void _returnsEmptyWhenWorkTargetNotAllowedForUnitTypeWithVisibility() {

  final provinceId = ValidWorkTilesTestSupport.provinceId('p1');
  final tile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final unit = ValidWorkTilesTestSupport.explorerUnit(
    locationProvinceId: provinceId,
    tileKey: tile,
  );
  final game = ValidWorkTilesTestSupport.validWorkTilesGame(
    oldWorld: RegionData(
      provinces: [
        Province(
          id: provinceId,
          regionId: ValidWorkTilesTestSupport.ow,
          ownerId: ValidWorkTilesTestSupport.playerId,
        ),
      ],
      units: [unit],
    ),
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince(
      {provinceId: [tile]},
    ),
  );
  final view = buildPlayerView(
    game,
    ValidWorkTilesTestSupport.emptyTopology,
    ValidWorkTilesTestSupport.playerId,
  );
  final valid = getValidWorkOrderTileKeysWithVisibility(
    game: game,
    topology: ValidWorkTilesTestSupport.emptyTopology,
    view: view,
    unitId: 'u1',
    workTarget: kWorkTargetBuildImprovement,
    currentOrders: const Orders(),
  );
  expect(valid, isEmpty);
}

void _filtersByVisibilityBeforeOrderEngineValidation() {

  final p1 = ValidWorkTilesTestSupport.provinceId('p1');
  final p2 = ValidWorkTilesTestSupport.provinceId('p2');
  final tileP1 = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final tileP2 = ValidWorkTilesTestSupport.tileKey('p2', 0, 0);
  final unit = Unit(
    id: 'u1',
    type: 'Colonist',
    ownerId: ValidWorkTilesTestSupport.playerId,
    locationProvinceId: p1,
    tileKey: tileP1,
  );
  final game = ValidWorkTilesTestSupport.validWorkTilesGame(
    oldWorld: RegionData(
      provinces: [
        Province(
          id: p1,
          regionId: ValidWorkTilesTestSupport.ow,
          ownerId: ValidWorkTilesTestSupport.playerId,
        ),
      ],
      units: [unit],
    ),
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince(
      {
        p1: [tileP1],
        p2: [tileP2],
      },
    ),
  );

  final viewWithFullVisibility = buildPlayerView(
    game,
    ValidWorkTilesTestSupport.emptyTopology,
    ValidWorkTilesTestSupport.playerId,
  );

  final validWithVisibility = getValidWorkOrderTileKeysWithVisibility(
    game: game,
    topology: ValidWorkTilesTestSupport.emptyTopology,
    view: viewWithFullVisibility,
    unitId: 'u1',
    workTarget: kWorkTargetBuildImprovement,
    currentOrders: const Orders(),
  );

  final validWithoutVisibility = getValidWorkOrderTileKeys(
    game,
    ValidWorkTilesTestSupport.emptyTopology,
    ValidWorkTilesTestSupport.playerId,
    'u1',
    kWorkTargetBuildImprovement,
    const Orders(),
  );

  expect(validWithVisibility.length, validWithoutVisibility.length);
}

void _buildImprovementReturnsOnlyControlledTilesWithResources() {

  final tileWithResource = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final tileWithoutResource = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  final foreignTileWithResource = ValidWorkTilesTestSupport.tileKey('p2', 0, 0);
  final p1 = ValidWorkTilesTestSupport.provinceId('p1');
  final p2 = ValidWorkTilesTestSupport.provinceId('p2');

  final unit = ValidWorkTilesTestSupport.builderUnit(
    locationProvinceId: p1,
    tileKey: tileWithResource,
  );
  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: p1,
            regionId: ValidWorkTilesTestSupport.ow,
            ownerId: ValidWorkTilesTestSupport.playerId,
          ),
          Province(
            id: p2,
            regionId: ValidWorkTilesTestSupport.ow,
            ownerId: 'other',
          ),
        ],
        units: [unit],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince:
          ValidWorkTilesTestSupport.tileKeysByProvince(
        {
          p1: [tileWithResource, tileWithoutResource],
          p2: [foreignTileWithResource],
        },
      ),
      resourceByTileKey: {
        tileWithResource: 'grain',
        foreignTileWithResource: 'iron',
      },
      playerVisibilityByTile: {
        ValidWorkTilesTestSupport.playerId: {
          tileWithResource: 'fullyVisible',
          tileWithoutResource: 'fullyVisible',
          foreignTileWithResource: 'fullyVisible',
        },
      },
      tileState: TileMapState(improvementByTile: {tileWithResource: 0}),
    ),
    players: [
      ValidWorkTilesTestSupport.playerWithBuildStockpile(),
      const Player(id: 'other', displayName: 'Other', isHuman: false),
    ],
  );
  final topology = ValidWorkTilesTestSupport.emptyTopology;
  final view = buildPlayerView(
    game,
    topology,
    ValidWorkTilesTestSupport.playerId,
  );

  final valid = getValidWorkOrderTileKeysWithVisibility(
    game: game,
    topology: topology,
    view: view,
    unitId: 'u1',
    workTarget: kWorkTargetBuildImprovement,
    currentOrders: const Orders(),
  );

  expect(valid.contains(tileWithResource), isTrue);
  expect(valid.contains(tileWithoutResource), isFalse);
  expect(valid.contains(foreignTileWithResource), isFalse);
}

void _buildImprovementExcludesOwnedMineralTileUntilProspectedIncludesAfterProspected() {

  final grainTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  final p1 = ValidWorkTilesTestSupport.provinceId('p1');

  final unit = ValidWorkTilesTestSupport.builderUnit(
    locationProvinceId: p1,
    tileKey: grainTile,
  );
  WorldState worldForProspected(Map<String, Set<String>> prospected) {
    return WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: p1,
            regionId: ValidWorkTilesTestSupport.ow,
            ownerId: ValidWorkTilesTestSupport.playerId,
          ),
        ],
        units: [unit],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince:
          ValidWorkTilesTestSupport.tileKeysByProvince(
        {p1: [grainTile, ironTile]},
      ),
      resourceByTileKey: {grainTile: 'grain', ironTile: 'iron'},
      playerVisibilityByTile: {
        ValidWorkTilesTestSupport.playerId: {
          grainTile: 'fullyVisible',
          ironTile: 'fullyVisible',
        },
      },
      tileState: TileMapState(
        improvementByTile: {grainTile: 0, ironTile: 0},
      ),
      playerProspectedTiles: prospected,
    );
  }

  final topology = ValidWorkTilesTestSupport.emptyTopology;
  final player = ValidWorkTilesTestSupport.playerWithBuildStockpile();

  final gameUnprospected = Game(
    id: 'g1',
    worldState: worldForProspected(const {}),
    players: [player],
  );
  final viewUnprospected = buildPlayerView(
    gameUnprospected,
    topology,
    ValidWorkTilesTestSupport.playerId,
  );
  final validUnprospected = getValidWorkOrderTileKeysWithVisibility(
    game: gameUnprospected,
    topology: topology,
    view: viewUnprospected,
    unitId: 'u1',
    workTarget: kWorkTargetBuildImprovement,
    currentOrders: const Orders(),
  );
  expect(validUnprospected.contains(grainTile), isTrue);
  expect(validUnprospected.contains(ironTile), isFalse);

  final gameProspected = Game(
    id: 'g2',
    worldState: worldForProspected({
      ValidWorkTilesTestSupport.playerId: {ironTile},
    }),
    players: [player],
  );
  final viewProspected = buildPlayerView(
    gameProspected,
    topology,
    ValidWorkTilesTestSupport.playerId,
  );
  final validProspected = getValidWorkOrderTileKeysWithVisibility(
    game: gameProspected,
    topology: topology,
    view: viewProspected,
    unitId: 'u1',
    workTarget: kWorkTargetBuildImprovement,
    currentOrders: const Orders(),
  );
  expect(validProspected.contains(grainTile), isTrue);
  expect(validProspected.contains(ironTile), isTrue);
}

void _buildImprovementIncludesPurchasedTilesWithResources() {

  final purchasedTileWithResource = ValidWorkTilesTestSupport.tileKey('p2', 0, 0);
  final unpurchasedTileWithResource =
      ValidWorkTilesTestSupport.tileKey('p2', 1, 0);
  final p1 = ValidWorkTilesTestSupport.provinceId('p1');
  final p2 = ValidWorkTilesTestSupport.provinceId('p2');
  final ownTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);

  final unit = ValidWorkTilesTestSupport.builderUnit(
    locationProvinceId: p1,
    tileKey: ownTile,
  );
  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: p1,
            regionId: ValidWorkTilesTestSupport.ow,
            ownerId: ValidWorkTilesTestSupport.playerId,
          ),
          Province(
            id: p2,
            regionId: ValidWorkTilesTestSupport.ow,
            ownerId: 'minor1',
          ),
        ],
        units: [unit],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince:
          ValidWorkTilesTestSupport.tileKeysByProvince(
        {
          p1: [ownTile],
          p2: [purchasedTileWithResource, unpurchasedTileWithResource],
        },
      ),
      resourceByTileKey: {
        purchasedTileWithResource: 'grain',
        unpurchasedTileWithResource: 'grain',
      },
      purchasedTilesByTileKey: {
        purchasedTileWithResource: ValidWorkTilesTestSupport.playerId,
      },
      playerVisibilityByTile: {
        ValidWorkTilesTestSupport.playerId: {
          ownTile: 'fullyVisible',
          purchasedTileWithResource: 'fullyVisible',
          unpurchasedTileWithResource: 'fullyVisible',
        },
      },
      tileState: TileMapState(
        improvementByTile: {purchasedTileWithResource: 0},
      ),
    ),
    players: [ValidWorkTilesTestSupport.playerWithBuildStockpile()],
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
  );
  final topology = ValidWorkTilesTestSupport.emptyTopology;
  final view = buildPlayerView(
    game,
    topology,
    ValidWorkTilesTestSupport.playerId,
  );

  final valid = getValidWorkOrderTileKeysWithVisibility(
    game: game,
    topology: topology,
    view: view,
    unitId: 'u1',
    workTarget: kWorkTargetBuildImprovement,
    currentOrders: const Orders(),
  );

  expect(valid.contains(purchasedTileWithResource), isTrue);
  expect(valid.contains(unpurchasedTileWithResource), isFalse);
}

void _buildImprovementExcludesSeaZoneTiles() {

  final landTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  const seaZoneId = 's1';
  final seaTile = ValidWorkTilesTestSupport.tileKey(seaZoneId, 0, 0);
  final p1 = ValidWorkTilesTestSupport.provinceId('p1');

  final unit = ValidWorkTilesTestSupport.builderUnit(
    locationProvinceId: p1,
    tileKey: landTile,
  );
  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(
        provinces: [
          Province(
            id: p1,
            regionId: ValidWorkTilesTestSupport.ow,
            ownerId: ValidWorkTilesTestSupport.playerId,
          ),
        ],
        units: [unit],
      ),
      newWorld: const RegionData(),
      tileKeysByRegionAndProvince: {
        ValidWorkTilesTestSupport.ow: {
          p1: [landTile],
          seaZoneId: [seaTile],
        },
      },
      resourceByTileKey: {
        landTile: 'grain',
        seaTile: 'fish',
      },
      playerVisibilityByTile: {
        ValidWorkTilesTestSupport.playerId: {
          landTile: 'fullyVisible',
          seaTile: 'fullyVisible',
        },
      },
      tileState: TileMapState(improvementByTile: {landTile: 0}),
    ),
    players: [ValidWorkTilesTestSupport.playerWithBuildStockpile()],
  );
  final topology = ValidWorkTilesTestSupport.emptyTopology;
  final view = buildPlayerView(
    game,
    topology,
    ValidWorkTilesTestSupport.playerId,
  );

  final valid = getValidWorkOrderTileKeysWithVisibility(
    game: game,
    topology: topology,
    view: view,
    unitId: 'u1',
    workTarget: kWorkTargetBuildImprovement,
    currentOrders: const Orders(),
  );

  expect(valid.contains(landTile), isTrue);
  expect(valid.contains(seaTile), isFalse);
}

void _getvalidworkordertilekeyswithvisibilityProspectExcludesNonMineralAndAlreadyProspected() {

  final provinceId = ValidWorkTilesTestSupport.provinceId('p1');
  final grassTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  final p1 = Province(
    id: provinceId,
    regionId: ValidWorkTilesTestSupport.ow,
    ownerId: 'tribe1',
  );
  final unit = ValidWorkTilesTestSupport.explorerUnit(
    locationProvinceId: provinceId,
    tileKey: grassTile,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [p1], units: [unit]),
    newWorld: const RegionData(),
    playerVisibilityByTile: {
      ValidWorkTilesTestSupport.playerId: {
        grassTile: 'fogged',
        ironTile: 'fogged',
      },
    },
    resourceByTileKey: {grassTile: 'grain', ironTile: 'iron'},
    playerProspectedTiles: {
      ValidWorkTilesTestSupport.playerId: {ironTile},
    },
    tileKeysByRegionAndProvince:
        ValidWorkTilesTestSupport.tileKeysByProvince(
      {provinceId: [grassTile, ironTile]},
    ),
  );
  final game = Game(
    id: 'g1',
    worldState: world,
    players: const [ValidWorkTilesTestSupport.defaultPlayer],
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: a Consulate is required to prospect Tribe provinces.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
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
  final view = buildPlayerView(
    game,
    topology,
    ValidWorkTilesTestSupport.playerId,
  );
  final valid = getValidWorkOrderTileKeysWithVisibility(
    game: game,
    topology: topology,
    view: view,
    unitId: 'u1',
    workTarget: kWorkTargetProspect,
    currentOrders: const Orders(),
  );
  expect(valid.contains(grassTile), isFalse);
  expect(valid.contains(ironTile), isFalse);
}

void _getvalidworkordertilekeyswithvisibilityProspectIncludesEligibleTile() {

  final provinceId = ValidWorkTilesTestSupport.provinceId('p1');
  final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final p1 = Province(
    id: provinceId,
    regionId: ValidWorkTilesTestSupport.ow,
    ownerId: 'tribe1',
  );
  final unit = ValidWorkTilesTestSupport.explorerUnit(
    locationProvinceId: provinceId,
    tileKey: ironTile,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [p1], units: [unit]),
    newWorld: const RegionData(),
    playerVisibilityByTile: {
      ValidWorkTilesTestSupport.playerId: {ironTile: 'fogged'},
    },
    resourceByTileKey: {ironTile: 'iron'},
    tileKeysByRegionAndProvince:
        ValidWorkTilesTestSupport.tileKeysByProvince(
      {provinceId: [ironTile]},
    ),
  );
  final game = Game(
    id: 'g1',
    worldState: world,
    players: const [ValidWorkTilesTestSupport.defaultPlayer],
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: a Consulate is required to prospect Tribe provinces.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
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
  final view = buildPlayerView(
    game,
    topology,
    ValidWorkTilesTestSupport.playerId,
  );
  final valid = getValidWorkOrderTileKeysWithVisibility(
    game: game,
    topology: topology,
    view: view,
    unitId: 'u1',
    workTarget: kWorkTargetProspect,
    currentOrders: const Orders(),
  );
  expect(valid, contains(ironTile));
}

void _getvalidworkordertilekeyswithvisibilityProspectExcludesWoolOnHillsWhenTileMapMarksHillsTerrainOnlyEligibility() {

  final provinceId = ValidWorkTilesTestSupport.provinceId('p1');
  final woolTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final p1 = Province(
    id: provinceId,
    regionId: ValidWorkTilesTestSupport.ow,
    ownerId: 'tribe1',
  );
  final unit = ValidWorkTilesTestSupport.explorerUnit(
    locationProvinceId: provinceId,
    tileKey: woolTile,
  );
  final tileMapByRegion = <String, TileMapResult>{
    ValidWorkTilesTestSupport.ow: TileMapResult(
      width: 1,
      height: 1,
      grid: const [
        ['p1'],
      ],
      terrainGrid: const [
        [TerrainType.hills],
      ],
      resourceGrid: const [
        [Resource.wool],
      ],
    ),
  };
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [p1], units: [unit]),
    newWorld: const RegionData(),
    playerVisibilityByTile: {
      ValidWorkTilesTestSupport.playerId: {woolTile: 'fogged'},
    },
    resourceByTileKey: {woolTile: 'wool'},
    tileKeysByRegionAndProvince:
        ValidWorkTilesTestSupport.tileKeysByProvince(
      {provinceId: [woolTile]},
    ),
  );
  final game = Game(
    id: 'g1',
    worldState: world,
    players: const [ValidWorkTilesTestSupport.defaultPlayer],
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: a Consulate is required to prospect Tribe provinces.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
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
  final view = buildPlayerView(
    game,
    topology,
    ValidWorkTilesTestSupport.playerId,
  );
  final valid = getValidWorkOrderTileKeysWithVisibility(
    game: game,
    topology: topology,
    view: view,
    unitId: 'u1',
    workTarget: kWorkTargetProspect,
    currentOrders: const Orders(),
    tileMapByRegion: tileMapByRegion,
  );
  expect(valid.contains(woolTile), isFalse);
}

void _getvalidworkordertilekeyswithvisibilityExploreOnlyScansPartiallyRevealedProvinces() {

  const partialProvince = 'oldWorld|p_partial';
  const fullProvince = 'oldWorld|p_full';
  const unknownProvince = 'oldWorld|p_unknown';
  const partialKnownTile = 'oldWorld|p_partial|0|0';
  const partialUnknownTile = 'oldWorld|p_partial|1|0';
  const fullTile = 'oldWorld|p_full|0|0';
  const unknownTile = 'oldWorld|p_unknown|0|0';

  final explorer = ValidWorkTilesTestSupport.explorerUnit(
    locationProvinceId: partialProvince,
    tileKey: partialKnownTile,
  );
  final game = ValidWorkTilesTestSupport.minimalValidWorkTilesGame(
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: explore/prospect in a Tribe province require a
    // Consulate (or higher); the suggestion path shares the work-order
    // validator, so a consulate is needed for these tiles to be valid.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
    oldWorld: RegionData(
      provinces: [
        Province(
          id: partialProvince,
          regionId: ValidWorkTilesTestSupport.ow,
          ownerId: 'tribe1',
        ),
        Province(
          id: fullProvince,
          regionId: ValidWorkTilesTestSupport.ow,
          ownerId: 'tribe1',
        ),
        Province(
          id: unknownProvince,
          regionId: ValidWorkTilesTestSupport.ow,
          ownerId: 'tribe1',
        ),
      ],
      units: [explorer],
    ),
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince(
      {
        partialProvince: [partialKnownTile, partialUnknownTile],
        fullProvince: [fullTile],
        unknownProvince: [unknownTile],
      },
    ),
    playerVisibilityByTile: const {
      ValidWorkTilesTestSupport.playerId: {
        partialKnownTile: 'fogged',
        fullTile: 'fullyVisible',
        unknownTile: 'unknown',
      },
    },
  );
  final view = buildPlayerView(
    game,
    ValidWorkTilesTestSupport.emptyTopology,
    ValidWorkTilesTestSupport.playerId,
  );

  final valid = getValidWorkOrderTileKeysWithVisibility(
    game: game,
    topology: ValidWorkTilesTestSupport.emptyTopology,
    view: view,
    unitId: 'u1',
    workTarget: kWorkTargetExplore,
    currentOrders: const Orders(),
  );

  expect(valid, contains(partialKnownTile));
  expect(valid, isNot(contains(fullTile)));
  expect(valid, isNot(contains(unknownTile)));
}

void _getvalidworkordertilekeyswithvisibilityExploreRemainsUnderOneSecondOnLargeMapFixture() {

  const provinceCount = 120;
  const tilesPerProvince = 12;
  final byProvince = <String, List<String>>{};
  final visibility = <String, String>{};
  final provinces = <Province>[];

  for (var p = 0; p < provinceCount; p++) {
    final provinceId = ValidWorkTilesTestSupport.provinceId('p$p');
    provinces.add(
      Province(
        id: provinceId,
        regionId: ValidWorkTilesTestSupport.ow,
        ownerId: 'tribe1',
      ),
    );
    final tiles = <String>[];
    for (var t = 0; t < tilesPerProvince; t++) {
      final tileKey = ValidWorkTilesTestSupport.tileKey('p$p', t, 0);
      tiles.add(tileKey);
      if (p.isEven && t == 0) {
        visibility[tileKey] = 'fogged';
      } else if (p.isEven && t == 1) {
        visibility[tileKey] = 'unknown';
      } else {
        visibility[tileKey] = 'unknown';
      }
    }
    byProvince[provinceId] = tiles;
  }

  final startTile = ValidWorkTilesTestSupport.tileKey('p0', 0, 0);
  final explorer = ValidWorkTilesTestSupport.explorerUnit(
    locationProvinceId: ValidWorkTilesTestSupport.provinceId('p0'),
    tileKey: startTile,
  );
  final game = ValidWorkTilesTestSupport.validWorkTilesGame(
    id: 'g-latency',
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: a Consulate is required to explore Tribe provinces.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
    oldWorld: RegionData(provinces: provinces, units: [explorer]),
    tileKeysByRegionAndProvince:
        ValidWorkTilesTestSupport.tileKeysByProvince(byProvince),
    playerVisibilityByTile: {
      ValidWorkTilesTestSupport.playerId: visibility,
    },
  );
  final view = buildPlayerView(
    game,
    ValidWorkTilesTestSupport.emptyTopology,
    ValidWorkTilesTestSupport.playerId,
  );

  final sw = Stopwatch()..start();
  final valid = getValidWorkOrderTileKeysWithVisibility(
    game: game,
    topology: ValidWorkTilesTestSupport.emptyTopology,
    view: view,
    unitId: 'u1',
    workTarget: kWorkTargetExplore,
    currentOrders: const Orders(),
  );
  sw.stop();

  expect(valid, isNotEmpty);
  expect(sw.elapsedMilliseconds, lessThan(1000));
}

void _suggestmoveordersExcludesMovesToOtherGreatPowerProvinces() {

  const otherGpId = 'gp2';
  final player = ValidWorkTilesTestSupport.defaultPlayer;
  final otherGp = const Player(
    id: otherGpId,
    displayName: 'Other GP',
    isHuman: false,
  );

  final p1 = Province(
    id: ValidWorkTilesTestSupport.provinceId('p1'),
    regionId: ValidWorkTilesTestSupport.ow,
    ownerId: ValidWorkTilesTestSupport.playerId,
  );
  final p2 = Province(
    id: ValidWorkTilesTestSupport.provinceId('p2'),
    regionId: ValidWorkTilesTestSupport.ow,
    ownerId: otherGpId,
  );
  final unit = ValidWorkTilesTestSupport.builderUnit(
    locationProvinceId: ValidWorkTilesTestSupport.provinceId('p1'),
  );

  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [p1, p2], units: [unit]),
    newWorld: const RegionData(),
    playerVisibilityByTile: const {
      ValidWorkTilesTestSupport.playerId: {
        'oldWorld|p1|0|0': 'fullyVisible',
        'oldWorld|p2|0|0': 'fullyVisible',
      },
    },
  );
  final game = Game(
    id: 'g1',
    worldState: world,
    players: [player, otherGp],
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
    edges: const [TopologyEdge(id1: 'p1', id2: 'p2')],
  );

  final view = buildPlayerView(
    game,
    topology,
    ValidWorkTilesTestSupport.playerId,
  );
  final suggestions = suggestMoveOrders(
    view,
    game,
    topology,
    const Orders(),
  );
  expect(
    suggestions.where(
      (m) =>
          Unit.provinceIdFromTileKey(m.destinationTileKey) ==
          ValidWorkTilesTestSupport.provinceId('p2'),
    ),
    isEmpty,
  );
}

void _suggestworkordersSortsByTargetTileKeyWhenUnitIdAndTargetMatch() {

  final p1 = ValidWorkTilesTestSupport.provinceId('p1');
  final tile0 = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final tile1 = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  final tile2 = ValidWorkTilesTestSupport.tileKey('p1', 2, 0);

  final province = Province(
    id: p1,
    regionId: ValidWorkTilesTestSupport.ow,
    ownerId: ValidWorkTilesTestSupport.playerId,
  );
  final builder = ValidWorkTilesTestSupport.builderUnit(
    locationProvinceId: p1,
    tileKey: tile0,
  );

  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [province], units: [builder]),
    newWorld: const RegionData(),
    playerVisibilityByTile: {
      ValidWorkTilesTestSupport.playerId: {
        tile0: 'fullyVisible',
        tile1: 'fullyVisible',
        tile2: 'fullyVisible',
      },
    },
    tileKeysByRegionAndProvince:
        ValidWorkTilesTestSupport.tileKeysByProvince(
      {p1: [tile0, tile1, tile2]},
    ),
    resourceByTileKey: {tile0: 'grain', tile1: 'grain', tile2: 'grain'},
    tileState: TileMapState(
      improvementByTile: {tile0: 0, tile1: 0, tile2: 0},
    ),
  );

  final game = Game(
    id: 'g1',
    worldState: world,
    players: [ValidWorkTilesTestSupport.playerWithTreasury()],
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

  final view = buildPlayerView(
    game,
    topology,
    ValidWorkTilesTestSupport.playerId,
  );
  final suggestions = suggestWorkOrders(
    view,
    game,
    topology,
    const Orders(),
  );
  final buildSuggestions = suggestions
      .where((o) => o.target == kWorkTargetBuildImprovement)
      .toList();

  if (buildSuggestions.length > 1) {
    for (int i = 0; i < buildSuggestions.length - 1; i++) {
      expect(
        buildSuggestions[i].targetTileKey.compareTo(
          buildSuggestions[i + 1].targetTileKey,
        ),
        lessThanOrEqualTo(0),
      );
    }
  }
}

void _suggestworkordersExcludesTargetsFromExistingWorkOrdersForSameUnit() {

  final p1 = ValidWorkTilesTestSupport.provinceId('p1');
  final tile0 = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final tile1 = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);

  final province = Province(
    id: p1,
    regionId: ValidWorkTilesTestSupport.ow,
    ownerId: ValidWorkTilesTestSupport.playerId,
  );
  final builder = ValidWorkTilesTestSupport.builderUnit(
    locationProvinceId: p1,
    tileKey: tile0,
  );
  final existingOrder = WorkOrder(
    unitId: 'u1',
    target: kWorkTargetBuildImprovement,
    targetTileKey: tile0,
  );

  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: RegionData(provinces: [province], units: [builder]),
    newWorld: const RegionData(),
    playerVisibilityByTile: {
      ValidWorkTilesTestSupport.playerId: {
        tile0: 'fullyVisible',
        tile1: 'fullyVisible',
      },
    },
    tileKeysByRegionAndProvince:
        ValidWorkTilesTestSupport.tileKeysByProvince(
      {p1: [tile0, tile1]},
    ),
    resourceByTileKey: {tile0: 'grain', tile1: 'grain'},
    tileState: TileMapState(
      improvementByTile: {tile0: 0, tile1: 0},
    ),
  );

  final game = Game(
    id: 'g1',
    worldState: world,
    players: [ValidWorkTilesTestSupport.playerWithTreasury()],
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

  final view = buildPlayerView(
    game,
    topology,
    ValidWorkTilesTestSupport.playerId,
  );
  final currentOrders = Orders(
    workOrdersByPlayerId: {
      ValidWorkTilesTestSupport.playerId: [existingOrder],
    },
  );
  final suggestions = suggestWorkOrders(
    view,
    game,
    topology,
    currentOrders,
  );

  final buildSuggestions = suggestions
      .where(
        (o) =>
            o.target == kWorkTargetBuildImprovement &&
            o.targetTileKey == tile0,
      )
      .toList();
  expect(buildSuggestions, isEmpty);
}

void _suggestworkordersExploreIncludesPartiallyRevealedProvinceWhenFirstSortedEntryTileIsUnknownBut() {

  final provHome = ValidWorkTilesTestSupport.provinceId(
    'home',
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final provTarget = ValidWorkTilesTestSupport.provinceId(
    'tribe1',
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final tileHome = ValidWorkTilesTestSupport.tileKey(
    'home',
    0,
    0,
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final t0 = ValidWorkTilesTestSupport.tileKey(
    'tribe1',
    0,
    0,
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final t1 = ValidWorkTilesTestSupport.tileKey(
    'tribe1',
    1,
    0,
    regionId: ValidWorkTilesTestSupport.nw,
  );

  final pHome = Province(
    id: provHome,
    regionId: ValidWorkTilesTestSupport.nw,
    ownerId: ValidWorkTilesTestSupport.playerId,
  );
  final pTarget = Province(
    id: provTarget,
    regionId: ValidWorkTilesTestSupport.nw,
    ownerId: 'tribe1',
  );
  final explorer = ValidWorkTilesTestSupport.explorerUnit(
    id: 'ex1',
    locationProvinceId: provHome,
    tileKey: tileHome,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: const RegionData(),
    newWorld: RegionData(provinces: [pHome, pTarget], units: [explorer]),
    tileKeysByRegionAndProvince:
        ValidWorkTilesTestSupport.tileKeysByProvince(
      {
        provHome: [tileHome],
        provTarget: [t0, t1],
      },
      regionId: ValidWorkTilesTestSupport.nw,
    ),
    playerVisibilityByTile: {
      ValidWorkTilesTestSupport.playerId: {
        tileHome: 'fullyVisible',
        t0: 'unknown',
        t1: 'fogged',
      },
    },
  );
  final game = Game(
    id: 'g1916e1',
    worldState: world,
    players: const [ValidWorkTilesTestSupport.defaultPlayer],
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: a Consulate is required to explore Tribe provinces.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
  );
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'home',
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'tribe1',
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [TopologyEdge(id1: 'home', id2: 'tribe1')],
  );
  final view = buildPlayerView(
    game,
    topology,
    ValidWorkTilesTestSupport.playerId,
  );
  final suggestions = suggestWorkOrders(
    view,
    game,
    topology,
    const Orders(),
  );
  final explore = suggestions
      .where((o) => o.target == kWorkTargetExplore)
      .toList();
  expect(explore, isNotEmpty);
  expect(
    explore.any(
      (o) => Unit.provinceIdFromTileKey(o.targetTileKey) == provTarget,
    ),
    isTrue,
  );
}

void _suggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation() {

  final provHome = ValidWorkTilesTestSupport.provinceId(
    'home',
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final provTarget = ValidWorkTilesTestSupport.provinceId(
    'gp2p',
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final tileHome = ValidWorkTilesTestSupport.tileKey(
    'home',
    0,
    0,
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final t0 = ValidWorkTilesTestSupport.tileKey(
    'gp2p',
    0,
    0,
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final t1 = ValidWorkTilesTestSupport.tileKey(
    'gp2p',
    1,
    0,
    regionId: ValidWorkTilesTestSupport.nw,
  );

  final gp2 = const Player(id: 'gp2', displayName: 'P2', isHuman: false);
  final pHome = Province(
    id: provHome,
    regionId: ValidWorkTilesTestSupport.nw,
    ownerId: ValidWorkTilesTestSupport.playerId,
  );
  final pTarget = Province(
    id: provTarget,
    regionId: ValidWorkTilesTestSupport.nw,
    ownerId: 'gp2',
  );
  final explorer = ValidWorkTilesTestSupport.explorerUnit(
    id: 'ex1',
    locationProvinceId: provHome,
    tileKey: tileHome,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: const RegionData(),
    newWorld: RegionData(provinces: [pHome, pTarget], units: [explorer]),
    tileKeysByRegionAndProvince:
        ValidWorkTilesTestSupport.tileKeysByProvince(
      {
        provHome: [tileHome],
        provTarget: [t0, t1],
      },
      regionId: ValidWorkTilesTestSupport.nw,
    ),
    playerVisibilityByTile: {
      ValidWorkTilesTestSupport.playerId: {
        tileHome: 'fullyVisible',
        t0: 'unknown',
        t1: 'fogged',
      },
    },
  );
  final game = Game(
    id: 'g1916e2',
    worldState: world,
    players: [ValidWorkTilesTestSupport.defaultPlayer, gp2],
  );
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'home',
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'gp2p',
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [TopologyEdge(id1: 'home', id2: 'gp2p')],
  );
  final view = buildPlayerView(
    game,
    topology,
    ValidWorkTilesTestSupport.playerId,
  );
  final suggestions = suggestWorkOrders(
    view,
    game,
    topology,
    const Orders(),
  );
  expect(
    suggestions.where(
      (o) =>
          o.target == kWorkTargetExplore &&
          Unit.provinceIdFromTileKey(o.targetTileKey) == provTarget,
    ),
    isEmpty,
  );
}

void _suggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile() {

  final provHome = ValidWorkTilesTestSupport.provinceId(
    'home',
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final provTarget = ValidWorkTilesTestSupport.provinceId(
    'tribe1',
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final tileHome = ValidWorkTilesTestSupport.tileKey(
    'home',
    0,
    0,
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final t0 = ValidWorkTilesTestSupport.tileKey(
    'tribe1',
    0,
    0,
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final t1 = ValidWorkTilesTestSupport.tileKey(
    'tribe1',
    1,
    0,
    regionId: ValidWorkTilesTestSupport.nw,
  );

  final pHome = Province(
    id: provHome,
    regionId: ValidWorkTilesTestSupport.nw,
    ownerId: ValidWorkTilesTestSupport.playerId,
  );
  final pTarget = Province(
    id: provTarget,
    regionId: ValidWorkTilesTestSupport.nw,
    ownerId: 'tribe1',
  );
  final explorer = ValidWorkTilesTestSupport.explorerUnit(
    id: 'ex1',
    locationProvinceId: provHome,
    tileKey: tileHome,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: const RegionData(),
    newWorld: RegionData(provinces: [pHome, pTarget], units: [explorer]),
    tileKeysByRegionAndProvince:
        ValidWorkTilesTestSupport.tileKeysByProvince(
      {
        provHome: [tileHome],
        provTarget: [t0, t1],
      },
      regionId: ValidWorkTilesTestSupport.nw,
    ),
    resourceByTileKey: {t0: 'grain', t1: 'iron'},
    playerVisibilityByTile: {
      ValidWorkTilesTestSupport.playerId: {
        tileHome: 'fullyVisible',
        t0: 'unknown',
        t1: 'fogged',
      },
    },
  );
  final game = Game(
    id: 'g1916p1',
    worldState: world,
    players: const [ValidWorkTilesTestSupport.defaultPlayer],
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: a Consulate is required to prospect Tribe provinces.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
  );
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'home',
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'tribe1',
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [TopologyEdge(id1: 'home', id2: 'tribe1')],
  );
  final view = buildPlayerView(
    game,
    topology,
    ValidWorkTilesTestSupport.playerId,
  );
  final suggestions = suggestWorkOrders(
    view,
    game,
    topology,
    const Orders(),
  );
  final prospect = suggestions
      .where((o) => o.target == kWorkTargetProspect)
      .toList();
  expect(prospect, isNotEmpty);
  expect(prospect.any((o) => o.targetTileKey == t1), isTrue);
}

void _suggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral() {

  final provHome = ValidWorkTilesTestSupport.provinceId(
    'home',
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final provTarget = ValidWorkTilesTestSupport.provinceId(
    'tribe1',
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final tileHome = ValidWorkTilesTestSupport.tileKey(
    'home',
    0,
    0,
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final t0 = ValidWorkTilesTestSupport.tileKey(
    'tribe1',
    0,
    0,
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final t1 = ValidWorkTilesTestSupport.tileKey(
    'tribe1',
    1,
    0,
    regionId: ValidWorkTilesTestSupport.nw,
  );

  final pHome = Province(
    id: provHome,
    regionId: ValidWorkTilesTestSupport.nw,
    ownerId: ValidWorkTilesTestSupport.playerId,
  );
  final pTarget = Province(
    id: provTarget,
    regionId: ValidWorkTilesTestSupport.nw,
    ownerId: 'tribe1',
  );
  final explorer = ValidWorkTilesTestSupport.explorerUnit(
    id: 'ex1',
    locationProvinceId: provHome,
    tileKey: tileHome,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: const RegionData(),
    newWorld: RegionData(provinces: [pHome, pTarget], units: [explorer]),
    tileKeysByRegionAndProvince:
        ValidWorkTilesTestSupport.tileKeysByProvince(
      {
        provHome: [tileHome],
        provTarget: [t0, t1],
      },
      regionId: ValidWorkTilesTestSupport.nw,
    ),
    resourceByTileKey: {t0: 'grain', t1: 'iron'},
    playerProspectedTiles: {
      ValidWorkTilesTestSupport.playerId: {t1},
    },
    playerVisibilityByTile: {
      ValidWorkTilesTestSupport.playerId: {
        tileHome: 'fullyVisible',
        t0: 'unknown',
        t1: 'fogged',
      },
    },
  );
  final game = Game(
    id: 'g1916p2',
    worldState: world,
    players: const [ValidWorkTilesTestSupport.defaultPlayer],
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: a Consulate is required to prospect Tribe provinces.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
  );
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'home',
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'tribe1',
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [TopologyEdge(id1: 'home', id2: 'tribe1')],
  );
  final view = buildPlayerView(
    game,
    topology,
    ValidWorkTilesTestSupport.playerId,
  );
  final suggestions = suggestWorkOrders(
    view,
    game,
    topology,
    const Orders(),
  );
  expect(
    suggestions.where((o) => o.target == kWorkTargetProspect),
    isEmpty,
  );
}

void _suggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy() {

  final provOwn = ValidWorkTilesTestSupport.provinceId(
    'own',
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final provMinor = ValidWorkTilesTestSupport.provinceId(
    'm1',
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final tileOwn = ValidWorkTilesTestSupport.tileKey(
    'own',
    0,
    0,
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final m0 = ValidWorkTilesTestSupport.tileKey(
    'm1',
    0,
    0,
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final m1 = ValidWorkTilesTestSupport.tileKey(
    'm1',
    1,
    0,
    regionId: ValidWorkTilesTestSupport.nw,
  );

  final pOwn = Province(
    id: provOwn,
    regionId: ValidWorkTilesTestSupport.nw,
    ownerId: ValidWorkTilesTestSupport.playerId,
  );
  final pMinor = Province(
    id: provMinor,
    regionId: ValidWorkTilesTestSupport.nw,
    ownerId: 'minor1',
  );
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeMerchant,
    ownerId: ValidWorkTilesTestSupport.playerId,
    locationProvinceId: provOwn,
    tileKey: tileOwn,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: const RegionData(),
    newWorld: RegionData(provinces: [pOwn, pMinor], units: [unit]),
    tileKeysByRegionAndProvince:
        ValidWorkTilesTestSupport.tileKeysByProvince(
      {
        provOwn: [tileOwn],
        provMinor: [m0, m1],
      },
      regionId: ValidWorkTilesTestSupport.nw,
    ),
    resourceByTileKey: {m1: 'grain'},
    playerVisibilityByTile: {
      ValidWorkTilesTestSupport.playerId: {
        tileOwn: 'fullyVisible',
        m0: 'unknown',
        m1: 'fogged',
      },
    },
  );
  final game = Game(
    id: 'g1916pl1',
    worldState: world,
    players: [ValidWorkTilesTestSupport.playerWithTreasury()],
    minorNations: const [
      MinorNation(id: 'minor1', displayName: 'Minor 1'),
    ],
    overtureStates: [ValidWorkTilesTestSupport.embassyOverture()],
  );
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'own',
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'm1',
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [TopologyEdge(id1: 'own', id2: 'm1')],
  );
  final view = buildPlayerView(
    game,
    topology,
    ValidWorkTilesTestSupport.playerId,
  );
  final suggestions = suggestWorkOrders(
    view,
    game,
    topology,
    const Orders(),
  );
  expect(
    suggestions.where(
      (o) =>
          o.target == kWorkTargetPurchaseLand &&
          Unit.provinceIdFromTileKey(o.targetTileKey) == provMinor,
    ),
    isNotEmpty,
  );
}

void _suggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail() {

  final provOwn = ValidWorkTilesTestSupport.provinceId(
    'own',
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final provMinor = ValidWorkTilesTestSupport.provinceId(
    'm1',
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final tileOwn = ValidWorkTilesTestSupport.tileKey(
    'own',
    0,
    0,
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final m0 = ValidWorkTilesTestSupport.tileKey(
    'm1',
    0,
    0,
    regionId: ValidWorkTilesTestSupport.nw,
  );
  final m1 = ValidWorkTilesTestSupport.tileKey(
    'm1',
    1,
    0,
    regionId: ValidWorkTilesTestSupport.nw,
  );

  final pOwn = Province(
    id: provOwn,
    regionId: ValidWorkTilesTestSupport.nw,
    ownerId: ValidWorkTilesTestSupport.playerId,
  );
  final pMinor = Province(
    id: provMinor,
    regionId: ValidWorkTilesTestSupport.nw,
    ownerId: 'minor1',
  );
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeMerchant,
    ownerId: ValidWorkTilesTestSupport.playerId,
    locationProvinceId: provOwn,
    tileKey: tileOwn,
  );
  final world = WorldState(
    turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
    oldWorld: const RegionData(),
    newWorld: RegionData(provinces: [pOwn, pMinor], units: [unit]),
    tileKeysByRegionAndProvince:
        ValidWorkTilesTestSupport.tileKeysByProvince(
      {
        provOwn: [tileOwn],
        provMinor: [m0, m1],
      },
      regionId: ValidWorkTilesTestSupport.nw,
    ),
    resourceByTileKey: {m1: 'grain'},
    playerVisibilityByTile: {
      ValidWorkTilesTestSupport.playerId: {
        tileOwn: 'fullyVisible',
        m0: 'unknown',
        m1: 'fogged',
      },
    },
  );
  final game = Game(
    id: 'g1916pl2',
    worldState: world,
    players: [ValidWorkTilesTestSupport.playerWithTreasury()],
    minorNations: const [
      MinorNation(id: 'minor1', displayName: 'Minor 1'),
    ],
  );
  final topology = MapTopology(
    nodes: const [
      TopologyNode(
        id: 'own',
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
      TopologyNode(
        id: 'm1',
        regionId: 'newWorld',
        type: TopologyNodeType.province,
      ),
    ],
    edges: const [TopologyEdge(id1: 'own', id2: 'm1')],
  );
  final view = buildPlayerView(
    game,
    topology,
    ValidWorkTilesTestSupport.playerId,
  );
  final suggestions = suggestWorkOrders(
    view,
    game,
    topology,
    const Orders(),
  );
  expect(
    suggestions.where(
      (o) =>
          o.target == kWorkTargetPurchaseLand &&
          Unit.provinceIdFromTileKey(o.targetTileKey) == provMinor,
    ),
    isEmpty,
  );
}

