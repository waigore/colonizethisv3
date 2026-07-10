// Table-driven valid-work-tiles scenarios (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../scenario_runner.dart';
import 'valid_work_tiles_expectation_shorthand.dart';
import 'valid_work_tiles_fixtures.dart';
import 'valid_work_tiles_test_support.dart';

void vwtRunReturnsEmptyForUnknownUnitId() {
  vwtExpectKeysEmpty(vwtSingleTileGame(), 'no-such-unit', kWorkTargetExplore);
}

void vwtRunReturnsEmptyWhenWorkTargetNotAllowedForUnitType() {
  vwtExpectKeysEmpty(
    vwtSingleTileGame(withExplorer: true),
    'u1',
    kWorkTargetBuildImprovement,
  );
}

void vwtRunReturnsEmptyForUnknownUnitIdWithVisibility() {
  vwtExpectKeysEmpty(
    vwtSingleTileGame(),
    'no-such-unit',
    kWorkTargetExplore,
    withVisibility: true,
  );
}

void vwtRunReturnsEmptyWhenWorkTargetNotAllowedForUnitTypeWithVisibility() {
  vwtExpectKeysEmpty(
    vwtSingleTileGame(withExplorer: true),
    'u1',
    kWorkTargetBuildImprovement,
    withVisibility: true,
  );
}

void vwtRunFiltersByVisibilityBeforeOrderEngineValidation() {
  final p1 = vwtPid('p1');
  final p2 = vwtPid('p2');
  final tileP1 = vwtTk('p1', 0, 0);
  final tileP2 = vwtTk('p2', 0, 0);
  final visGame = ValidWorkTilesTestSupport.validWorkTilesGame(
    oldWorld: RegionData(
      provinces: [vwtOwnedProvince('p1')],
      units: [
        Unit(
          id: 'u1',
          type: 'Colonist',
          ownerId: ValidWorkTilesTestSupport.playerId,
          locationProvinceId: p1,
          tileKey: tileP1,
        ),
      ],
    ),
    tileKeysByRegionAndProvince: ValidWorkTilesTestSupport.tileKeysByProvince({
      p1: [tileP1],
      p2: [tileP2],
    }),
  );
  expect(
    vwtVisKeys(visGame, 'u1', kWorkTargetBuildImprovement).length,
    vwtPlainKeys(visGame, 'u1', kWorkTargetBuildImprovement).length,
  );
}

void vwtRunBuildImprovementReturnsOnlyControlledTilesWithResources() {
  final withRes = vwtTk('p1', 0, 0);
  final noRes = vwtTk('p1', 1, 0);
  final foreign = vwtTk('p2', 0, 0);
  vwtExpectBuildVisMembership(
    owBuilderVisibilityGame(
      provinces: [vwtOwnedProvince('p1'), vwtProvince('p2', 'other')],
      tilesByProvince: {
        vwtPid('p1'): [withRes, noRes],
        vwtPid('p2'): [foreign],
      },
      resourceByTileKey: {withRes: 'grain', foreign: 'iron'},
      builderTileKey: withRes,
      improvementByTile: {withRes: 0},
      extraPlayers: const [
        Player(id: 'other', displayName: 'Other', isHuman: false),
      ],
    ),
    included: [withRes],
    excluded: [noRes, foreign],
  );
}

void vwtRunBuildImprovementExcludesOwnedMineralTileUntilProspectedIncludesAfterProspected() =>
    vwtExpectMineralProspectGate();

void vwtRunBuildImprovementIncludesPurchasedTilesWithResources() {
  final purchased = vwtTk('p2', 0, 0);
  final unpurchased = vwtTk('p2', 1, 0);
  final own = vwtTk('p1', 0, 0);
  vwtExpectBuildVisMembership(
    owBuilderVisibilityGame(
      provinces: [vwtOwnedProvince('p1'), vwtProvince('p2', 'minor1')],
      tilesByProvince: {
        vwtPid('p1'): [own],
        vwtPid('p2'): [purchased, unpurchased],
      },
      resourceByTileKey: {purchased: 'grain', unpurchased: 'grain'},
      builderTileKey: own,
      improvementByTile: {purchased: 0},
      purchasedTilesByTileKey: {purchased: ValidWorkTilesTestSupport.playerId},
      minorNations: const [MinorNation(id: 'minor1', displayName: 'Minor')],
    ),
    included: [purchased],
    excluded: [unpurchased],
  );
}

void vwtRunBuildImprovementExcludesSeaZoneTiles() {
  final land = vwtTk('p1', 0, 0);
  const seaZoneId = 's1';
  final sea = vwtTk(seaZoneId, 0, 0);
  vwtExpectBuildVisMembership(
    owBuilderVisibilityGame(
      provinces: [vwtOwnedProvince('p1')],
      tilesByProvince: {
        vwtPid('p1'): [land],
      },
      resourceByTileKey: {land: 'grain', sea: 'fish'},
      builderTileKey: land,
      improvementByTile: {land: 0},
      seaZoneId: seaZoneId,
      seaTiles: [sea],
    ),
    included: [land],
    excluded: [sea],
  );
}

