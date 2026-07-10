// Table-driven scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'valid_work_tiles_run_rows.dart';

List<RunnableScenario> validWorkTilesScenarios() => [
  RunnableScenario(
    label: 'returns empty for unknown unit id',
    run: vwtRunReturnsEmptyForUnknownUnitId,
  ),
  RunnableScenario(
    label: 'returns empty when workTarget not allowed for unit type',
    run: vwtRunReturnsEmptyWhenWorkTargetNotAllowedForUnitType,
  ),
  RunnableScenario(
    label: 'returns empty for unknown unit id with visibility',
    run: vwtRunReturnsEmptyForUnknownUnitIdWithVisibility,
  ),
  RunnableScenario(
    label:
        'returns empty when workTarget not allowed for unit type with visibility',
    run: vwtRunReturnsEmptyWhenWorkTargetNotAllowedForUnitTypeWithVisibility,
  ),
  RunnableScenario(
    label: 'filters by visibility before order engine validation',
    run: vwtRunFiltersByVisibilityBeforeOrderEngineValidation,
  ),
  RunnableScenario(
    label: 'build_improvement returns only controlled tiles with resources',
    run: vwtRunBuildImprovementReturnsOnlyControlledTilesWithResources,
  ),
  RunnableScenario(
    label:
        'build_improvement excludes owned mineral tile until prospected; includes after prospected',
    run:
        vwtRunBuildImprovementExcludesOwnedMineralTileUntilProspectedIncludesAfterProspected,
  ),
  RunnableScenario(
    label: 'build_improvement includes purchased tiles with resources',
    run: vwtRunBuildImprovementIncludesPurchasedTilesWithResources,
  ),
  RunnableScenario(
    label: 'build_improvement excludes sea zone tiles',
    run: vwtRunBuildImprovementExcludesSeaZoneTiles,
  ),
  RunnableScenario(
    label:
        'getValidWorkOrderTileKeysWithVisibility prospect excludes non-mineral and already prospected',
    run:
        vwtRunGetvalidworkordertilekeyswithvisibilityProspectExcludesNonMineralAndAlreadyProspected,
  ),
  RunnableScenario(
    label:
        'getValidWorkOrderTileKeysWithVisibility prospect includes eligible tile',
    run:
        vwtRunGetvalidworkordertilekeyswithvisibilityProspectIncludesEligibleTile,
  ),
  RunnableScenario(
    label:
        'getValidWorkOrderTileKeysWithVisibility prospect excludes wool on hills when tile map marks hills (terrain-only eligibility must not apply)',
    run:
        vwtRunGetvalidworkordertilekeyswithvisibilityProspectExcludesWoolOnHillsWhenTileMapMarksHillsTerrainOnlyEligibility,
  ),
  RunnableScenario(
    label:
        'getValidWorkOrderTileKeysWithVisibility explore only scans partially revealed provinces',
    run:
        vwtRunGetvalidworkordertilekeyswithvisibilityExploreOnlyScansPartiallyRevealedProvinces,
  ),
  RunnableScenario(
    label:
        'getValidWorkOrderTileKeysWithVisibility explore remains under one second on large map fixture',
    run:
        vwtRunGetvalidworkordertilekeyswithvisibilityExploreRemainsUnderOneSecondOnLargeMapFixture,
  ),
  RunnableScenario(
    label: 'suggestMoveOrders excludes moves to other Great Power provinces',
    run: vwtRunSuggestmoveordersExcludesMovesToOtherGreatPowerProvinces,
  ),
  RunnableScenario(
    label:
        'suggestWorkOrders sorts by targetTileKey when unitId and target match',
    run: vwtRunSuggestworkordersSortsByTargetTileKeyWhenUnitIdAndTargetMatch,
  ),
  RunnableScenario(
    label:
        'suggestWorkOrders excludes targets from existing work orders for same unit',
    run:
        vwtRunSuggestworkordersExcludesTargetsFromExistingWorkOrdersForSameUnit,
  ),
  RunnableScenario(
    label:
        'suggestWorkOrders explore includes partially revealed province when first sorted entry tile is unknown but later tile is fogged',
    run:
        vwtRunSuggestworkordersExploreIncludesPartiallyRevealedProvinceWhenFirstSortedEntryTileIsUnknownBut,
  ),
  RunnableScenario(
    label:
        'suggestWorkOrders explore excludes partially revealed province when no bundled entry tile passes move validation',
    run:
        vwtRunSuggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation,
  ),
  RunnableScenario(
    label:
        'suggestWorkOrders prospect includes mineral tile in partially revealed province when first sorted entry tile is unknown',
    run:
        vwtRunSuggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile,
  ),
  RunnableScenario(
    label:
        'suggestWorkOrders prospect excludes partially revealed province when only non-eligible or already prospected mineral tiles remain',
    run:
        vwtRunSuggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral,
  ),
  RunnableScenario(
    label:
        'suggestWorkOrders purchase_land includes target in partially revealed minor or tribe province when embassy and diplomacy gates pass',
    run:
        vwtRunSuggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy,
  ),
  RunnableScenario(
    label:
        'suggestWorkOrders purchase_land excludes partially revealed target when embassy or diplomacy preconditions fail',
    run:
        vwtRunSuggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail,
  ),
];
