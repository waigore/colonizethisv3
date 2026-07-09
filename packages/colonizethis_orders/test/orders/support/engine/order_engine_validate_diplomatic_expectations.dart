// Compact OrderEngine validateDiplomatic assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../diplomatic/diplomatic_orders_test_fixtures.dart';
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
        vedExpectRejected(
          vedGpMinor(relationState: RelationState.atWar),
          vedDeclareWarMinor,
          reasonContains: 'Already at war',
        );
    case OrderEngineValidateDiplomaticTarget.offerpeaceRejectedWhenNotAtWar:
        vedExpectRejected(
          vedGpMinor(),
          vedOfferPeaceMinor,
          reasonContains: 'not at war',
        );
    case OrderEngineValidateDiplomaticTarget
        .establishovertureRejectedWhenTargetIsAtWarWithGP:
        vedExpectRejected(
          vedGpMinor(
            relationState: RelationState.atWar,
            treasury: overtureConsulateCost + 100,
          ),
          vedEstablishOverture(OvertureStage.tradeConsulate),
          reasonContains: 'at war',
        );
    case OrderEngineValidateDiplomaticTarget
        .establishovertureTradeConsulateRejectedWithoutDiplomaticExpertise:
        vedExpectRejected(
          vedGpMinor(
            treasury: overtureConsulateCost + 100,
            techUnlocked: const {},
          ),
          vedEstablishOverture(OvertureStage.tradeConsulate),
          reasonContains: 'Diplomatic Expertise',
        );
    case OrderEngineValidateDiplomaticTarget
        .establishovertureConsulateRejectedWhenTreasuryTooLow:
        vedExpectRejected(
          vedGpMinor(treasury: overtureConsulateCost - 1),
          vedEstablishOverture(OvertureStage.tradeConsulate),
          reasonContains: 'Insufficient treasury',
        );
    case OrderEngineValidateDiplomaticTarget
        .establishovertureEmbassyRequiresExistingConsulate:
        vedExpectRejected(
          vedGpMinor(treasury: overtureEmbassyCost + 1000),
          vedEstablishOverture(OvertureStage.embassy),
          reasonContains: 'requires existing Trade Consulate',
        );
    case OrderEngineValidateDiplomaticTarget
        .establishovertureSecondOrderForSameFactionInSameTurnRejected:
        final order = vedEstablishOverture(OvertureStage.tradeConsulate);
        vedExpectSecondOrderRejected(
          vedGpMinor(treasury: overtureConsulateCost * 3),
          order,
          order,
          reasonContains: 'Already have a diplomatic order for this faction this turn',
        );
    case OrderEngineValidateDiplomaticTarget
        .secondDiplomaticOrderToSameTargetDifferentTypeIsRejected:
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
    case OrderEngineValidateDiplomaticTarget
        .grantaidRequiresEmbassyAndSufficientTreasury:
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
    case OrderEngineValidateDiplomaticTarget
        .grantaidRejectsAmountsNotAMultipleOf1000:
        vedExpectRejected(
          vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 5000),
          vedGrantAid(1500),
          reasonContains: 'multiple',
        );
    case OrderEngineValidateDiplomaticTarget
        .grantaidThenSetSubsidyTowardSameTargetBothAccepted:
        final game = vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 5000);
        final engine = OrderEngine();
        vedExpectAccepted(game, vedGrantAid(1000), engine: engine);
        vedExpectAccepted(game, vedSetSubsidy(10), engine: engine);
    case OrderEngineValidateDiplomaticTarget
        .setsubsidyRequiresAnEmbassyRefs3753R2:
        vedExpectRejected(
          vedGpMinor(treasury: 5000),
          vedSetSubsidy(10),
          reasonContains: 'Embassy required',
        );
        vedExpectRejected(
          vedGpMinor(overtureStage: OvertureStage.tradeConsulate, treasury: 5000),
          vedSetSubsidy(10),
          reasonContains: 'Embassy required',
        );
    case OrderEngineValidateDiplomaticTarget
        .setsubsidyWithAnEmbassyIsAcceptedRegardlessOfTreasuryNoUpfrontCostRefs3753R3:
        vedExpectAccepted(
          vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 10),
          vedSetSubsidy(20),
        );
    case OrderEngineValidateDiplomaticTarget
        .setsubsidyWithAnEmbassyAndAValidPercentIsAccepted:
        vedExpectAccepted(
          vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 5000),
          vedSetSubsidy(5),
        );
    case OrderEngineValidateDiplomaticTarget
        .setsubsidyRejectsAPercentOutside520InStepsOf5:
        vedExpectRejected(
          vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 5000),
          vedSetSubsidy(7),
          reasonContains: 'steps of',
        );
    case OrderEngineValidateDiplomaticTarget
        .secondGrantAidTowardSameTargetRejected:
        vedExpectGrantAidRejectedAfterPrior(prior: vedGrantAid(1000));
    case OrderEngineValidateDiplomaticTarget
        .declarewarThenGrantAidTowardSameTargetRejected:
        vedExpectGrantAidRejectedAfterPrior(prior: vedDeclareWarMinor);
  }
}