void vwtRunGetvalidworkordertilekeyswithvisibilityProspectExcludesNonMineralAndAlreadyProspected() {
  final grass = vwtTk('p1', 0, 0);
  final iron = vwtTk('p1', 1, 0);
  vwtExpectProspectVisExcludesAll(
    owTribeProspectGame(
      provinceLocalId: 'p1',
      tileKeys: [grass, iron],
      resourceByTileKey: {grass: 'grain', iron: 'iron'},
      visibilityByTile: {grass: 'fogged', iron: 'fogged'},
      playerProspectedTiles: {
        ValidWorkTilesTestSupport.playerId: {iron},
      },
    ),
    [grass, iron],
  );
}

void vwtRunGetvalidworkordertilekeyswithvisibilityProspectIncludesEligibleTile() {
  final iron = vwtTk('p1', 0, 0);
  expect(
    vwtVisKeys(
      owTribeProspectGame(
        provinceLocalId: 'p1',
        tileKeys: [iron],
        resourceByTileKey: {iron: 'iron'},
        visibilityByTile: {iron: 'fogged'},
      ),
      'u1',
      kWorkTargetProspect,
    ),
    contains(iron),
  );
}

void vwtRunGetvalidworkordertilekeyswithvisibilityProspectExcludesWoolOnHillsWhenTileMapMarksHillsTerrainOnlyEligibility() {
  final wool = vwtTk('p1', 0, 0);
  vwtExpectProspectVisExcludesAll(
    owTribeProspectGame(
      provinceLocalId: 'p1',
      tileKeys: [wool],
      resourceByTileKey: {wool: 'wool'},
      visibilityByTile: {wool: 'fogged'},
    ),
    [wool],
    tileMapByRegion: vwtHillsWoolTileMap('p1'),
  );
}

void vwtRunGetvalidworkordertilekeyswithvisibilityExploreOnlyScansPartiallyRevealedProvinces() {
  final fx = owTribeExploreMultiProvinceFixture();
  vwtExpectExploreVisMembership(
    fx.game,
    included: [fx.partialKnownTile],
    excluded: [fx.fullTile, fx.unknownTile],
  );
}

void vwtRunGetvalidworkordertilekeyswithvisibilityExploreRemainsUnderOneSecondOnLargeMapFixture() =>
    vwtExpectExploreLatencyUnder1s();

void vwtRunSuggestmoveordersExcludesMovesToOtherGreatPowerProvinces() =>
    vwtExpectNoMoveToOtherGpProvince();

void vwtRunSuggestworkordersSortsByTargetTileKeyWhenUnitIdAndTargetMatch() {
  vwtExpectBuildSuggestionsSorted([
    vwtTk('p1', 0, 0),
    vwtTk('p1', 1, 0),
    vwtTk('p1', 2, 0),
  ]);
}

void vwtRunSuggestworkordersExcludesTargetsFromExistingWorkOrdersForSameUnit() {
  vwtExpectBuildExcludesReservedTile(vwtTk('p1', 0, 0), vwtTk('p1', 1, 0));
}

void vwtRunSuggestworkordersExploreIncludesPartiallyRevealedProvinceWhenFirstSortedEntryTileIsUnknownBut() {
  final fx = NwPartialRevealHomeTarget(
    homeLocalId: 'home',
    targetLocalId: 'tribe1',
    targetOwnerId: 'tribe1',
  );
  vwtExpectPartialRevealSuggestions(
    fx: fx,
    game: fx.tribeConsulateGame('g1916e1'),
    workTarget: kWorkTargetExplore,
    expectNonEmpty: true,
    provinceId: fx.provTarget,
  );
}

void vwtRunSuggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation() {
  final fx = NwPartialRevealHomeTarget(
    homeLocalId: 'home',
    targetLocalId: 'gp2p',
    targetOwnerId: 'gp2',
  );
  vwtExpectPartialRevealSuggestions(
    fx: fx,
    game: fx.game(
      id: 'g1916e2',
      players: [
        ValidWorkTilesTestSupport.defaultPlayer,
        const Player(id: 'gp2', displayName: 'P2', isHuman: false),
      ],
    ),
    workTarget: kWorkTargetExplore,
    expectNonEmpty: false,
    provinceId: fx.provTarget,
  );
}

void vwtRunSuggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile() {
  final fx = NwPartialRevealHomeTarget.tribeGrainIron();
  vwtExpectPartialRevealSuggestions(
    fx: fx,
    game: fx.tribeConsulateGame('g1916p1'),
    workTarget: kWorkTargetProspect,
    expectNonEmpty: true,
    tileKey: fx.t1,
  );
}

void vwtRunSuggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral() {
  final fx = NwPartialRevealHomeTarget.tribeGrainIron(prospectedIron: true);
  vwtExpectPartialRevealSuggestions(
    fx: fx,
    game: fx.tribeConsulateGame('g1916p2'),
    workTarget: kWorkTargetProspect,
    expectNonEmpty: false,
  );
}

void vwtRunSuggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy() {
  final fx = NwPartialRevealHomeTarget.minorPurchase();
  vwtExpectPartialRevealSuggestions(
    fx: fx,
    game: fx.minorPurchaseGame(
      'g1916pl1',
      overtureStates: [ValidWorkTilesTestSupport.embassyOverture()],
    ),
    workTarget: kWorkTargetPurchaseLand,
    expectNonEmpty: true,
    provinceId: fx.provTarget,
  );
}

void vwtRunSuggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail() {
  final fx = NwPartialRevealHomeTarget.minorPurchase();
  vwtExpectPartialRevealSuggestions(
    fx: fx,
    game: fx.minorPurchaseGame('g1916pl2'),
    workTarget: kWorkTargetPurchaseLand,
    expectNonEmpty: false,
    provinceId: fx.provTarget,
  );
}

List<RunnableScenario> validWorkTilesScenarios() => [
  // dart format off
  rs('returns empty for unknown unit id', vwtRunReturnsEmptyForUnknownUnitId),

  rs('returns empty when workTarget not allowed for unit type', vwtRunReturnsEmptyWhenWorkTargetNotAllowedForUnitType),

  rs('returns empty for unknown unit id with visibility', vwtRunReturnsEmptyForUnknownUnitIdWithVisibility),

  rs('returns empty when workTarget not allowed for unit type with visibility', vwtRunReturnsEmptyWhenWorkTargetNotAllowedForUnitTypeWithVisibility),

  rs('filters by visibility before order engine validation', vwtRunFiltersByVisibilityBeforeOrderEngineValidation),

  rs('build_improvement returns only controlled tiles with resources', vwtRunBuildImprovementReturnsOnlyControlledTilesWithResources),

  rs('build_improvement excludes owned mineral tile until prospected; includes after prospected', vwtRunBuildImprovementExcludesOwnedMineralTileUntilProspectedIncludesAfterProspected),

  rs('build_improvement includes purchased tiles with resources', vwtRunBuildImprovementIncludesPurchasedTilesWithResources),

  rs('build_improvement excludes sea zone tiles', vwtRunBuildImprovementExcludesSeaZoneTiles),

  rs('getValidWorkOrderTileKeysWithVisibility prospect excludes non-mineral and already prospected', vwtRunGetvalidworkordertilekeyswithvisibilityProspectExcludesNonMineralAndAlreadyProspected),

  rs('getValidWorkOrderTileKeysWithVisibility prospect includes eligible tile', vwtRunGetvalidworkordertilekeyswithvisibilityProspectIncludesEligibleTile),

  rs('getValidWorkOrderTileKeysWithVisibility prospect excludes wool on hills when tile map marks hills (terrain-only eligibility must not apply)', vwtRunGetvalidworkordertilekeyswithvisibilityProspectExcludesWoolOnHillsWhenTileMapMarksHillsTerrainOnlyEligibility),

  rs('getValidWorkOrderTileKeysWithVisibility explore only scans partially revealed provinces', vwtRunGetvalidworkordertilekeyswithvisibilityExploreOnlyScansPartiallyRevealedProvinces),

  rs('getValidWorkOrderTileKeysWithVisibility explore remains under one second on large map fixture', vwtRunGetvalidworkordertilekeyswithvisibilityExploreRemainsUnderOneSecondOnLargeMapFixture),

  rs('suggestMoveOrders excludes moves to other Great Power provinces', vwtRunSuggestmoveordersExcludesMovesToOtherGreatPowerProvinces),

  rs('suggestWorkOrders sorts by targetTileKey when unitId and target match', vwtRunSuggestworkordersSortsByTargetTileKeyWhenUnitIdAndTargetMatch),

  rs('suggestWorkOrders excludes targets from existing work orders for same unit', vwtRunSuggestworkordersExcludesTargetsFromExistingWorkOrdersForSameUnit),

  rs('suggestWorkOrders explore includes partially revealed province when first sorted entry tile is unknown but later tile is fogged', vwtRunSuggestworkordersExploreIncludesPartiallyRevealedProvinceWhenFirstSortedEntryTileIsUnknownBut),

  rs('suggestWorkOrders explore excludes partially revealed province when no bundled entry tile passes move validation', vwtRunSuggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation),

  rs('suggestWorkOrders prospect includes mineral tile in partially revealed province when first sorted entry tile is unknown', vwtRunSuggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile),

  rs('suggestWorkOrders prospect excludes partially revealed province when only non-eligible or already prospected mineral tiles remain', vwtRunSuggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral),

  rs('suggestWorkOrders purchase_land includes target in partially revealed minor or tribe province when embassy and diplomacy gates pass', vwtRunSuggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy),

  rs('suggestWorkOrders purchase_land excludes partially revealed target when embassy or diplomacy preconditions fail', vwtRunSuggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail),

  // dart format on
];
