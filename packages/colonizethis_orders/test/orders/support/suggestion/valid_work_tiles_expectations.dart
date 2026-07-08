// Compact getValidWorkOrderTileKeys / suggestWorkOrders assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'valid_work_tiles_fixtures.dart';
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

Province _ownedProvince(String localId) => Province(
  id: ValidWorkTilesTestSupport.provinceId(localId),
  regionId: ValidWorkTilesTestSupport.ow,
  ownerId: ValidWorkTilesTestSupport.playerId,
);

Province _province(String localId, String ownerId) => Province(
  id: ValidWorkTilesTestSupport.provinceId(localId),
  regionId: ValidWorkTilesTestSupport.ow,
  ownerId: ownerId,
);

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
      provinces: [_ownedProvince('p1')],
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
  expect(
    validWorkTilesWithVisibility(
      game: game,
      topology: ValidWorkTilesTestSupport.emptyTopology,
      unitId: 'no-such-unit',
      workTarget: kWorkTargetExplore,
    ),
    isEmpty,
  );
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
      provinces: [_ownedProvince('p1')],
      units: [unit],
    ),
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince(
      {provinceId: [tile]},
    ),
  );
  expect(
    validWorkTilesWithVisibility(
      game: game,
      topology: ValidWorkTilesTestSupport.emptyTopology,
      unitId: 'u1',
      workTarget: kWorkTargetBuildImprovement,
    ),
    isEmpty,
  );
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
      provinces: [_ownedProvince('p1')],
      units: [unit],
    ),
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince(
      {
        p1: [tileP1],
        p2: [tileP2],
      },
    ),
  );
  final topology = ValidWorkTilesTestSupport.emptyTopology;
  final withVis = validWorkTilesWithVisibility(
    game: game,
    topology: topology,
    unitId: 'u1',
    workTarget: kWorkTargetBuildImprovement,
  );
  final withoutVis = getValidWorkOrderTileKeys(
    game,
    topology,
    ValidWorkTilesTestSupport.playerId,
    'u1',
    kWorkTargetBuildImprovement,
    const Orders(),
  );
  expect(withVis.length, withoutVis.length);
}

void _buildImprovementReturnsOnlyControlledTilesWithResources() {
  final tileWithResource = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final tileWithoutResource = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  final foreignTileWithResource = ValidWorkTilesTestSupport.tileKey('p2', 0, 0);
  final game = owBuilderVisibilityGame(
    provinces: [_ownedProvince('p1'), _province('p2', 'other')],
    tilesByProvince: {
      ValidWorkTilesTestSupport.provinceId('p1'): [
        tileWithResource,
        tileWithoutResource,
      ],
      ValidWorkTilesTestSupport.provinceId('p2'): [foreignTileWithResource],
    },
    resourceByTileKey: {
      tileWithResource: 'grain',
      foreignTileWithResource: 'iron',
    },
    builderTileKey: tileWithResource,
    improvementByTile: {tileWithResource: 0},
    extraPlayers: const [
      Player(id: 'other', displayName: 'Other', isHuman: false),
    ],
  );
  final valid = validWorkTilesWithVisibility(
    game: game,
    topology: ValidWorkTilesTestSupport.emptyTopology,
    unitId: 'u1',
    workTarget: kWorkTargetBuildImprovement,
  );
  expect(valid.contains(tileWithResource), isTrue);
  expect(valid.contains(tileWithoutResource), isFalse);
  expect(valid.contains(foreignTileWithResource), isFalse);
}

void _buildImprovementExcludesOwnedMineralTileUntilProspectedIncludesAfterProspected() {
  final grainTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  final p1 = ValidWorkTilesTestSupport.provinceId('p1');
  final tiles = {p1: [grainTile, ironTile]};
  final resources = {grainTile: 'grain', ironTile: 'iron'};
  final improvements = {grainTile: 0, ironTile: 0};
  final provinces = [_ownedProvince('p1')];
  final topology = ValidWorkTilesTestSupport.emptyTopology;

  final unprospected = owBuilderVisibilityGame(
    provinces: provinces,
    tilesByProvince: tiles,
    resourceByTileKey: resources,
    builderTileKey: grainTile,
    improvementByTile: improvements,
  );
  final validUnprospected = validWorkTilesWithVisibility(
    game: unprospected,
    topology: topology,
    unitId: 'u1',
    workTarget: kWorkTargetBuildImprovement,
  );
  expect(validUnprospected.contains(grainTile), isTrue);
  expect(validUnprospected.contains(ironTile), isFalse);

  final prospected = owBuilderVisibilityGame(
    provinces: provinces,
    tilesByProvince: tiles,
    resourceByTileKey: resources,
    builderTileKey: grainTile,
    improvementByTile: improvements,
    playerProspectedTiles: {
      ValidWorkTilesTestSupport.playerId: {ironTile},
    },
  );
  final validProspected = validWorkTilesWithVisibility(
    game: prospected,
    topology: topology,
    unitId: 'u1',
    workTarget: kWorkTargetBuildImprovement,
  );
  expect(validProspected.contains(grainTile), isTrue);
  expect(validProspected.contains(ironTile), isTrue);
}

