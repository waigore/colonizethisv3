// Table-driven scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'work_order_application_run_rows.dart';

List<RunnableScenario> workOrderApplicationScenarios() => [
  RunnableScenario(
    label: 'prospect adds tile to playerProspectedTiles when terrain eligible',
    run: waaRunProspectAddsTilePlayerProspectedTilesWhenTerrainEligible,
  ),
  RunnableScenario(
    label: 'prospect on non-mineral-eligible terrain does not add tile',
    run: waaRunProspectOnNonMineralEligibleTerrainDoesNotAddTile,
  ),
  RunnableScenario(
    label: 'prospect adds tile when mineral resource present without tile map',
    run: waaRunProspectAddsTileWhenMineralResourcePresentWithoutTileMap,
  ),
  RunnableScenario(
    label:
        'prospect does not add tile when non-mineral resource present without tile map',
    run:
        waaRunProspectDoesNotAddTileWhenNonMineralResourcePresentWithoutTileMap,
  ),
  RunnableScenario(
    label:
        'build_improvement work order sets currentWork then completes when totalTurns=1',
    run:
        waaRunBuildImprovementWorkOrderSetsCurrentWorkThenCompletesWhenTotalTurns1,
  ),
  RunnableScenario(
    label:
        'build_fort assigns currentWork.totalTurns from totalTurnsForWork (fort level)',
    run:
        waaRunBuildFortAssignsCurrentWorkTotalTurnsFromTotalTurnsForWorkFortLevel,
  ),
  RunnableScenario(
    label: 'counter_spy work order sets currentWork for Spy unit',
    run: waaRunCounterSpyWorkOrderSetsCurrentWorkForSpyUnit,
  ),
  RunnableScenario(
    label:
        'purchase_land success: treasury deducted and tile recorded in purchasedTilesByTileKey',
    run:
        waaRunPurchaseLandSuccessTreasuryDeductedTileRecordedPurchasedTilesByTileKey,
  ),
  RunnableScenario(
    label:
        'purchase_land rejected when no Embassy with province owner (Minor/Tribe)',
    run: waaRunPurchaseLandRejectedWhenNoEmbassyWithProvinceOwnerMinorTribe,
  ),
  RunnableScenario(
    label:
        'purchase_land rejected when at war with province owner (Minor/Tribe)',
    run: waaRunPurchaseLandRejectedWhenAtWarWithProvinceOwnerMinorTribe,
  ),
  RunnableScenario(
    label:
        'purchase_land same tile by two GPs: first wins, second does not deduct or overwrite',
    run:
        waaRunPurchaseLandSameTileByTwoGPsFirstWinsSecondDoesNotDeductOverwrite,
  ),
  RunnableScenario(
    label: 'build_fort with sufficient materials deducts materials',
    run: waaRunBuildFortWithSufficientMaterialsDeductsMaterials,
  ),
  RunnableScenario(
    label: 'build_fort to level 2 is skipped without Mine Engineering',
    run: waaRunBuildFortLevel2SkippedWithoutMineEngineering,
  ),
  RunnableScenario(
    label: 'build_fort to level 3 is skipped without Modern Forts',
    run: waaRunBuildFortLevel3SkippedWithoutModernForts,
  ),
  RunnableScenario(
    label: 'upgrade_town completion increases province townDevelopmentLevel',
    run: waaRunUpgradeTownCompletionIncreasesProvinceTownDevelopmentLevel,
  ),
  RunnableScenario(
    label:
        'counter_spy processWork keeps ongoing assignment without killing in build/work',
    run:
        waaRunCounterSpyProcessWorkKeepsOngoingAssignmentWithoutKillingBuildWork,
  ),
  RunnableScenario(
    label: 'unknown work target is skipped and unit stays idle',
    run: waaRunUnknownWorkTargetSkippedUnitStaysIdle,
  ),
  RunnableScenario(
    label:
        'build_road with insufficient materials does not set currentWork or deduct stockpile',
    run:
        waaRunBuildRoadWithInsufficientMaterialsDoesNotSetCurrentWorkDeductStockpile,
  ),
  RunnableScenario(
    label:
        'build_road with sufficient materials deducts materials and sets currentWork',
    run: waaRunBuildRoadWithSufficientMaterialsDeductsMaterialsSetsCurrentWork,
  ),
  RunnableScenario(
    label:
        'counter_spy work order sets currentWork for Spy unit on owned capital province',
    run:
        waaRunCounterSpyWorkOrderSetsCurrentWorkForSpyUnitOnOwnedCapitalProvince,
  ),
  RunnableScenario(
    label: 'explore work order sets currentWork when province has tiles',
    run: waaRunExploreWorkOrderSetsCurrentWorkWhenProvinceHasTiles,
  ),
  RunnableScenario(
    label:
        'explore work order totalTurns uses region-scoped formula ceil(3 * tilesInP / maxTilesInRegion)',
    run:
        waaRunExploreWorkOrderTotalTurnsUsesRegionScopedFormulaCeil3TilesInPMaxTilesInRegion,
  ),
  RunnableScenario(
    label: 'Engineer build_road work order sets currentWork',
    run: waaRunEngineerBuildRoadWorkOrderSetsCurrentWork,
  ),
  RunnableScenario(
    label: 'build_port work order sets currentWork when materials sufficient',
    run: waaRunBuildPortWorkOrderSetsCurrentWorkWhenMaterialsSufficient,
  ),
];
