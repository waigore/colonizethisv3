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
  final order = vedEstablishOverture(OvertureStage.tradeConsulate);
  vedExpectSecondOrderRejected(
    vedGpMinor(treasury: overtureConsulateCost * 3),
    order,
    order,
    reasonContains: 'Already have a diplomatic order for this faction this turn',
  );
}

void _secondDiplomaticOrderToSameTargetDifferentTypeIsRejected() {
  vedExpectSecondOrderRejected(
    vedTwoGpPeaceGame(),
    const DiplomaticOrder(
      type: DiplomaticOrderType.declareWar,
      targetFactionId: 'gp2',
    ),
    const DiplomaticOrder(
      type: DiplomaticOrderType.alliance,
      targetFactionId: 'gp2',
    ),
    reasonContains: 'Already have a diplomatic order for this faction this turn',
  );
}

void _grantaidRequiresEmbassyAndSufficientTreasury() {
  vedExpectRejected(
    vedGpMinor(overtureStage: OvertureStage.tradeConsulate, treasury: 5000),
    vedGrantAid(1000),
    reasonContains: 'Embassy required',
  );
  vedExpectRejected(
    vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 500),
    vedGrantAid(1000),
    reasonContains: 'Insufficient treasury',
  );
}

void _grantaidRejectsAmountsNotAMultipleOf1000() {
  vedExpectRejected(
    vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 5000),
    vedGrantAid(1500),
    reasonContains: 'multiple',
  );
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
