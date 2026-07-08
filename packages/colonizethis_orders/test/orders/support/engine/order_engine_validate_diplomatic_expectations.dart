// Compact OrderEngine validateDiplomatic assertions (Refs #3949 wave 3).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'order_engine_validate_diplomatic_test_support.dart';

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

void _declarewarRejectedWhenAlreadyAtWar() {
  final game = gpMinorGame(
    relationState: RelationState.atWar,
    treasury: gpMinorOrderEngineTreasury,
  );
  final engine = OrderEngine();
  final result = engine.addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.declareWar,
      targetFactionId: 'minor1',
    ),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('Already at war'));
}

void _offerpeaceRejectedWhenNotAtWar() {
  final game = gpMinorGame(
    relationState: RelationState.atPeace,
    treasury: gpMinorOrderEngineTreasury,
  );
  final engine = OrderEngine();
  final result = engine.addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.offerPeace,
      targetFactionId: 'minor1',
    ),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('not at war'));
}

void _establishovertureRejectedWhenTargetIsAtWarWithGP() {
  final game = gpMinorGame(
    relationState: RelationState.atWar,
    overtureStage: OvertureStage.none,
    treasury: overtureConsulateCost + 100,
  );
  final engine = OrderEngine();
  final result = engine.addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: 'minor1',
      overtureStage: OvertureStage.tradeConsulate,
    ),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('at war'));
}

void _establishovertureTradeConsulateRejectedWithoutDiplomaticExpertise() {
  final game = gpMinorGame(
    relationState: RelationState.atPeace,
    overtureStage: OvertureStage.none,
    treasury: overtureConsulateCost + 100,
    techUnlocked: const {},
  );
  final engine = OrderEngine();
  final result = engine.addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: 'minor1',
      overtureStage: OvertureStage.tradeConsulate,
    ),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('Diplomatic Expertise'));
}

void _establishovertureConsulateRejectedWhenTreasuryTooLow() {
  final game = gpMinorGame(
    relationState: RelationState.atPeace,
    overtureStage: OvertureStage.none,
    treasury: overtureConsulateCost - 1,
  );
  final engine = OrderEngine();
  final result = engine.addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: 'minor1',
      overtureStage: OvertureStage.tradeConsulate,
    ),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('Insufficient treasury'));
}

void _establishovertureEmbassyRequiresExistingConsulate() {
  final game = gpMinorGame(
    relationState: RelationState.atPeace,
    overtureStage: OvertureStage.none,
    treasury: overtureEmbassyCost + 1000,
  );
  final engine = OrderEngine();
  final result = engine.addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: 'minor1',
      overtureStage: OvertureStage.embassy,
    ),
  );
  expect(result.status, OrderValidationStatus.rejected);
  expect(result.reason, contains('requires existing Trade Consulate'));
}

void _establishovertureSecondOrderForSameFactionInSameTurnRejected() {
  final game = gpMinorGame(
    relationState: RelationState.atPeace,
    overtureStage: OvertureStage.none,
    treasury: overtureConsulateCost * 3,
  );
  final engine = OrderEngine();
  final first = engine.addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: 'minor1',
      overtureStage: OvertureStage.tradeConsulate,
    ),
  );
  expect(first.status, OrderValidationStatus.accepted);
  final second = engine.addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.establishOverture,
      targetFactionId: 'minor1',
      overtureStage: OvertureStage.tradeConsulate,
    ),
  );
  expect(second.status, OrderValidationStatus.rejected);
  expect(
    second.reason,
    contains('Already have a diplomatic order for this faction this turn'),
  );
}

void _secondDiplomaticOrderToSameTargetDifferentTypeIsRejected() {
  final game = Game(
    id: 'g1',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 1),
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
  );
  final engine = OrderEngine();
  final first = engine.addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.declareWar,
      targetFactionId: 'gp2',
    ),
  );
  expect(first.status, OrderValidationStatus.accepted);
  final second = engine.addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.alliance,
      targetFactionId: 'gp2',
    ),
  );
  expect(second.status, OrderValidationStatus.rejected);
  expect(
    second.reason,
    contains('Already have a diplomatic order for this faction this turn'),
  );
}

void _grantaidRequiresEmbassyAndSufficientTreasury() {
  final game = gpMinorGame(
    relationState: RelationState.atPeace,
    overtureStage: OvertureStage.tradeConsulate,
    treasury: 5000,
  );
  final noEmbassy = OrderEngine().addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.grantAid,
      targetFactionId: 'minor1',
      amount: 1000,
    ),
  );
  expect(noEmbassy.status, OrderValidationStatus.rejected);
  expect(noEmbassy.reason, contains('Embassy required'));

  final gameWithEmbassy = gpMinorGame(
    relationState: RelationState.atPeace,
    overtureStage: OvertureStage.embassy,
    treasury: 500,
  );
  final insufficient = OrderEngine().addDiplomaticOrderWithContext(
    gameWithEmbassy,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.grantAid,
      targetFactionId: 'minor1',
      amount: 1000,
    ),
  );
  expect(insufficient.status, OrderValidationStatus.rejected);
  expect(insufficient.reason, contains('Insufficient treasury'));
}

