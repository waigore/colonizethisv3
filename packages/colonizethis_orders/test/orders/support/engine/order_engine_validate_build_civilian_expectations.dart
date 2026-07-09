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
  vbcExpectUnknownUnitTypeRejected();
}

void _rejectsBuilderWhenTreasuryTooLow() {
  vbcExpectBuilderRejectedLowTreasury();
}

void _rejectsBuilderWhenPaperInsufficient() {
  vbcExpectBuilderRejectedInsufficientPaper();
}

void _rejectsMerchantWhenMerchantCompaniesNotUnlocked() {
  vbcExpectMerchantRejectedNoTech();
}

void _acceptsBuilderWhenTreasuryAndPaperSufficient() {
  vbcExpectBuilderAcceptedDefaultSpawn();
}

void _acceptsMerchantWhenTechAndResourcesOk() {
  vbcExpectMerchantAcceptedWithTech();
}

void _acceptsBuildWhenSpawnProvinceIdIsEmptyFallsBackToCapital() {
  vbcExpectBuilderAcceptedEmptySpawnProvince();
}

void _acceptsBuildWhenSpawnProvinceIdIsForeignFallsBackToCapital() {
  vbcExpectBuilderAcceptedForeignSpawnFallsBackToCapital();
}
