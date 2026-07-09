// Compact OrderEngine validateBuild(civilian) assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_engine_validate_build_civilian_expectation_shorthand.dart';
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
  vbcExpectRejected(
    buildCivilianValidationGame(treasury: 5000),
    'UnknownTypeXyz',
    reason: 'Insufficient resources',
  );
}

void _rejectsBuilderWhenTreasuryTooLow() {
  vbcExpectRejected(
    buildCivilianValidationGame(treasury: 999, paper: 5),
    kUnitTypeBuilder,
    reason: 'Insufficient treasury',
  );
}

void _rejectsBuilderWhenPaperInsufficient() {
  vbcExpectRejected(
    buildCivilianValidationGame(treasury: 2000),
    kUnitTypeBuilder,
    reason: 'Insufficient materials',
  );
}

void _rejectsMerchantWhenMerchantCompaniesNotUnlocked() {
  vbcExpectRejected(
    buildCivilianValidationGame(treasury: 3000, paper: 5),
    kUnitTypeMerchant,
    reason: 'Required technology not unlocked',
  );
}

void _acceptsBuilderWhenTreasuryAndPaperSufficient() {
  vbcExpectAccepted(
    buildCivilianValidationGame(treasury: 2000, paper: 5),
    kUnitTypeBuilder,
  );
}

void _acceptsMerchantWhenTechAndResourcesOk() {
  vbcExpectAccepted(
    buildCivilianValidationGame(
      treasury: 3000,
      paper: 5,
      techUnlocked: const {kTechIdMerchantCompanies: true},
    ),
    kUnitTypeMerchant,
  );
}

void _acceptsBuildWhenSpawnProvinceIdIsEmptyFallsBackToCapital() {
  vbcExpectAccepted(
    buildCivilianValidationGame(treasury: 2000, paper: 5),
    kUnitTypeBuilder,
    spawnProvinceId: '',
  );
}

void _acceptsBuildWhenSpawnProvinceIdIsForeignFallsBackToCapital() {
  vbcExpectAccepted(
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
    kUnitTypeBuilder,
    spawnProvinceId: '$oldWorldRegionId|P2',
  );
}
