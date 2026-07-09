part of 'order_engine_validate_diplomatic_expectations.dart';

void _declarewarRejectedWhenAlreadyAtWar() {
  vedExpectDeclareWarRejectedWhenAtWar();
}

void _offerpeaceRejectedWhenNotAtWar() {
  vedExpectOfferPeaceRejectedWhenNotAtWar();
}

void _establishovertureRejectedWhenTargetIsAtWarWithGP() {
  vedExpectOvertureRejectedAtWar();
}

void _establishovertureTradeConsulateRejectedWithoutDiplomaticExpertise() {
  vedExpectConsulateRejectedNoDiplomaticExpertise();
}

void _establishovertureConsulateRejectedWhenTreasuryTooLow() {
  vedExpectConsulateRejectedLowTreasury();
}

void _establishovertureEmbassyRequiresExistingConsulate() {
  vedExpectEmbassyRequiresConsulate();
}

void _establishovertureSecondOrderForSameFactionInSameTurnRejected() {
  vedExpectDuplicateOvertureRejected();
}

void _secondDiplomaticOrderToSameTargetDifferentTypeIsRejected() {
  vedExpectGpAllianceDeclareWarConflictRejected();
}

void _grantaidRequiresEmbassyAndSufficientTreasury() {
  vedExpectGrantAidEmbassyTreasuryRejected();
}

void _grantaidRejectsAmountsNotAMultipleOf1000() {
  vedExpectGrantAidMultipleRejected();
}

void _grantaidThenSetSubsidyTowardSameTargetBothAccepted() {
  vedExpectGrantAidThenSubsidyAccepted();
}

void _setsubsidyRequiresAnEmbassyRefs3753R2() {
  vedExpectSubsidyEmbassyRequired();
}

void
_setsubsidyWithAnEmbassyIsAcceptedRegardlessOfTreasuryNoUpfrontCostRefs3753R3() {
  vedExpectSubsidyAcceptedLowTreasury();
}

void _setsubsidyWithAnEmbassyAndAValidPercentIsAccepted() {
  vedExpectSubsidyAcceptedValidPercent();
}

void _setsubsidyRejectsAPercentOutside520InStepsOf5() {
  vedExpectSubsidyRejectedInvalidPercent();
}
