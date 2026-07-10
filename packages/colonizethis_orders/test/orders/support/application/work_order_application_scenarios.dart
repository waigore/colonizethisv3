// Table-driven scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'work_order_application_run_rows.dart';

class WorkOrderApplicationScenario implements RefsScenario {
  const WorkOrderApplicationScenario({
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

void runWorkOrderApplicationScenario(WorkOrderApplicationScenario scenario) =>
    scenario.run();

List<WorkOrderApplicationScenario> workOrderApplicationScenarios() => [
  WorkOrderApplicationScenario(
    label: 'prospect adds tile to playerProspectedTiles when terrain eligible',
    run: waaRunProspectAddsTilePlayerProspectedTilesWhenTerrainEligible,
  ),
  WorkOrderApplicationScenario(
    label: 'prospect on non-mineral-eligible terrain does not add tile',
    run: waaRunProspectOnNonMineralEligibleTerrainDoesNotAddTile,
  ),
  WorkOrderApplicationScenario(
    label: 'prospect adds tile when mineral resource present without tile map',
    run: waaRunProspectAddsTileWhenMineralResourcePresentWithoutTileMap,
  ),
  WorkOrderApplicationScenario(
    label:
        'prospect does not add tile when non-mineral resource present without tile map',
    run:
        waaRunProspectDoesNotAddTileWhenNonMineralResourcePresentWithoutTileMap,
  ),
  WorkOrderApplicationScenario(
    label:
        'build_improvement work order sets currentWork then completes when totalTurns=1',
    run:
        waaRunBuildImprovementWorkOrderSetsCurrentWorkThenCompletesWhenTotalTurns1,
  ),
  WorkOrderApplicationScenario(
    label:
        'build_fort assigns currentWork.totalTurns from totalTurnsForWork (fort level)',
    run:
        waaRunBuildFortAssignsCurrentWorkTotalTurnsFromTotalTurnsForWorkFortLevel,
  ),
  WorkOrderApplicationScenario(
    label: 'counter_spy work order sets currentWork for Spy unit',
    run: waaRunCounterSpyWorkOrderSetsCurrentWorkForSpyUnit,
  ),
  WorkOrderApplicationScenario(
    label:
        'purchase_land success: treasury deducted and tile recorded in purchasedTilesByTileKey',
    run:
        waaRunPurchaseLandSuccessTreasuryDeductedTileRecordedPurchasedTilesByTileKey,
  ),
  WorkOrderApplicationScenario(
    label:
        'purchase_land rejected when no Embassy with province owner (Minor/Tribe)',
    run: waaRunPurchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe,
  ),
  WorkOrderApplicationScenario(
    label:
        'purchase_land rejected when at war with province owner (Minor/Tribe)',
    run: waaRunPurchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe,
  ),
  WorkOrderApplicationScenario(
    label:
        'purchase_land same tile by two GPs: first wins, second does not deduct or overwrite',
    run:
        waaRunPurchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite,
  ),
  WorkOrderApplicationScenario(
    label: 'build_fort with sufficient materials deducts materials',
    run: waaRunBuildFortWithSufficientMaterialsDeductsMaterials,
  ),
  WorkOrderApplicationScenario(
    label: 'build_fort to level 2 is skipped without Mine Engineering',
    run: waaRunBuildFortLevel2SkippedWithoutMineEngineering,
  ),
  WorkOrderApplicationScenario(
    label: 'build_fort to level 3 is skipped without Modern Forts',
    run: waaRunBuildFortLevel3SkippedWithoutModernForts,
  ),
  WorkOrderApplicationScenario(
    label: 'upgrade_town completion increases province townDevelopmentLevel',
    run: waaRunUpgradeTownCompletionIncreasesProvinceTownDevelopmentLevel,
  ),
  WorkOrderApplicationScenario(
    label:
        'counter_spy processWork keeps ongoing assignment without killing in build/work',
    run:
        waaRunCounterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork,
  ),
  WorkOrderApplicationScenario(
    label: 'unknown work target is skipped and unit stays idle',
    run: waaRunUnknownWorkTargetSkippedUnitStaysIdle,
  ),
  WorkOrderApplicationScenario(
    label:
        'build_road with insufficient materials does not set currentWork or deduct stockpile',
    run:
        waaRunBuildRoadWithInsufficientMaterialsDoesNotSetCurrentWorkDeductStockpile,
  ),
  WorkOrderApplicationScenario(
    label:
        'build_road with sufficient materials deducts materials and sets currentWork',
    run: waaRunBuildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork,
  ),
  WorkOrderApplicationScenario(
    label:
        'counter_spy work order sets currentWork for Spy unit on owned capital province',
    run:
        waaRunCounterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince,
  ),
  WorkOrderApplicationScenario(
    label: 'explore work order sets currentWork when province has tiles',
    run: waaRunExploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles,
  ),
  WorkOrderApplicationScenario(
    label:
        'explore work order totalTurns uses region-scoped formula ceil(3 * tilesInP / maxTilesInRegion)',
    run:
        waaRunExploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion,
  ),
  WorkOrderApplicationScenario(
    label: 'Engineer build_road work order sets currentWork',
    run: waaRunEngineerBuildRoadWorkOrderSetsCurrentWork,
  ),
  WorkOrderApplicationScenario(
    label: 'build_port work order sets currentWork when materials sufficient',
    run: waaRunBuildPortWorkOrderSetsCurrentWorkWhenMaterialsSufficient,
  ),
];
