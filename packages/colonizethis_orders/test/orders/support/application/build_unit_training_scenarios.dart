// Table-driven applyBuildAndWorkOrders build-unit / training scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'build_unit_training_run_rows.dart';

/// One row in [buildUnitTrainingScenarios].
class BuildUnitTrainingScenario implements RefsScenario {
  const BuildUnitTrainingScenario({
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

void runBuildUnitTrainingScenario(BuildUnitTrainingScenario scenario) {
  scenario.run();
}

/// Canonical scenarios for military ship-skip + training-cost family tests.
/// Labels match former suite descriptions (single-line `label:` for CI).
List<BuildUnitTrainingScenario> buildUnitTrainingScenarios() => const [
  // dart format off
  BuildUnitTrainingScenario(
    label: 'skips build when unitType unknown in RegimentEconomyCatalog',
    run: butRunSkipsBuildWhenUnitTypeUnknownInRegimentEconomyCatalog,
  ),
  BuildUnitTrainingScenario(
    label: 'skips military build when zero peasants',
    run: butRunSkipsMilitaryBuildWhenZeroPeasants,
  ),
  BuildUnitTrainingScenario(
    label: 'skips military build when tech not unlocked',
    run: butRunSkipsMilitaryBuildWhenTechNotUnlocked,
  ),
  BuildUnitTrainingScenario(
    label: 'skips ship build when tech not unlocked',
    run: butRunSkipsShipBuildWhenTechNotUnlocked,
  ),
  BuildUnitTrainingScenario(
    label: 'ship build with topology null does not add fleet',
    run: butRunShipBuildWithTopologyNullDoesNotAddFleet,
  ),
  BuildUnitTrainingScenario(
    label: 'ship build with capitalProvinceId null does not add fleet',
    run: butRunShipBuildWithCapitalProvinceIdNullDoesNotAddFleet,
  ),
  BuildUnitTrainingScenario(
    label: 'ship build with capital not adjacent to sea does not add ship',
    run: butRunShipBuildWithCapitalNotAdjacentToSeaDoesNotAddShip,
  ),
  BuildUnitTrainingScenario(
    label: 'rejects build when treasury is insufficient',
    run: butRunRejectsBuildWhenTreasuryIsInsufficient,
  ),
  BuildUnitTrainingScenario(
    label: 'rejects build when materials are insufficient',
    run: butRunRejectsBuildWhenMaterialsAreInsufficient,
  ),
  BuildUnitTrainingScenario(
    label: 'applies treasury, stockpile and worker costs when valid',
    run: butRunAppliesTreasuryStockpileAndWorkerCostsWhenValid,
  ),
  BuildUnitTrainingScenario(
    label: 'returns game unchanged when no build or work orders',
    run: butRunReturnsGameUnchangedWhenNoBuildOrWorkOrders,
  ),
  BuildUnitTrainingScenario(
    label: 'ship build adds ship to fleet when topology and capital with sea',
    run: butRunShipBuildAddsShipToFleetWhenTopologyAndCapitalWithSea,
  ),
  BuildUnitTrainingScenario(
    label: 'rejects naval build when peasants are zero',
    run: butRunRejectsNavalBuildWhenPeasantsAreZero,
  ),
  BuildUnitTrainingScenario(
    label: 'second naval build adds ship to existing home fleet',
    run: butRunSecondNavalBuildAddsShipToExistingHomeFleet,
  ),
  BuildUnitTrainingScenario(
    label: 'rejects civilian build when treasury insufficient',
    run: butRunRejectsCivilianBuildWhenTreasuryInsufficient,
  ),
  BuildUnitTrainingScenario(
    label: 'rejects civilian build when paper insufficient',
    run: butRunRejectsCivilianBuildWhenPaperInsufficient,
  ),
  BuildUnitTrainingScenario(
    label: 'applies treasury and paper cost when civilian build valid',
    run: butRunAppliesTreasuryAndPaperCostWhenCivilianBuildValid,
  ),
  BuildUnitTrainingScenario(
    label: 'Merchant requires merchant_companies tech',
    run: butRunMerchantRequiresMerchantCompaniesTech,
  ),
  // dart format on
];
