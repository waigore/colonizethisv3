// Table-driven valid work tiles / suggest work scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'valid_work_tiles_expectations.dart';

/// One row in [validWorkTilesScenarios].
class ValidWorkTilesScenario implements RefsScenario {
  const ValidWorkTilesScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final ValidWorkTilesTarget target;
  @override
  final String? refs;
}

void runValidWorkTilesScenario(ValidWorkTilesScenario scenario) {
  runValidWorkTilesExpectation(scenario.target);
}

/// Canonical scenarios for valid-work-tiles / suggest-work family tests.
/// Labels match former part-file descriptions (concatenated onto one line for
/// scenario `label:` pins). Baseline single-line entries are preserved verbatim.
List<ValidWorkTilesScenario> validWorkTilesScenarios() => const [
      ValidWorkTilesScenario(
        label: 'returns empty for unknown unit id',
        target: ValidWorkTilesTarget.returnsEmptyForUnknownUnitId,
      ),
      ValidWorkTilesScenario(
        label: 'returns empty when workTarget not allowed for unit type',
        target: ValidWorkTilesTarget.returnsEmptyWhenWorkTargetNotAllowedForUnitType,
      ),
      ValidWorkTilesScenario(
        label: 'returns empty for unknown unit id with visibility',
        target: ValidWorkTilesTarget.returnsEmptyForUnknownUnitIdWithVisibility,
      ),
      ValidWorkTilesScenario(
        label: 'returns empty when workTarget not allowed for unit type with visibility',
        target: ValidWorkTilesTarget.returnsEmptyWhenWorkTargetNotAllowedForUnitTypeWithVisibility,
      ),
      ValidWorkTilesScenario(
        label: 'filters by visibility before order engine validation',
        target: ValidWorkTilesTarget.filtersByVisibilityBeforeOrderEngineValidation,
      ),
      ValidWorkTilesScenario(
        label: 'build_improvement returns only controlled tiles with resources',
        target: ValidWorkTilesTarget.buildImprovementReturnsOnlyControlledTilesWithResources,
      ),
      ValidWorkTilesScenario(
        label: 'build_improvement excludes owned mineral tile until prospected; includes after prospected',
        target: ValidWorkTilesTarget.buildImprovementExcludesOwnedMineralTileUntilProspectedIncludesAfterProspected,
      ),
      ValidWorkTilesScenario(
        label: 'build_improvement includes purchased tiles with resources',
        target: ValidWorkTilesTarget.buildImprovementIncludesPurchasedTilesWithResources,
      ),
      ValidWorkTilesScenario(
        label: 'build_improvement excludes sea zone tiles',
        target: ValidWorkTilesTarget.buildImprovementExcludesSeaZoneTiles,
      ),
      ValidWorkTilesScenario(
        label: 'getValidWorkOrderTileKeysWithVisibility prospect excludes non-mineral and already prospected',
        target: ValidWorkTilesTarget.getvalidworkordertilekeyswithvisibilityProspectExcludesNonMineralAndAlreadyProspected,
      ),
      ValidWorkTilesScenario(
        label: 'getValidWorkOrderTileKeysWithVisibility prospect includes eligible tile',
        target: ValidWorkTilesTarget.getvalidworkordertilekeyswithvisibilityProspectIncludesEligibleTile,
      ),
      ValidWorkTilesScenario(
        label: 'getValidWorkOrderTileKeysWithVisibility prospect excludes wool on hills when tile map marks hills (terrain-only eligibility must not apply)',
        target: ValidWorkTilesTarget.getvalidworkordertilekeyswithvisibilityProspectExcludesWoolOnHillsWhenTileMapMarksHillsTerrainOnlyEligibility,
      ),
      ValidWorkTilesScenario(
        label: 'getValidWorkOrderTileKeysWithVisibility explore only scans partially revealed provinces',
        target: ValidWorkTilesTarget.getvalidworkordertilekeyswithvisibilityExploreOnlyScansPartiallyRevealedProvinces,
      ),
      ValidWorkTilesScenario(
        label: 'getValidWorkOrderTileKeysWithVisibility explore remains under one second on large map fixture',
        target: ValidWorkTilesTarget.getvalidworkordertilekeyswithvisibilityExploreRemainsUnderOneSecondOnLargeMapFixture,
      ),
      ValidWorkTilesScenario(
        label: 'suggestMoveOrders excludes moves to other Great Power provinces',
        target: ValidWorkTilesTarget.suggestmoveordersExcludesMovesToOtherGreatPowerProvinces,
      ),
      ValidWorkTilesScenario(
        label: 'suggestWorkOrders sorts by targetTileKey when unitId and target match',
        target: ValidWorkTilesTarget.suggestworkordersSortsByTargetTileKeyWhenUnitIdAndTargetMatch,
      ),
      ValidWorkTilesScenario(
        label: 'suggestWorkOrders excludes targets from existing work orders for same unit',
        target: ValidWorkTilesTarget.suggestworkordersExcludesTargetsFromExistingWorkOrdersForSameUnit,
      ),
      ValidWorkTilesScenario(
        label: 'suggestWorkOrders explore includes partially revealed province when first sorted entry tile is unknown but later tile is fogged',
        target: ValidWorkTilesTarget.suggestworkordersExploreIncludesPartiallyRevealedProvinceWhenFirstSortedEntryTileIsUnknownBut,
      ),
      ValidWorkTilesScenario(
        label: 'suggestWorkOrders explore excludes partially revealed province when no bundled entry tile passes move validation',
        target: ValidWorkTilesTarget.suggestworkordersExploreExcludesPartiallyRevealedProvinceWhenNoBundledEntryTilePassesMoveValidation,
      ),
      ValidWorkTilesScenario(
        label: 'suggestWorkOrders prospect includes mineral tile in partially revealed province when first sorted entry tile is unknown',
        target: ValidWorkTilesTarget.suggestworkordersProspectIncludesMineralTileInPartiallyRevealedProvinceWhenFirstSortedEntryTile,
      ),
      ValidWorkTilesScenario(
        label: 'suggestWorkOrders prospect excludes partially revealed province when only non-eligible or already prospected mineral tiles remain',
        target: ValidWorkTilesTarget.suggestworkordersProspectExcludesPartiallyRevealedProvinceWhenOnlyNonEligibleOrAlreadyProspectedMineral,
      ),
      ValidWorkTilesScenario(
        label: 'suggestWorkOrders purchase_land includes target in partially revealed minor or tribe province when embassy and diplomacy gates pass',
        target: ValidWorkTilesTarget.suggestworkordersPurchaseLandIncludesTargetInPartiallyRevealedMinorOrTribeProvinceWhenEmbassy,
      ),
      ValidWorkTilesScenario(
        label: 'suggestWorkOrders purchase_land excludes partially revealed target when embassy or diplomacy preconditions fail',
        target: ValidWorkTilesTarget.suggestworkordersPurchaseLandExcludesPartiallyRevealedTargetWhenEmbassyOrDiplomacyPreconditionsFail,
      ),
    ];