void _grantaidRejectsAmountsNotAMultipleOf1000() {
  final game = gpMinorGame(
    relationState: RelationState.atPeace,
    overtureStage: OvertureStage.embassy,
    treasury: 5000,
  );
  final bad = OrderEngine().addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.grantAid,
      targetFactionId: 'minor1',
      amount: 1500,
    ),
  );
  expect(bad.status, OrderValidationStatus.rejected);
  expect(bad.reason, contains('multiple'));
}

void _grantaidThenSetSubsidyTowardSameTargetBothAccepted() {
  final game = gpMinorGame(
    relationState: RelationState.atPeace,
    overtureStage: OvertureStage.embassy,
    treasury: 5000,
  );
  final eng = OrderEngine();
  final g = eng.addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.grantAid,
      targetFactionId: 'minor1',
      amount: 1000,
    ),
  );
  expect(g.status, OrderValidationStatus.accepted);
  final s = eng.addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.setSubsidy,
      targetFactionId: 'minor1',
      amount: 10,
    ),
  );
  expect(s.status, OrderValidationStatus.accepted);
}

void _setsubsidyRequiresAnEmbassyRefs3753R2() {
  // No overture at all is rejected for the embassy prerequisite. A valid
  // percent is supplied so validation reaches the embassy check.
  final gameNoOverture = gpMinorGame(
    relationState: RelationState.atPeace,
    overtureStage: OvertureStage.none,
    treasury: 5000,
  );
  final noOverture = OrderEngine().addDiplomaticOrderWithContext(
    gameNoOverture,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.setSubsidy,
      targetFactionId: 'minor1',
      amount: 10,
    ),
  );
  expect(noOverture.status, OrderValidationStatus.rejected);
  expect(noOverture.reason, contains('Embassy required'));

  // A Trade Consulate alone is no longer sufficient for SetSubsidy.
  final gameConsulateOnly = gpMinorGame(
    relationState: RelationState.atPeace,
    overtureStage: OvertureStage.tradeConsulate,
    treasury: 5000,
  );
  final consulateOnly = OrderEngine().addDiplomaticOrderWithContext(
    gameConsulateOnly,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.setSubsidy,
      targetFactionId: 'minor1',
      amount: 10,
    ),
  );
  expect(consulateOnly.status, OrderValidationStatus.rejected);
  expect(consulateOnly.reason, contains('Embassy required'));
}

void
_setsubsidyWithAnEmbassyIsAcceptedRegardlessOfTreasuryNoUpfrontCostRefs3753R3() {
  final gameLowTreasury = gpMinorGame(
    relationState: RelationState.atPeace,
    overtureStage: OvertureStage.embassy,
    treasury: 10,
  );
  final accepted = OrderEngine().addDiplomaticOrderWithContext(
    gameLowTreasury,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.setSubsidy,
      targetFactionId: 'minor1',
      amount: 20,
    ),
  );
  // Percent subsidies charge nothing upfront, so even a near-empty treasury
  // is accepted.
  expect(accepted.status, OrderValidationStatus.accepted);
}

void _setsubsidyWithAnEmbassyAndAValidPercentIsAccepted() {
  final game = gpMinorGame(
    relationState: RelationState.atPeace,
    overtureStage: OvertureStage.embassy,
    treasury: 5000,
  );
  final accepted = OrderEngine().addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.setSubsidy,
      targetFactionId: 'minor1',
      amount: 5,
    ),
  );
  expect(accepted.status, OrderValidationStatus.accepted);
}

void _setsubsidyRejectsAPercentOutside520InStepsOf5() {
  final game = gpMinorGame(
    relationState: RelationState.atPeace,
    overtureStage: OvertureStage.embassy,
    treasury: 5000,
  );
  final engine = OrderEngine();
  final r = engine.addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.setSubsidy,
      targetFactionId: 'minor1',
      amount: 7,
    ),
  );
  expect(r.status, OrderValidationStatus.rejected);
  expect(r.reason, contains('steps of'));
}

void _secondGrantAidTowardSameTargetRejected() {
  final game = gpMinorGame(
    relationState: RelationState.atPeace,
    overtureStage: OvertureStage.embassy,
    treasury: 5000,
  );
  final engine = OrderEngine();
  engine.addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.grantAid,
      targetFactionId: 'minor1',
      amount: 1000,
    ),
  );
  final second = engine.addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.grantAid,
      targetFactionId: 'minor1',
      amount: 1000,
    ),
  );
  expect(second.status, OrderValidationStatus.rejected);
}

void _declarewarThenGrantAidTowardSameTargetRejected() {
  final game = gpMinorGame(
    relationState: RelationState.atPeace,
    overtureStage: OvertureStage.embassy,
    treasury: 5000,
  );
  final engine = OrderEngine();
  engine.addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.declareWar,
      targetFactionId: 'minor1',
    ),
  );
  final g = engine.addDiplomaticOrderWithContext(
    game,
    emptyTopology,
    'gp1',
    const DiplomaticOrder(
      type: DiplomaticOrderType.grantAid,
      targetFactionId: 'minor1',
      amount: 1000,
    ),
  );
  expect(g.status, OrderValidationStatus.rejected);
}
