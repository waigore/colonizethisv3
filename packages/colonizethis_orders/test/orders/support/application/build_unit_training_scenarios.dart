// Table-driven applyBuildAndWorkOrders build-unit / training scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'build_unit_training_run_rows.dart';

/// Canonical scenarios for military ship-skip + training-cost family tests.
/// Labels match former suite descriptions (single-line `label:` for CI).
List<RunnableScenario> buildUnitTrainingScenarios() => const [
  // dart format off
  RunnableScenario(
    label: 'skips build when unitType unknown in RegimentEconomyCatalog',
    run: butRunSkipsBuildWhenUnitTypeUnknownInRegimentEconomyCatalog,
  ),
  RunnableScenario(
    label: 'skips military build when zero peasants',
    run: butRunSkipsMilitaryBuildWhenZeroPeasants,
  ),
  RunnableScenario(
    label: 'skips military build when tech not unlocked',
    run: butRunSkipsMilitaryBuildWhenTechNotUnlocked,
  ),
  RunnableScenario(
    label: 'skips ship build when tech not unlocked',
    run: butRunSkipsShipBuildWhenTechNotUnlocked,
  ),
  RunnableScenario(
    label: 'ship build with topology null does not add fleet',
    run: butRunShipBuildWithTopologyNullDoesNotAddFleet,
  ),
  RunnableScenario(
    label: 'ship build with capitalProvinceId null does not add fleet',
    run: butRunShipBuildWithCapitalProvinceIdNullDoesNotAddFleet,
  ),
  RunnableScenario(
    label: 'ship build with capital not adjacent to sea does not add ship',
    run: butRunShipBuildWithCapitalNotAdjacentToSeaDoesNotAddShip,
  ),
  RunnableScenario(
    label: 'rejects build when treasury is insufficient',
    run: butRunRejectsBuildWhenTreasuryIsInsufficient,
  ),
  RunnableScenario(
    label: 'rejects build when materials are insufficient',
    run: butRunRejectsBuildWhenMaterialsAreInsufficient,
  ),
  RunnableScenario(
    label: 'applies treasury, stockpile and worker costs when valid',
    run: butRunAppliesTreasuryStockpileAndWorkerCostsWhenValid,
  ),
  RunnableScenario(
    label: 'returns game unchanged when no build or work orders',
    run: butRunReturnsGameUnchangedWhenNoBuildOrWorkOrders,
  ),
  RunnableScenario(
    label: 'ship build adds ship to fleet when topology and capital with sea',
    run: butRunShipBuildAddsShipToFleetWhenTopologyAndCapitalWithSea,
  ),
  RunnableScenario(
    label: 'rejects naval build when peasants are zero',
    run: butRunRejectsNavalBuildWhenPeasantsAreZero,
  ),
  RunnableScenario(
    label: 'second naval build adds ship to existing home fleet',
    run: butRunSecondNavalBuildAddsShipToExistingHomeFleet,
  ),
  RunnableScenario(
    label: 'rejects civilian build when treasury insufficient',
    run: butRunRejectsCivilianBuildWhenTreasuryInsufficient,
  ),
  RunnableScenario(
    label: 'rejects civilian build when paper insufficient',
    run: butRunRejectsCivilianBuildWhenPaperInsufficient,
  ),
  RunnableScenario(
    label: 'applies treasury and paper cost when civilian build valid',
    run: butRunAppliesTreasuryAndPaperCostWhenCivilianBuildValid,
  ),
  RunnableScenario(
    label: 'Merchant requires merchant_companies tech',
    run: butRunMerchantRequiresMerchantCompaniesTech,
  ),
  // dart format on
];
