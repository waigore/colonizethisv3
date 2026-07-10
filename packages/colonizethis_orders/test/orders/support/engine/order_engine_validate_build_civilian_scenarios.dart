// Table-driven OrderEngine validateBuild(civilian) scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'order_engine_validate_build_civilian_expectation_shorthand.dart';
import 'order_engine_validate_build_civilian_test_support.dart';

void vbcRunRejectsUnknownUnitType() {
  final result = validateSingleBuildUnitOrder(
    buildCivilianValidationGame(treasury: 5000),
    vbcOrder('UnknownTypeXyz'),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, 'Insufficient resources');
}

void vbcRunRejectsBuilderWhenTreasuryTooLow() {
  final result = validateSingleBuildUnitOrder(
    buildCivilianValidationGame(treasury: 999, paper: 5),
    vbcOrder(kUnitTypeBuilder),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, 'Insufficient treasury');
}

void vbcRunRejectsBuilderWhenPaperInsufficient() {
  final result = validateSingleBuildUnitOrder(
    buildCivilianValidationGame(treasury: 2000),
    vbcOrder(kUnitTypeBuilder),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, 'Insufficient materials');
}

void vbcRunRejectsMerchantWhenMerchantCompaniesNotUnlocked() {
  final result = validateSingleBuildUnitOrder(
    buildCivilianValidationGame(treasury: 3000, paper: 5),
    vbcOrder(kUnitTypeMerchant),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, 'Required technology not unlocked');
}

void vbcRunAcceptsBuilderWhenTreasuryAndPaperSufficient() {
  final result = validateSingleBuildUnitOrder(
    buildCivilianValidationGame(treasury: 2000, paper: 5),
    vbcOrder(kUnitTypeBuilder),
  );
  expect(result.status, OrderValidationStatus.accepted);
}

void vbcRunAcceptsMerchantWhenTechAndResourcesOk() {
  final result = validateSingleBuildUnitOrder(
    buildCivilianValidationGame(
      treasury: 3000,
      paper: 5,
      techUnlocked: const {kTechIdMerchantCompanies: true},
    ),
    vbcOrder(kUnitTypeMerchant),
  );
  expect(result.status, OrderValidationStatus.accepted);
}

void vbcRunAcceptsBuildWhenSpawnProvinceIdEmptyFallsBackToCapital() {
  final result = validateSingleBuildUnitOrder(
    buildCivilianValidationGame(treasury: 2000, paper: 5),
    vbcOrder(kUnitTypeBuilder, spawnProvinceId: ''),
  );
  expect(result.status, OrderValidationStatus.accepted);
}

void vbcRunAcceptsBuildWhenSpawnProvinceIdForeignFallsBackToCapital() {
  final result = validateSingleBuildUnitOrder(
    buildCivilianValidationGame(
      treasury: 2000,
      paper: 5,
      provinces: const [
        Province(
          id: '$oldWorldRegionId|P1',
          regionId: oldWorldRegionId,
          ownerId: 'p1',
        ),
        Province(
          id: '$oldWorldRegionId|P2',
          regionId: oldWorldRegionId,
          ownerId: 'p2',
        ),
      ],
    ),
    vbcOrder(kUnitTypeBuilder, spawnProvinceId: '$oldWorldRegionId|P2'),
  );
  expect(result.status, OrderValidationStatus.accepted);
}

List<RunnableScenario> orderEngineValidateBuildCivilianScenarios() => const [
  // dart format off
          rs('rejects unknown unit type', vbcRunRejectsUnknownUnitType),
          rs('rejects Builder when treasury too low', vbcRunRejectsBuilderWhenTreasuryTooLow),
          rs('rejects Builder when paper insufficient', vbcRunRejectsBuilderWhenPaperInsufficient),
          rs('rejects Merchant when merchant_companies not unlocked', vbcRunRejectsMerchantWhenMerchantCompaniesNotUnlocked),
          rs('accepts Builder when treasury and paper sufficient', vbcRunAcceptsBuilderWhenTreasuryAndPaperSufficient),
          rs('accepts Merchant when tech and resources ok', vbcRunAcceptsMerchantWhenTechAndResourcesOk),
          rs('accepts build when spawnProvinceId is empty (falls back to capital)', vbcRunAcceptsBuildWhenSpawnProvinceIdEmptyFallsBackToCapital),
          rs('accepts build when spawnProvinceId is foreign (falls back to capital)', vbcRunAcceptsBuildWhenSpawnProvinceIdForeignFallsBackToCapital),
          // dart format on
];
