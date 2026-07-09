// Compact OrderEngine validateDiplomatic assertions (Refs #3949 wave 3).

import 'order_engine_validate_diplomatic_expectation_shorthand.dart';

enum OrderEngineValidateDiplomaticTarget {
  declarewarRejectedWhenAlreadyAtWar,
  offerpeaceRejectedWhenNotAtWar,
  establishovertureRejectedWhenTargetIsAtWarWithGP,
  establishovertureTradeConsulateRejectedWithoutDiplomaticExpertise,
  establishovertureConsulateRejectedWhenTreasuryTooLow,
  establishovertureEmbassyRequiresExistingConsulate,
  establishovertureSecondOrderForSameFactionInSameTurnRejected,
  secondDiplomaticOrderToSameTargetDifferentTypeIsRejected,
  grantaidRequiresEmbassyAndSufficientTreasury,
  grantaidRejectsAmountsNotAMultipleOf1000,
  grantaidThenSetSubsidyTowardSameTargetBothAccepted,
  setsubsidyRequiresAnEmbassyRefs3753R2,
  setsubsidyWithAnEmbassyIsAcceptedRegardlessOfTreasuryNoUpfrontCostRefs3753R3,
  setsubsidyWithAnEmbassyAndAValidPercentIsAccepted,
  setsubsidyRejectsAPercentOutside520InStepsOf5,
  secondGrantAidTowardSameTargetRejected,
  declarewarThenGrantAidTowardSameTargetRejected,
}

void runOrderEngineValidateDiplomaticExpectation(
  OrderEngineValidateDiplomaticTarget target,
) {
  switch (target) {
    case OrderEngineValidateDiplomaticTarget.declarewarRejectedWhenAlreadyAtWar:
      vedExpectDeclareWarRejectedWhenAtWar();
    case OrderEngineValidateDiplomaticTarget.offerpeaceRejectedWhenNotAtWar:
      vedExpectOfferPeaceRejectedWhenNotAtWar();
    case OrderEngineValidateDiplomaticTarget
        .establishovertureRejectedWhenTargetIsAtWarWithGP:
      vedExpectOvertureRejectedAtWar();
    case OrderEngineValidateDiplomaticTarget
        .establishovertureTradeConsulateRejectedWithoutDiplomaticExpertise:
      vedExpectConsulateRejectedNoDiplomaticExpertise();
    case OrderEngineValidateDiplomaticTarget
        .establishovertureConsulateRejectedWhenTreasuryTooLow:
      vedExpectConsulateRejectedLowTreasury();
    case OrderEngineValidateDiplomaticTarget
        .establishovertureEmbassyRequiresExistingConsulate:
      vedExpectEmbassyRequiresConsulate();
    case OrderEngineValidateDiplomaticTarget
        .establishovertureSecondOrderForSameFactionInSameTurnRejected:
      vedExpectDuplicateOvertureRejected();
    case OrderEngineValidateDiplomaticTarget
        .secondDiplomaticOrderToSameTargetDifferentTypeIsRejected:
      vedExpectGpAllianceDeclareWarConflictRejected();
    case OrderEngineValidateDiplomaticTarget
        .grantaidRequiresEmbassyAndSufficientTreasury:
      vedExpectGrantAidEmbassyTreasuryRejected();
    case OrderEngineValidateDiplomaticTarget
        .grantaidRejectsAmountsNotAMultipleOf1000:
      vedExpectGrantAidMultipleRejected();
    case OrderEngineValidateDiplomaticTarget
        .grantaidThenSetSubsidyTowardSameTargetBothAccepted:
      vedExpectGrantAidThenSubsidyAccepted();
    case OrderEngineValidateDiplomaticTarget
        .setsubsidyRequiresAnEmbassyRefs3753R2:
      vedExpectSubsidyEmbassyRequired();
    case OrderEngineValidateDiplomaticTarget
        .setsubsidyWithAnEmbassyIsAcceptedRegardlessOfTreasuryNoUpfrontCostRefs3753R3:
      vedExpectSubsidyAcceptedLowTreasury();
    case OrderEngineValidateDiplomaticTarget
        .setsubsidyWithAnEmbassyAndAValidPercentIsAccepted:
      vedExpectSubsidyAcceptedValidPercent();
    case OrderEngineValidateDiplomaticTarget
        .setsubsidyRejectsAPercentOutside520InStepsOf5:
      vedExpectSubsidyRejectedInvalidPercent();
    case OrderEngineValidateDiplomaticTarget
        .secondGrantAidTowardSameTargetRejected:
      vedExpectSecondGrantAidRejected();
    case OrderEngineValidateDiplomaticTarget
        .declarewarThenGrantAidTowardSameTargetRejected:
      vedExpectDeclareWarThenGrantAidRejected();
  }
}
