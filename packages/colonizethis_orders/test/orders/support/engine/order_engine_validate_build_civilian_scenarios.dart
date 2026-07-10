// Table-driven OrderEngine validateBuild(civilian) scenarios (Refs #3949 wave 3).

import '../scenario_runner.dart';
import 'order_engine_validate_build_civilian_run_rows.dart';

class OrderEngineValidateBuildCivilianScenario implements RefsScenario {
  const OrderEngineValidateBuildCivilianScenario({
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

void runOrderEngineValidateBuildCivilianScenario(
  OrderEngineValidateBuildCivilianScenario scenario,
) => scenario.run();

List<OrderEngineValidateBuildCivilianScenario>
orderEngineValidateBuildCivilianScenarios() => const [
  // dart format off
          OrderEngineValidateBuildCivilianScenario(
            label: 'rejects unknown unit type',
            run: vbcRunRejectsUnknownUnitType,
          ),
          OrderEngineValidateBuildCivilianScenario(
            label: 'rejects Builder when treasury too low',
            run: vbcRunRejectsBuilderWhenTreasuryTooLow,
          ),
          OrderEngineValidateBuildCivilianScenario(
            label: 'rejects Builder when paper insufficient',
            run: vbcRunRejectsBuilderWhenPaperInsufficient,
          ),
          OrderEngineValidateBuildCivilianScenario(
            label: 'rejects Merchant when merchant_companies not unlocked',
            run: vbcRunRejectsMerchantWhenMerchantCompaniesNotUnlocked,
          ),
          OrderEngineValidateBuildCivilianScenario(
            label: 'accepts Builder when treasury and paper sufficient',
            run: vbcRunAcceptsBuilderWhenTreasuryAndPaperSufficient,
          ),
          OrderEngineValidateBuildCivilianScenario(
            label: 'accepts Merchant when tech and resources ok',
            run: vbcRunAcceptsMerchantWhenTechAndResourcesOk,
          ),
          OrderEngineValidateBuildCivilianScenario(
            label: 'accepts build when spawnProvinceId is empty (falls back to capital)',
            run: vbcRunAcceptsBuildWhenSpawnProvinceIdEmptyFallsBackToCapital,
          ),
          OrderEngineValidateBuildCivilianScenario(
            label: 'accepts build when spawnProvinceId is foreign (falls back to capital)',
            run: vbcRunAcceptsBuildWhenSpawnProvinceIdForeignFallsBackToCapital,
          ),
          // dart format on
];
