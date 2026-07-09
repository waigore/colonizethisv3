part of 'order_engine_validate_diplomatic_expectations.dart';

void _declarewarRejectedWhenAlreadyAtWar() {
  vedExpectRejected(
    vedGpMinor(relationState: RelationState.atWar),
    vedDeclareWarMinor,
    reasonContains: 'Already at war',
  );
}

void _offerpeaceRejectedWhenNotAtWar() {
  vedExpectRejected(
    vedGpMinor(),
    vedOfferPeaceMinor,
    reasonContains: 'not at war',
  );
}

void _establishovertureRejectedWhenTargetIsAtWarWithGP() {
  vedExpectRejected(
    vedGpMinor(
      relationState: RelationState.atWar,
      treasury: overtureConsulateCost + 100,
    ),
    vedEstablishOverture(OvertureStage.tradeConsulate),
    reasonContains: 'at war',
  );
}

void _establishovertureTradeConsulateRejectedWithoutDiplomaticExpertise() {
  vedExpectRejected(
    vedGpMinor(
      treasury: overtureConsulateCost + 100,
      techUnlocked: const {},
    ),
    vedEstablishOverture(OvertureStage.tradeConsulate),
    reasonContains: 'Diplomatic Expertise',
  );
}

void _establishovertureConsulateRejectedWhenTreasuryTooLow() {
  vedExpectRejected(
    vedGpMinor(treasury: overtureConsulateCost - 1),
    vedEstablishOverture(OvertureStage.tradeConsulate),
    reasonContains: 'Insufficient treasury',
  );
}

void _establishovertureEmbassyRequiresExistingConsulate() {
  vedExpectRejected(
    vedGpMinor(treasury: overtureEmbassyCost + 1000),
    vedEstablishOverture(OvertureStage.embassy),
    reasonContains: 'requires existing Trade Consulate',
  );
}

void _establishovertureSecondOrderForSameFactionInSameTurnRejected() {
  final game = vedGpMinor(treasury: overtureConsulateCost * 3);
  final engine = OrderEngine();
  final order = vedEstablishOverture(OvertureStage.tradeConsulate);
  vedExpectAccepted(game, order, engine: engine);
  final second = vedSubmit(game, order, engine: engine);
  expect(second.status, OrderValidationStatus.rejected);
  expect(
    second.reason,
    contains('Already have a diplomatic order for this faction this turn'),
  );
}

void _secondDiplomaticOrderToSameTargetDifferentTypeIsRejected() {
  final game = vedTwoGpPeaceGame();
  final engine = OrderEngine();
  vedExpectAccepted(
    game,
    const DiplomaticOrder(
      type: DiplomaticOrderType.declareWar,
      targetFactionId: 'gp2',
    ),
    engine: engine,
  );
  final second = vedSubmit(
    game,
    const DiplomaticOrder(
      type: DiplomaticOrderType.alliance,
      targetFactionId: 'gp2',
    ),
    engine: engine,
  );
  expect(second.status, OrderValidationStatus.rejected);
  expect(
    second.reason,
    contains('Already have a diplomatic order for this faction this turn'),
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
  final game = vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 5000);
  final engine = OrderEngine();
  vedExpectAccepted(game, vedGrantAid(1000), engine: engine);
  vedExpectAccepted(game, vedSetSubsidy(10), engine: engine);
}

void _setsubsidyRequiresAnEmbassyRefs3753R2() {
  // No overture at all is rejected for the embassy prerequisite. A valid
  // percent is supplied so validation reaches the embassy check.
  vedExpectRejected(
    vedGpMinor(treasury: 5000),
    vedSetSubsidy(10),
    reasonContains: 'Embassy required',
  );

  // A Trade Consulate alone is no longer sufficient for SetSubsidy.
  vedExpectRejected(
    vedGpMinor(overtureStage: OvertureStage.tradeConsulate, treasury: 5000),
    vedSetSubsidy(10),
    reasonContains: 'Embassy required',
  );
}

void
_setsubsidyWithAnEmbassyIsAcceptedRegardlessOfTreasuryNoUpfrontCostRefs3753R3() {
  // Percent subsidies charge nothing upfront, so even a near-empty treasury
  // is accepted.
  vedExpectAccepted(
    vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 10),
    vedSetSubsidy(20),
  );
}

void _setsubsidyWithAnEmbassyAndAValidPercentIsAccepted() {
  vedExpectAccepted(
    vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 5000),
    vedSetSubsidy(5),
  );
}

void _setsubsidyRejectsAPercentOutside520InStepsOf5() {
  vedExpectRejected(
    vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 5000),
    vedSetSubsidy(7),
    reasonContains: 'steps of',
  );
}
