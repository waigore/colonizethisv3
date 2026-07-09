// Table-driven applyBuildAndWorkOrders build-unit / training scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'build_unit_training_expectations.dart';

/// One row in [buildUnitTrainingScenarios].
class BuildUnitTrainingScenario implements RefsScenario {
  const BuildUnitTrainingScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final BuildUnitTrainingTarget target;
  @override
  final String? refs;
}

void runBuildUnitTrainingScenario(BuildUnitTrainingScenario scenario) {
  runBuildUnitTrainingExpectation(scenario.target);
}

/// Canonical scenarios for military ship-skip + training-cost family tests.
/// Labels match former suite descriptions (single-line `label:` for CI).
List<BuildUnitTrainingScenario> buildUnitTrainingScenarios() => const [
  // dart format off
  BuildUnitTrainingScenario(
    label: 'skips build when unitType unknown in RegimentEconomyCatalog',
    target: BuildUnitTrainingTarget.skipsBuildWhenUnitTypeUnknownInRegimentEconomyCatalog,
  ),
  BuildUnitTrainingScenario(
    label: 'skips military build when zero peasants',
    target: BuildUnitTrainingTarget.skipsMilitaryBuildWhenZeroPeasants,
  ),
  BuildUnitTrainingScenario(
    label: 'skips military build when tech not unlocked',
    target: BuildUnitTrainingTarget.skipsMilitaryBuildWhenTechNotUnlocked,
  ),
  BuildUnitTrainingScenario(
    label: 'skips ship build when tech not unlocked',
    target: BuildUnitTrainingTarget.skipsShipBuildWhenTechNotUnlocked,
  ),
  BuildUnitTrainingScenario(
    label: 'ship build with topology null does not add fleet',
    target: BuildUnitTrainingTarget.shipBuildWithTopologyNullDoesNotAddFleet,
  ),
  BuildUnitTrainingScenario(
    label: 'ship build with capitalProvinceId null does not add fleet',
    target: BuildUnitTrainingTarget.shipBuildWithCapitalProvinceIdNullDoesNotAddFleet,
  ),
  BuildUnitTrainingScenario(
    label: 'ship build with capital not adjacent to sea does not add ship',
    target: BuildUnitTrainingTarget.shipBuildWithCapitalNotAdjacentToSeaDoesNotAddShip,
  ),
  BuildUnitTrainingScenario(
    label: 'rejects build when treasury is insufficient',
    target: BuildUnitTrainingTarget.rejectsBuildWhenTreasuryIsInsufficient,
  ),
  BuildUnitTrainingScenario(
    label: 'rejects build when materials are insufficient',
    target: BuildUnitTrainingTarget.rejectsBuildWhenMaterialsAreInsufficient,
  ),
  BuildUnitTrainingScenario(
    label: 'applies treasury, stockpile and worker costs when valid',
    target: BuildUnitTrainingTarget.appliesTreasuryStockpileAndWorkerCostsWhenValid,
  ),
  BuildUnitTrainingScenario(
    label: 'returns game unchanged when no build or work orders',
    target: BuildUnitTrainingTarget.returnsGameUnchangedWhenNoBuildOrWorkOrders,
  ),
  BuildUnitTrainingScenario(
    label: 'ship build adds ship to fleet when topology and capital with sea',
    target: BuildUnitTrainingTarget.shipBuildAddsShipToFleetWhenTopologyAndCapitalWithSea,
  ),
  BuildUnitTrainingScenario(
    label: 'rejects naval build when peasants are zero',
    target: BuildUnitTrainingTarget.rejectsNavalBuildWhenPeasantsAreZero,
  ),
  BuildUnitTrainingScenario(
    label: 'second naval build adds ship to existing home fleet',
    target: BuildUnitTrainingTarget.secondNavalBuildAddsShipToExistingHomeFleet,
  ),
  BuildUnitTrainingScenario(
    label: 'rejects civilian build when treasury insufficient',
    target: BuildUnitTrainingTarget.rejectsCivilianBuildWhenTreasuryInsufficient,
  ),
  BuildUnitTrainingScenario(
    label: 'rejects civilian build when paper insufficient',
    target: BuildUnitTrainingTarget.rejectsCivilianBuildWhenPaperInsufficient,
  ),
  BuildUnitTrainingScenario(
    label: 'applies treasury and paper cost when civilian build valid',
    target: BuildUnitTrainingTarget.appliesTreasuryAndPaperCostWhenCivilianBuildValid,
  ),
  BuildUnitTrainingScenario(
    label: 'Merchant requires merchant_companies tech',
    target: BuildUnitTrainingTarget.merchantRequiresMerchantCompaniesTech,
  ),
  // dart format on
];
