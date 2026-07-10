// Table-driven scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'valid_work_tiles_run_rows.dart';

class ValidWorkTilesScenario implements RefsScenario {
  const ValidWorkTilesScenario({
    required this.label,
    required this.run,
    this.refs,
  });
  @override
  final String label;
  final void Function() run;
  @override
  final String? refs;
}

void runValidWorkTilesScenario(ValidWorkTilesScenario scenario) =>
    scenario.run();

List<ValidWorkTilesScenario> validWorkTilesScenarios() => [
  ValidWorkTilesScenario(
    label: 'returns empty for unknown unit id',
    run: vwtRunReturnsEmptyForUnknownUnitId,
  ),
  ValidWorkTilesScenario(
    label: 'returns empty when workTarget not allowed for unit type',
    run: vwtRunReturnsEmptyWhenWorkTargetNotAllowedForUnitType,
  ),
  ValidWorkTilesScenario(
    label: 'returns empty for unknown unit id with visibility',
    run: vwtRunReturnsEmptyForUnknownUnitIdWithVisibility,
  ),
  ValidWorkTilesScenario(
    label:
        'returns empty when workTarget not allowed for unit type with visibility',
    run: vwtRunReturnsEmptyWhenWorkTargetNotAllowedForUnitTypeWithVisibility,
  ),
  ValidWorkTilesScenario(
    label: 'filters by visibility before order engine validation',
    run: vwtRunFiltersByVisibilityBeforeOrderEngineValidation,
  ),
  ValidWorkTilesScenario(
    label: 'build_improvement returns only controlled tiles with resources',
    run: vwtRunBuildImprovementReturnsOnlyControlledTilesWithResources,
  ),
  ValidWorkTilesScenario(
    label:
        'build_improvement excludes owned mineral tile until prospected; includes after prospected',
    run:
        vwtRunBuildImprovementExcludesOwnedMineralTileUntilProspectedIncludesAfterProspected,
  ),
  ValidWorkTilesScenario(
    label: 'build_improvement includes purchased tiles with resources',
    run: vwtRunBuildImprovementIncludesPurchasedTilesWithResources,
  ),
  ValidWorkTilesScenario(
    label: 'build_improvement excludes sea zone tiles',
    run: vwtRunBuildImprovementExcludesSeaZoneTiles,
  ),
  ValidWorkTilesScenario(
    label:
        'getValidWorkOrderTileKeysWithVisibility prospect excludes non-mineral and already prospected',
    run:
        vwtRunGetvalidworkordertilekeyswithvisibilityProspectExcludesNonMineralAndAlreadyProspected,
  ),
  ValidWorkTilesScenario(
    label:
        'getValidWorkOrderTileKeysWithVisibility prospect includes eligible tile',
    run:
        vwtRunGetvalidworkordertilekeyswithvisibilityProspectIncludesEligibleTile,
  ),
  ValidWorkTilesScenario(
    label:
        'getValidWorkOrderTileKeysWithVisibility prospect excludes wool on hills when tile map marks hills (terrain-only eligibility must not apply)',
    run:
        vwtRunGetvalidworkordertilekeyswithvisibilityProspectExcludesWoolOnHillsWhenTileMapMarksHillsTerrainOnlyEligibility,
  ),
  ValidWorkTilesScenario(
    label:
        'getValidWorkOrderTileKeysWithVisibility explore only scans partially revealed provinces',
    run:
        vwtRunGetvalidworkordertilekeyswithvisibilityExploreOnlyScansPartiallyRevealedProvinces,
  ),
  ValidWorkTilesScenario(
    label:
        'getValidWorkOrderTileKeysWithVisibility explore remains under one second on large map fixture',
    run:
        vwtRunGetvalidworkordertilekeyswithvisibilityExploreRemainsUnderOneSecondOnLargeMapFixture,
  ),
  ValidWorkTilesScenario(
    label: 'suggestMoveOrders excludes moves to other Great Power provinces',
    run: vwtRunSuggestmoveordersExcludesMovesToOtherGreatPowerProvinces,
  ),
  ValidWorkTilesScenario(
    label:
        'suggestWorkOrders sorts by targetTileKey when unitId and target match',
    run: vwtRunSuggestworkordersSortsByTargetTileKeyWhenUnitIdAndTargetMatch,
  ),
  ValidWorkTilesScenario(
    label:
        'suggestWorkOrders excludes targets from existing work orders for same unit',
    run:
        vwtRunSuggestworkordersExcludesTargetsFromExistingWorkOrdersForSameUnit,
  ),
  ValidWorkTilesScenario(
    label:
        'suggestWorkOrders explore includes partially revealed province when first sorted entry tile is unknown but later tile is fogged',
    run:
        vwtRunSuggestworkordersExploreIncludesPartiallyRevealedProvinceWhenFirstSortedEntryTileIsUnknownBut,
  ),
  ValidWorkTilesScenario(
    label:
        'suggestWorkOrders explore excludes partially revealed province when no bundled entry tile passes move validation',
    run:
        vwtRunSuggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation,
  ),
  ValidWorkTilesScenario(
    label:
        'suggestWorkOrders prospect includes mineral tile in partially revealed province when first sorted entry tile is unknown',
    run:
        vwtRunSuggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile,
  ),
  ValidWorkTilesScenario(
    label:
        'suggestWorkOrders prospect excludes partially revealed province when only non-eligible or already prospected mineral tiles remain',
    run:
        vwtRunSuggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral,
  ),
  ValidWorkTilesScenario(
    label:
        'suggestWorkOrders purchase_land includes target in partially revealed minor or tribe province when embassy and diplomacy gates pass',
    run:
        vwtRunSuggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy,
  ),
  ValidWorkTilesScenario(
    label:
        'suggestWorkOrders purchase_land excludes partially revealed target when embassy or diplomacy preconditions fail',
    run:
        vwtRunSuggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail,
  ),
];
