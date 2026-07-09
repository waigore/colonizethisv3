// Table-driven applyBuildAndWorkOrders work-order application scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'work_order_application_expectations.dart';

/// One row in [workOrderApplicationScenarios].
class WorkOrderApplicationScenario implements RefsScenario {
  const WorkOrderApplicationScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final WorkOrderApplicationTarget target;
  @override
  final String? refs;
}

void runWorkOrderApplicationScenario(WorkOrderApplicationScenario scenario) {
  runWorkOrderApplicationExpectation(scenario.target);
}

/// Canonical scenarios for work-order application family tests.
/// Labels match former part-file descriptions (single-line `label:` for CI).
List<WorkOrderApplicationScenario> workOrderApplicationScenarios() => const [
  WorkOrderApplicationScenario(
    label: 'prospect adds tile to playerProspectedTiles when terrain eligible',
    target: WorkOrderApplicationTarget
        .prospectAddsTilePlayerProspectedTilesWhenTerrainEligible,
  ),
  WorkOrderApplicationScenario(
    label: 'prospect on non-mineral-eligible terrain does not add tile',
    target: WorkOrderApplicationTarget
        .prospectOnNonMineralEligibleTerrainDoesNotAddTile,
  ),
  WorkOrderApplicationScenario(
    label: 'prospect adds tile when mineral resource present without tile map',
    target: WorkOrderApplicationTarget
        .prospectAddsTileWhenMineralResourcePresentWithoutTileMap,
  ),
  WorkOrderApplicationScenario(
    label:
        'prospect does not add tile when non-mineral resource present without tile map',
    target: WorkOrderApplicationTarget
        .prospectDoesNotAddTileWhenNonMineralResourcePresentWithoutTileMap,
  ),
  WorkOrderApplicationScenario(
    label:
        'build_improvement work order sets currentWork then completes when totalTurns=1',
    target: WorkOrderApplicationTarget
        .buildImprovementWorkOrderSetsCurrentWorkThenCompletesWhenTotalTurns1,
  ),
  WorkOrderApplicationScenario(
    label:
        'build_fort assigns currentWork.totalTurns from totalTurnsForWork (fort level)',
    target: WorkOrderApplicationTarget
        .buildFortAssignsCurrentWorkTotalTurnsFromTotalTurnsForWorkFortLevel,
  ),
  WorkOrderApplicationScenario(
    label: 'counter_spy work order sets currentWork for Spy unit',
    target:
        WorkOrderApplicationTarget.counterSpyWorkOrderSetsCurrentWorkForSpyUnit,
  ),
  WorkOrderApplicationScenario(
    label:
        'purchase_land success: treasury deducted and tile recorded in purchasedTilesByTileKey',
    target: WorkOrderApplicationTarget
        .purchaseLandSuccessTreasuryDeductedTileRecordedPurchasedTilesByTileKey,
  ),
  WorkOrderApplicationScenario(
    label:
        'purchase_land rejected when no Embassy with province owner (Minor/Tribe)',
    target: WorkOrderApplicationTarget
        .purchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe,
  ),
  WorkOrderApplicationScenario(
    label:
        'purchase_land rejected when at war with province owner (Minor/Tribe)',
    target: WorkOrderApplicationTarget
        .purchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe,
  ),
  WorkOrderApplicationScenario(
    label:
        'purchase_land same tile by two GPs: first wins, second does not deduct or overwrite',
    target: WorkOrderApplicationTarget
        .purchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite,
  ),
  WorkOrderApplicationScenario(
    label: 'build_fort with sufficient materials deducts materials',
    target: WorkOrderApplicationTarget
        .buildFortWithSufficientMaterialsDeductsMaterials,
  ),
  WorkOrderApplicationScenario(
    label: 'build_fort to level 2 is skipped without Mine Engineering',
    target:
        WorkOrderApplicationTarget.buildFortLevel2SkippedWithoutMineEngineering,
  ),
  WorkOrderApplicationScenario(
    label: 'build_fort to level 3 is skipped without Modern Forts',
    target: WorkOrderApplicationTarget.buildFortLevel3SkippedWithoutModernForts,
  ),
  WorkOrderApplicationScenario(
    label: 'upgrade_town completion increases province townDevelopmentLevel',
    target: WorkOrderApplicationTarget
        .upgradeTownCompletionIncreasesProvinceTownDevelopmentLevel,
  ),
  WorkOrderApplicationScenario(
    label:
        'counter_spy processWork keeps ongoing assignment without killing in build/work',
    target: WorkOrderApplicationTarget
        .counterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork,
  ),
  WorkOrderApplicationScenario(
    label: 'unknown work target is skipped and unit stays idle',
    target: WorkOrderApplicationTarget.unknownWorkTargetSkippedUnitStaysIdle,
  ),
  WorkOrderApplicationScenario(
    label:
        'build_road with insufficient materials does not set currentWork or deduct stockpile',
    target: WorkOrderApplicationTarget
        .buildRoadWithInsufficientMaterialsDoesNotSetCurrentWorkDeductStockpile,
  ),
  WorkOrderApplicationScenario(
    label:
        'build_road with sufficient materials deducts materials and sets currentWork',
    target: WorkOrderApplicationTarget
        .buildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork,
  ),
  WorkOrderApplicationScenario(
    label:
        'counter_spy work order sets currentWork for Spy unit on owned capital province',
    target: WorkOrderApplicationTarget
        .counterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince,
  ),
  WorkOrderApplicationScenario(
    label: 'explore work order sets currentWork when province has tiles',
    target: WorkOrderApplicationTarget
        .exploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles,
  ),
  WorkOrderApplicationScenario(
    label:
        'explore work order totalTurns uses region-scoped formula ceil(3 * tilesInP / maxTilesInRegion)',
    target: WorkOrderApplicationTarget
        .exploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion,
  ),
  WorkOrderApplicationScenario(
    label: 'Engineer build_road work order sets currentWork',
    target:
        WorkOrderApplicationTarget.engineerBuildRoadWorkOrderSetsCurrentWork,
  ),
  WorkOrderApplicationScenario(
    label: 'build_port work order sets currentWork when materials sufficient',
    target: WorkOrderApplicationTarget
        .buildPortWorkOrderSetsCurrentWorkWhenMaterialsSufficient,
  ),
];
