// Table-driven OrderEngine validateBuild(civilian) scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_validate_build_civilian_expectations.dart';

class OrderEngineValidateBuildCivilianScenario implements RefsScenario {
  const OrderEngineValidateBuildCivilianScenario({
    required this.label,
    required this.target,
    this.refs,
  });

  @override
  final String label;
  final OrderEngineValidateBuildCivilianTarget target;
  @override
  final String? refs;
}

void runOrderEngineValidateBuildCivilianScenario(
  OrderEngineValidateBuildCivilianScenario scenario,
) {
  runOrderEngineValidateBuildCivilianExpectation(scenario.target);
}

List<OrderEngineValidateBuildCivilianScenario>
orderEngineValidateBuildCivilianScenarios() => const [
  // dart format off
  OrderEngineValidateBuildCivilianScenario(
    label: 'rejects unknown unit type',
    target: OrderEngineValidateBuildCivilianTarget.rejectsUnknownUnitType,
  ),
  OrderEngineValidateBuildCivilianScenario(
    label: 'rejects Builder when treasury too low',
    target: OrderEngineValidateBuildCivilianTarget.rejectsBuilderWhenTreasuryTooLow,
  ),
  OrderEngineValidateBuildCivilianScenario(
    label: 'rejects Builder when paper insufficient',
    target: OrderEngineValidateBuildCivilianTarget.rejectsBuilderWhenPaperInsufficient,
  ),
  OrderEngineValidateBuildCivilianScenario(
    label: 'rejects Merchant when merchant_companies not unlocked',
    target: OrderEngineValidateBuildCivilianTarget.rejectsMerchantWhenMerchantCompaniesNotUnlocked,
  ),
  OrderEngineValidateBuildCivilianScenario(
    label: 'accepts Builder when treasury and paper sufficient',
    target: OrderEngineValidateBuildCivilianTarget.acceptsBuilderWhenTreasuryAndPaperSufficient,
  ),
  OrderEngineValidateBuildCivilianScenario(
    label: 'accepts Merchant when tech and resources ok',
    target: OrderEngineValidateBuildCivilianTarget.acceptsMerchantWhenTechAndResourcesOk,
  ),
  OrderEngineValidateBuildCivilianScenario(
    label: 'accepts build when spawnProvinceId is empty (falls back to capital)',
    target: OrderEngineValidateBuildCivilianTarget.acceptsBuildWhenSpawnProvinceIdIsEmptyFallsBackToCapital,
  ),
  OrderEngineValidateBuildCivilianScenario(
    label: 'accepts build when spawnProvinceId is foreign (falls back to capital)',
    target: OrderEngineValidateBuildCivilianTarget.acceptsBuildWhenSpawnProvinceIdIsForeignFallsBackToCapital,
  ),
  // dart format on
];