void _buildImprovementIncludesPurchasedTilesWithResources() {
  final purchased = ValidWorkTilesTestSupport.tileKey('p2', 0, 0);
  final unpurchased = ValidWorkTilesTestSupport.tileKey('p2', 1, 0);
  final ownTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final game = owBuilderVisibilityGame(
    provinces: [_ownedProvince('p1'), _province('p2', 'minor1')],
    tilesByProvince: {
      ValidWorkTilesTestSupport.provinceId('p1'): [ownTile],
      ValidWorkTilesTestSupport.provinceId('p2'): [purchased, unpurchased],
    },
    resourceByTileKey: {purchased: 'grain', unpurchased: 'grain'},
    builderTileKey: ownTile,
    purchasedTilesByTileKey: {
      purchased: ValidWorkTilesTestSupport.playerId,
    },
    improvementByTile: {purchased: 0},
    minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
  );
  final valid = validWorkTilesWithVisibility(
    game: game,
    topology: ValidWorkTilesTestSupport.emptyTopology,
    unitId: 'u1',
    workTarget: kWorkTargetBuildImprovement,
  );
  expect(valid.contains(purchased), isTrue);
  expect(valid.contains(unpurchased), isFalse);
}

void _buildImprovementExcludesSeaZoneTiles() {
  final landTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  const seaZoneId = 's1';
  final seaTile = ValidWorkTilesTestSupport.tileKey(seaZoneId, 0, 0);
  final game = owBuilderVisibilityGame(
    provinces: [_ownedProvince('p1')],
    tilesByProvince: {
      ValidWorkTilesTestSupport.provinceId('p1'): [landTile],
    },
    resourceByTileKey: {landTile: 'grain', seaTile: 'fish'},
    builderTileKey: landTile,
    improvementByTile: {landTile: 0},
    seaZoneId: seaZoneId,
    seaTiles: [seaTile],
  );
  final valid = validWorkTilesWithVisibility(
    game: game,
    topology: ValidWorkTilesTestSupport.emptyTopology,
    unitId: 'u1',
    workTarget: kWorkTargetBuildImprovement,
  );
  expect(valid.contains(landTile), isTrue);
  expect(valid.contains(seaTile), isFalse);
}

void _getvalidworkordertilekeyswithvisibilityProspectExcludesNonMineralAndAlreadyProspected() {
  final grassTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  final game = owTribeProspectGame(
    provinceLocalId: 'p1',
    tileKeys: [grassTile, ironTile],
    resourceByTileKey: {grassTile: 'grain', ironTile: 'iron'},
    visibilityByTile: {grassTile: 'fogged', ironTile: 'fogged'},
    playerProspectedTiles: {
      ValidWorkTilesTestSupport.playerId: {ironTile},
    },
  );
  final topology = owSingleProvinceTopology('p1');
  final valid = validWorkTilesWithVisibility(
    game: game,
    topology: topology,
    unitId: 'u1',
    workTarget: kWorkTargetProspect,
  );
  expect(valid.contains(grassTile), isFalse);
  expect(valid.contains(ironTile), isFalse);
}

void _getvalidworkordertilekeyswithvisibilityProspectIncludesEligibleTile() {
  final ironTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final game = owTribeProspectGame(
    provinceLocalId: 'p1',
    tileKeys: [ironTile],
    resourceByTileKey: {ironTile: 'iron'},
    visibilityByTile: {ironTile: 'fogged'},
  );
  final valid = validWorkTilesWithVisibility(
    game: game,
    topology: owSingleProvinceTopology('p1'),
    unitId: 'u1',
    workTarget: kWorkTargetProspect,
  );
  expect(valid, contains(ironTile));
}

