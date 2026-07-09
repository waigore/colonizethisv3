// Compact OrderEngine validateDiplomatic assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'order_engine_validate_diplomatic_expectation_shorthand.dart';
part 'order_engine_validate_diplomatic_expectations_part1.dart';
part 'order_engine_validate_diplomatic_expectations_part2.dart';


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
      _declarewarRejectedWhenAlreadyAtWar();
    case OrderEngineValidateDiplomaticTarget.offerpeaceRejectedWhenNotAtWar:
      _offerpeaceRejectedWhenNotAtWar();
    case OrderEngineValidateDiplomaticTarget
        .establishovertureRejectedWhenTargetIsAtWarWithGP:
      _establishovertureRejectedWhenTargetIsAtWarWithGP();
    case OrderEngineValidateDiplomaticTarget
        .establishovertureTradeConsulateRejectedWithoutDiplomaticExpertise:
      _establishovertureTradeConsulateRejectedWithoutDiplomaticExpertise();
    case OrderEngineValidateDiplomaticTarget
        .establishovertureConsulateRejectedWhenTreasuryTooLow:
      _establishovertureConsulateRejectedWhenTreasuryTooLow();
    case OrderEngineValidateDiplomaticTarget
        .establishovertureEmbassyRequiresExistingConsulate:
      _establishovertureEmbassyRequiresExistingConsulate();
    case OrderEngineValidateDiplomaticTarget
        .establishovertureSecondOrderForSameFactionInSameTurnRejected:
      _establishovertureSecondOrderForSameFactionInSameTurnRejected();
    case OrderEngineValidateDiplomaticTarget
        .secondDiplomaticOrderToSameTargetDifferentTypeIsRejected:
      _secondDiplomaticOrderToSameTargetDifferentTypeIsRejected();
    case OrderEngineValidateDiplomaticTarget
        .grantaidRequiresEmbassyAndSufficientTreasury:
      _grantaidRequiresEmbassyAndSufficientTreasury();
    case OrderEngineValidateDiplomaticTarget
        .grantaidRejectsAmountsNotAMultipleOf1000:
      _grantaidRejectsAmountsNotAMultipleOf1000();
    case OrderEngineValidateDiplomaticTarget
        .grantaidThenSetSubsidyTowardSameTargetBothAccepted:
      _grantaidThenSetSubsidyTowardSameTargetBothAccepted();
    case OrderEngineValidateDiplomaticTarget
        .setsubsidyRequiresAnEmbassyRefs3753R2:
      _setsubsidyRequiresAnEmbassyRefs3753R2();
    case OrderEngineValidateDiplomaticTarget
        .setsubsidyWithAnEmbassyIsAcceptedRegardlessOfTreasuryNoUpfrontCostRefs3753R3:
      _setsubsidyWithAnEmbassyIsAcceptedRegardlessOfTreasuryNoUpfrontCostRefs3753R3();
    case OrderEngineValidateDiplomaticTarget
        .setsubsidyWithAnEmbassyAndAValidPercentIsAccepted:
      _setsubsidyWithAnEmbassyAndAValidPercentIsAccepted();
    case OrderEngineValidateDiplomaticTarget
        .setsubsidyRejectsAPercentOutside520InStepsOf5:
      _setsubsidyRejectsAPercentOutside520InStepsOf5();
    case OrderEngineValidateDiplomaticTarget
        .secondGrantAidTowardSameTargetRejected:
      _secondGrantAidTowardSameTargetRejected();
    case OrderEngineValidateDiplomaticTarget
        .declarewarThenGrantAidTowardSameTargetRejected:
      _declarewarThenGrantAidTowardSameTargetRejected();
  }
}


