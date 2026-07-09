// Compact OrderEngine validateBuild(civilian) assertions (Refs #3949 wave 3).

import 'order_engine_validate_build_civilian_expectation_shorthand.dart';

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
      vbcExpectUnknownUnitTypeRejected();
    case OrderEngineValidateBuildCivilianTarget
        .rejectsBuilderWhenTreasuryTooLow:
      vbcExpectBuilderRejectedLowTreasury();
    case OrderEngineValidateBuildCivilianTarget
        .rejectsBuilderWhenPaperInsufficient:
      vbcExpectBuilderRejectedInsufficientPaper();
    case OrderEngineValidateBuildCivilianTarget
        .rejectsMerchantWhenMerchantCompaniesNotUnlocked:
      vbcExpectMerchantRejectedNoTech();
    case OrderEngineValidateBuildCivilianTarget
        .acceptsBuilderWhenTreasuryAndPaperSufficient:
      vbcExpectBuilderAcceptedDefaultSpawn();
    case OrderEngineValidateBuildCivilianTarget
        .acceptsMerchantWhenTechAndResourcesOk:
      vbcExpectMerchantAcceptedWithTech();
    case OrderEngineValidateBuildCivilianTarget
        .acceptsBuildWhenSpawnProvinceIdIsEmptyFallsBackToCapital:
      vbcExpectBuilderAcceptedEmptySpawnProvince();
    case OrderEngineValidateBuildCivilianTarget
        .acceptsBuildWhenSpawnProvinceIdIsForeignFallsBackToCapital:
      vbcExpectBuilderAcceptedForeignSpawnFallsBackToCapital();
  }
}