void _getvalidworkordertilekeyswithvisibilityProspectExcludesWoolOnHillsWhenTileMapMarksHillsTerrainOnlyEligibility() {
  final woolTile = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
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
  final game = owTribeProspectGame(
    provinceLocalId: 'p1',
    tileKeys: [woolTile],
    resourceByTileKey: {woolTile: 'wool'},
    visibilityByTile: {woolTile: 'fogged'},
  );
  final valid = validWorkTilesWithVisibility(
    game: game,
    topology: owSingleProvinceTopology('p1'),
    unitId: 'u1',
    workTarget: kWorkTargetProspect,
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
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince({
      partialProvince: [partialKnownTile, partialUnknownTile],
      fullProvince: [fullTile],
      unknownProvince: [unknownTile],
    }),
    playerVisibilityByTile: const {
      ValidWorkTilesTestSupport.playerId: {
        partialKnownTile: 'fogged',
        fullTile: 'fullyVisible',
        unknownTile: 'unknown',
      },
    },
  );
  final valid = validWorkTilesWithVisibility(
    game: game,
    topology: ValidWorkTilesTestSupport.emptyTopology,
    unitId: 'u1',
    workTarget: kWorkTargetExplore,
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
      visibility[tileKey] = (p.isEven && t == 0) ? 'fogged' : 'unknown';
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
  final sw = Stopwatch()..start();
  final valid = validWorkTilesWithVisibility(
    game: game,
    topology: ValidWorkTilesTestSupport.emptyTopology,
    unitId: 'u1',
    workTarget: kWorkTargetExplore,
  );
  sw.stop();
  expect(valid, isNotEmpty);
  expect(sw.elapsedMilliseconds, lessThan(1000));
}

void _suggestmoveordersExcludesMovesToOtherGreatPowerProvinces() {
  const otherGpId = 'gp2';
  final p1 = _ownedProvince('p1');
  final p2 = _province('p2', otherGpId);
  final unit = ValidWorkTilesTestSupport.builderUnit(
    locationProvinceId: ValidWorkTilesTestSupport.provinceId('p1'),
  );
  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
      oldWorld: RegionData(provinces: [p1, p2], units: [unit]),
      newWorld: const RegionData(),
      playerVisibilityByTile: const {
        ValidWorkTilesTestSupport.playerId: {
          'oldWorld|p1|0|0': 'fullyVisible',
          'oldWorld|p2|0|0': 'fullyVisible',
        },
      },
    ),
    players: [
      ValidWorkTilesTestSupport.defaultPlayer,
      const Player(id: otherGpId, displayName: 'Other GP', isHuman: false),
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
  final tiles = [
    ValidWorkTilesTestSupport.tileKey('p1', 0, 0),
    ValidWorkTilesTestSupport.tileKey('p1', 1, 0),
    ValidWorkTilesTestSupport.tileKey('p1', 2, 0),
  ];
  final game = owGrainBuildSuggestGame(tileKeys: tiles);
  final topology = owSingleProvinceTopology('p1');
  final buildSuggestions = suggestedWorkOrders(game: game, topology: topology)
      .where((o) => o.target == kWorkTargetBuildImprovement)
      .toList();
  if (buildSuggestions.length > 1) {
    for (var i = 0; i < buildSuggestions.length - 1; i++) {
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
  final tile0 = ValidWorkTilesTestSupport.tileKey('p1', 0, 0);
  final tile1 = ValidWorkTilesTestSupport.tileKey('p1', 1, 0);
  final game = owGrainBuildSuggestGame(tileKeys: [tile0, tile1]);
  final topology = owSingleProvinceTopology('p1');
  final currentOrders = Orders(
    workOrdersByPlayerId: {
      ValidWorkTilesTestSupport.playerId: [
        WorkOrder(
          unitId: 'u1',
          target: kWorkTargetBuildImprovement,
          targetTileKey: tile0,
        ),
      ],
    },
  );
  final buildSuggestions = suggestedWorkOrders(
    game: game,
    topology: topology,
    currentOrders: currentOrders,
  ).where(
    (o) =>
        o.target == kWorkTargetBuildImprovement && o.targetTileKey == tile0,
  );
  expect(buildSuggestions, isEmpty);
}

void _suggestworkordersExploreIncludesPartiallyRevealedProvinceWhenFirstSortedEntryTileIsUnknownBut() {
  final fx = NwPartialRevealHomeTarget(
    homeLocalId: 'home',
    targetLocalId: 'tribe1',
    targetOwnerId: 'tribe1',
  );
  final game = fx.game(
    id: 'g1916e1',
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: a Consulate is required to explore Tribe provinces.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
  );
  final explore = suggestedWorkOrders(game: game, topology: fx.topology())
      .where((o) => o.target == kWorkTargetExplore)
      .toList();
  expect(explore, isNotEmpty);
  expect(
    explore.any(
      (o) => Unit.provinceIdFromTileKey(o.targetTileKey) == fx.provTarget,
    ),
    isTrue,
  );
}

void _suggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation() {
  final fx = NwPartialRevealHomeTarget(
    homeLocalId: 'home',
    targetLocalId: 'gp2p',
    targetOwnerId: 'gp2',
  );
  final game = fx.game(
    id: 'g1916e2',
    players: [
      ValidWorkTilesTestSupport.defaultPlayer,
      const Player(id: 'gp2', displayName: 'P2', isHuman: false),
    ],
  );
  expect(
    suggestedWorkOrders(game: game, topology: fx.topology()).where(
      (o) =>
          o.target == kWorkTargetExplore &&
          Unit.provinceIdFromTileKey(o.targetTileKey) == fx.provTarget,
    ),
    isEmpty,
  );
}

void _suggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile() {
  final keys = NwPartialRevealHomeTarget(
    homeLocalId: 'home',
    targetLocalId: 'tribe1',
    targetOwnerId: 'tribe1',
  );
  final fx = NwPartialRevealHomeTarget(
    homeLocalId: 'home',
    targetLocalId: 'tribe1',
    targetOwnerId: 'tribe1',
    resourceByTileKey: {keys.t0: 'grain', keys.t1: 'iron'},
  );
  final game = fx.game(
    id: 'g1916p1',
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: a Consulate is required to prospect Tribe provinces.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
  );
  final prospect = suggestedWorkOrders(
    game: game,
    topology: fx.topology(),
  ).where((o) => o.target == kWorkTargetProspect).toList();
  expect(prospect, isNotEmpty);
  expect(prospect.any((o) => o.targetTileKey == fx.t1), isTrue);
}

void _suggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral() {
  final keys = NwPartialRevealHomeTarget(
    homeLocalId: 'home',
    targetLocalId: 'tribe1',
    targetOwnerId: 'tribe1',
  );
  final fx = NwPartialRevealHomeTarget(
    homeLocalId: 'home',
    targetLocalId: 'tribe1',
    targetOwnerId: 'tribe1',
    resourceByTileKey: {keys.t0: 'grain', keys.t1: 'iron'},
    playerProspectedTiles: {
      ValidWorkTilesTestSupport.playerId: {keys.t1},
    },
  );
  final game = fx.game(
    id: 'g1916p2',
    tribes: const [ValidWorkTilesTestSupport.defaultTribe],
    // Refs #3753 R4: a Consulate is required to prospect Tribe provinces.
    overtureStates: const [ValidWorkTilesTestSupport.tribeConsulateOverture],
  );
  expect(
    suggestedWorkOrders(game: game, topology: fx.topology()).where(
      (o) => o.target == kWorkTargetProspect,
    ),
    isEmpty,
  );
}

void _suggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy() {
  final keys = NwPartialRevealHomeTarget(
    homeLocalId: 'own',
    targetLocalId: 'm1',
    targetOwnerId: 'minor1',
  );
  final fx = NwPartialRevealHomeTarget(
    homeLocalId: 'own',
    targetLocalId: 'm1',
    targetOwnerId: 'minor1',
    resourceByTileKey: {keys.t1: 'grain'},
  );
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeMerchant,
    ownerId: ValidWorkTilesTestSupport.playerId,
    locationProvinceId: fx.provHome,
    tileKey: fx.tileHome,
  );
  final game = fx.game(
    id: 'g1916pl1',
    players: [ValidWorkTilesTestSupport.playerWithTreasury()],
    minorNations: const [
      MinorNation(id: 'minor1', displayName: 'Minor 1'),
    ],
    overtureStates: [ValidWorkTilesTestSupport.embassyOverture()],
    unit: unit,
  );
  expect(
    suggestedWorkOrders(game: game, topology: fx.topology()).where(
      (o) =>
          o.target == kWorkTargetPurchaseLand &&
          Unit.provinceIdFromTileKey(o.targetTileKey) == fx.provTarget,
    ),
    isNotEmpty,
  );
}

void _suggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail() {
  final keys = NwPartialRevealHomeTarget(
    homeLocalId: 'own',
    targetLocalId: 'm1',
    targetOwnerId: 'minor1',
  );
  final fx = NwPartialRevealHomeTarget(
    homeLocalId: 'own',
    targetLocalId: 'm1',
    targetOwnerId: 'minor1',
    resourceByTileKey: {keys.t1: 'grain'},
  );
  final unit = Unit(
    id: 'u1',
    type: kUnitTypeMerchant,
    ownerId: ValidWorkTilesTestSupport.playerId,
    locationProvinceId: fx.provHome,
    tileKey: fx.tileHome,
  );
  final game = fx.game(
    id: 'g1916pl2',
    players: [ValidWorkTilesTestSupport.playerWithTreasury()],
    minorNations: const [
      MinorNation(id: 'minor1', displayName: 'Minor 1'),
    ],
    unit: unit,
  );
  expect(
    suggestedWorkOrders(game: game, topology: fx.topology()).where(
      (o) =>
          o.target == kWorkTargetPurchaseLand &&
          Unit.provinceIdFromTileKey(o.targetTileKey) == fx.provTarget,
    ),
    isEmpty,
  );
}
