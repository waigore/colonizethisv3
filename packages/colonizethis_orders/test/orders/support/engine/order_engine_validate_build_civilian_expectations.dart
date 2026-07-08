// Compact OrderEngine validateBuild(civilian) assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_engine_validate_build_civilian_test_support.dart';

/// Pins for [orderEngineValidateBuildCivilianScenarios] rows.
enum OrderEngineValidateBuildCivilianTarget {
  rejectsUnknownUnitType,
  rejectsBuilderWhenTreasuryTooLow,
  rejectsBuilderWhenPaperInsufficient,
  rejectsMerchantWhenMerchantCompaniesNotUnlocked,
  acceptsBuilderWhenTreasuryAndPaperSufficient,
  acceptsMerchantWhenTechAndResourcesOk,
  acceptsBuildWhenSpawnProvinceIdIsEmptyFallsBackToCapital,
  acceptsBuildWhenSpawnProvinceIdIsForeignFallsBackToCapital,
}

void runOrderEngineValidateBuildCivilianExpectation(
  OrderEngineValidateBuildCivilianTarget target,
) {
  switch (target) {
    case OrderEngineValidateBuildCivilianTarget.rejectsUnknownUnitType:
      _rejectsUnknownUnitType();
    case OrderEngineValidateBuildCivilianTarget
        .rejectsBuilderWhenTreasuryTooLow:
      _rejectsBuilderWhenTreasuryTooLow();
    case OrderEngineValidateBuildCivilianTarget
        .rejectsBuilderWhenPaperInsufficient:
      _rejectsBuilderWhenPaperInsufficient();
    case OrderEngineValidateBuildCivilianTarget
        .rejectsMerchantWhenMerchantCompaniesNotUnlocked:
      _rejectsMerchantWhenMerchantCompaniesNotUnlocked();
    case OrderEngineValidateBuildCivilianTarget
        .acceptsBuilderWhenTreasuryAndPaperSufficient:
      _acceptsBuilderWhenTreasuryAndPaperSufficient();
    case OrderEngineValidateBuildCivilianTarget
        .acceptsMerchantWhenTechAndResourcesOk:
      _acceptsMerchantWhenTechAndResourcesOk();
    case OrderEngineValidateBuildCivilianTarget
        .acceptsBuildWhenSpawnProvinceIdIsEmptyFallsBackToCapital:
      _acceptsBuildWhenSpawnProvinceIdIsEmptyFallsBackToCapital();
    case OrderEngineValidateBuildCivilianTarget
        .acceptsBuildWhenSpawnProvinceIdIsForeignFallsBackToCapital:
      _acceptsBuildWhenSpawnProvinceIdIsForeignFallsBackToCapital();
  }
}

void _rejectsUnknownUnitType() {
  final result = validateSingleBuildUnitOrder(
    buildCivilianValidationGame(treasury: 5000),
    BuildUnitOrder(
      unitType: 'UnknownTypeXyz',
      isMilitary:
          buildUnitCategoryForUnitType('UnknownTypeXyz') ==
          BuildUnitCategory.military,
      spawnProvinceId: '$oldWorldRegionId|P1',
    ),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, 'Insufficient resources');
}

void _rejectsBuilderWhenTreasuryTooLow() {
  final result = validateSingleBuildUnitOrder(
    buildCivilianValidationGame(treasury: 999, paper: 5),
    BuildUnitOrder(
      unitType: kUnitTypeBuilder,
      isMilitary:
          buildUnitCategoryForUnitType(kUnitTypeBuilder) ==
          BuildUnitCategory.military,
      spawnProvinceId: '$oldWorldRegionId|P1',
    ),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, 'Insufficient treasury');
}

void _rejectsBuilderWhenPaperInsufficient() {
  final result = validateSingleBuildUnitOrder(
    buildCivilianValidationGame(treasury: 2000),
    BuildUnitOrder(
      unitType: kUnitTypeBuilder,
      isMilitary:
          buildUnitCategoryForUnitType(kUnitTypeBuilder) ==
          BuildUnitCategory.military,
      spawnProvinceId: '$oldWorldRegionId|P1',
    ),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, 'Insufficient materials');
}

void _rejectsMerchantWhenMerchantCompaniesNotUnlocked() {
  final result = validateSingleBuildUnitOrder(
    buildCivilianValidationGame(treasury: 3000, paper: 5),
    BuildUnitOrder(
      unitType: kUnitTypeMerchant,
      isMilitary:
          buildUnitCategoryForUnitType(kUnitTypeMerchant) ==
          BuildUnitCategory.military,
      spawnProvinceId: '$oldWorldRegionId|P1',
    ),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, 'Required technology not unlocked');
}

void _acceptsBuilderWhenTreasuryAndPaperSufficient() {
  final result = validateSingleBuildUnitOrder(
    buildCivilianValidationGame(treasury: 2000, paper: 5),
    BuildUnitOrder(
      unitType: kUnitTypeBuilder,
      isMilitary:
          buildUnitCategoryForUnitType(kUnitTypeBuilder) ==
          BuildUnitCategory.military,
      spawnProvinceId: '$oldWorldRegionId|P1',
    ),
  );
  expect(result.status, OrderValidationStatus.accepted);
}

void _acceptsMerchantWhenTechAndResourcesOk() {
  final result = validateSingleBuildUnitOrder(
    buildCivilianValidationGame(
      treasury: 3000,
      paper: 5,
      techUnlocked: const {kTechIdMerchantCompanies: true},
    ),
    BuildUnitOrder(
      unitType: kUnitTypeMerchant,
      isMilitary:
          buildUnitCategoryForUnitType(kUnitTypeMerchant) ==
          BuildUnitCategory.military,
      spawnProvinceId: '$oldWorldRegionId|P1',
    ),
  );
  expect(result.status, OrderValidationStatus.accepted);
}

void _acceptsBuildWhenSpawnProvinceIdIsEmptyFallsBackToCapital() {
  final result = validateSingleBuildUnitOrder(
    buildCivilianValidationGame(treasury: 2000, paper: 5),
    BuildUnitOrder(
      unitType: kUnitTypeBuilder,
      isMilitary:
          buildUnitCategoryForUnitType(kUnitTypeBuilder) ==
          BuildUnitCategory.military,
      spawnProvinceId: '',
    ),
  );
  expect(result.status, OrderValidationStatus.accepted);
}

void _acceptsBuildWhenSpawnProvinceIdIsForeignFallsBackToCapital() {
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
    BuildUnitOrder(
      unitType: kUnitTypeBuilder,
      isMilitary:
          buildUnitCategoryForUnitType(kUnitTypeBuilder) ==
          BuildUnitCategory.military,
      spawnProvinceId: '$oldWorldRegionId|P2',
    ),
  );
  expect(result.status, OrderValidationStatus.accepted);
}
