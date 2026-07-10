// Scenario run tear-offs for OrderEngine validateDiplomatic (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../diplomatic/diplomatic_orders_test_fixtures.dart';
import 'order_engine_validate_diplomatic_expectation_shorthand.dart';

void vedRunDeclareWarRejectedWhenAlreadyAtWar() {
  vedExpectRejected(
    vedGpMinor(relationState: RelationState.atWar),
    vedDeclareWarMinor,
    reasonContains: 'Already at war',
  );
}

void vedRunOfferPeaceRejectedWhenNotAtWar() {
  vedExpectRejected(
    vedGpMinor(),
    vedOfferPeaceMinor,
    reasonContains: 'not at war',
  );
}

void vedRunEstablishOvertureRejectedWhenTargetIsAtWarWithGp() {
  vedExpectRejected(
    vedGpMinor(
      relationState: RelationState.atWar,
      treasury: overtureConsulateCost + 100,
    ),
    vedEstablishOverture(OvertureStage.tradeConsulate),
    reasonContains: 'at war',
  );
}

void vedRunEstablishOvertureTradeConsulateRejectedWithoutDiplomaticExpertise() {
  vedExpectRejected(
    vedGpMinor(
      treasury: overtureConsulateCost + 100,
      techUnlocked: const {},
    ),
    vedEstablishOverture(OvertureStage.tradeConsulate),
    reasonContains: 'Diplomatic Expertise',
  );
}

void vedRunEstablishOvertureConsulateRejectedWhenTreasuryTooLow() {
  vedExpectRejected(
    vedGpMinor(treasury: overtureConsulateCost - 1),
    vedEstablishOverture(OvertureStage.tradeConsulate),
    reasonContains: 'Insufficient treasury',
  );
}

void vedRunEstablishOvertureEmbassyRequiresExistingConsulate() {
  vedExpectRejected(
    vedGpMinor(treasury: overtureEmbassyCost + 1000),
    vedEstablishOverture(OvertureStage.embassy),
    reasonContains: 'requires existing Trade Consulate',
  );
}

void vedRunEstablishOvertureSecondOrderForSameFactionInSameTurnRejected() {
  final order = vedEstablishOverture(OvertureStage.tradeConsulate);
  vedExpectSecondOrderRejected(
    vedGpMinor(treasury: overtureConsulateCost * 3),
    order,
    order,
    reasonContains: 'Already have a diplomatic order for this faction this turn',
  );
}

void vedRunSecondDiplomaticOrderToSameTargetDifferentTypeIsRejected() {
  vedExpectSecondOrderRejected(
    Game(
      id: 'g1',
      worldState: WorldState(
        turnState: const TurnState(
          phase: TurnPhase.orders,
          turnNumber: 1,
        ),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: const [
        Player(id: 'gp1', displayName: 'A', isHuman: false),
        Player(id: 'gp2', displayName: 'B', isHuman: false),
      ],
      diplomacyRelations: const [
        DiplomacyRelation(
          factionId1: 'gp1',
          factionId2: 'gp2',
          state: RelationState.atPeace,
          level: RelationLevel.neutral,
        ),
      ],
    ),
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

void vedRunGrantAidRequiresEmbassyAndSufficientTreasury() {
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

void vedRunGrantAidRejectsAmountsNotAMultipleOf1000() {
  vedExpectRejected(
    vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 5000),
    vedGrantAid(1500),
    reasonContains: 'multiple',
  );
}

void vedRunGrantAidThenSetSubsidyTowardSameTargetBothAccepted() {
  final game = vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 5000);
  final engine = OrderEngine();
  vedExpectAccepted(game, vedGrantAid(1000), engine: engine);
  vedExpectAccepted(game, vedSetSubsidy(10), engine: engine);
}

void vedRunSetSubsidyRequiresAnEmbassyRefs3753R2() {
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
}

void vedRunSetSubsidyWithEmbassyAcceptedRegardlessOfTreasuryRefs3753R3() {
  vedExpectAccepted(
    vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 10),
    vedSetSubsidy(20),
  );
}

void vedRunSetSubsidyWithEmbassyAndValidPercentAccepted() {
  vedExpectAccepted(
    vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 5000),
    vedSetSubsidy(5),
  );
}

void vedRunSetSubsidyRejectsPercentOutside520InStepsOf5() {
  vedExpectRejected(
    vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 5000),
    vedSetSubsidy(7),
    reasonContains: 'steps of',
  );
}

void vedRunSecondGrantAidTowardSameTargetRejected() {
  final game = vedGpMinor(
    overtureStage: OvertureStage.embassy,
    treasury: 5000,
  );
  final engine = OrderEngine();
  vedSubmit(game, vedGrantAid(1000), engine: engine);
  final grant = vedSubmit(game, vedGrantAid(1000), engine: engine);
  expect(grant.status, OrderValidationStatus.rejected);
}

void vedRunDeclareWarThenGrantAidTowardSameTargetRejected() {
  final game = vedGpMinor(
    overtureStage: OvertureStage.embassy,
    treasury: 5000,
  );
  final engine = OrderEngine();
  vedSubmit(game, vedDeclareWarMinor, engine: engine);
  final grant = vedSubmit(game, vedGrantAid(1000), engine: engine);
  expect(grant.status, OrderValidationStatus.rejected);
}
