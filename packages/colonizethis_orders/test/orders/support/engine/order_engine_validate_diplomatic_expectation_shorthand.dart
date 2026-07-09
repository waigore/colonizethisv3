// Compact order-engine diplomatic validation expectation shorthands (Refs #3949).

import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import '../diplomatic/diplomatic_orders_test_fixtures.dart';

abstract final class VedIds {
  static const gp = 'gp1';
  static const minor = 'minor1';
}

const vedDeclareWarMinor = DiplomaticOrder(
  type: DiplomaticOrderType.declareWar,
  targetFactionId: VedIds.minor,
);

const vedOfferPeaceMinor = DiplomaticOrder(
  type: DiplomaticOrderType.offerPeace,
  targetFactionId: VedIds.minor,
);

DiplomaticOrder vedEstablishOverture(OvertureStage stage) => DiplomaticOrder(
  type: DiplomaticOrderType.establishOverture,
  targetFactionId: VedIds.minor,
  overtureStage: stage,
);

DiplomaticOrder vedGrantAid(int amount) => DiplomaticOrder(
  type: DiplomaticOrderType.grantAid,
  targetFactionId: VedIds.minor,
  amount: amount,
);

DiplomaticOrder vedSetSubsidy(int amount) => DiplomaticOrder(
  type: DiplomaticOrderType.setSubsidy,
  targetFactionId: VedIds.minor,
  amount: amount,
);

Game vedGpMinor({
  RelationState relationState = RelationState.atPeace,
  OvertureStage overtureStage = OvertureStage.none,
  int? treasury,
  Map<String, bool>? techUnlocked,
}) =>
    gpMinorGame(
      relationState: relationState,
      overtureStage: overtureStage,
      treasury: treasury ?? gpMinorOrderEngineTreasury,
      techUnlocked: techUnlocked,
    );

Game vedTwoGpPeaceGame({int turnNumber = 1}) => Game(
  id: 'g1',
  worldState: WorldState(
    turnState: TurnState(phase: TurnPhase.orders, turnNumber: turnNumber),
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

OrderValidationResult vedSubmit(
  Game game,
  DiplomaticOrder order, {
  OrderEngine? engine,
}) =>
    (engine ?? OrderEngine()).addDiplomaticOrderWithContext(
      game,
      emptyTopology,
      VedIds.gp,
      order,
    );

void vedExpectRejected(
  Game game,
  DiplomaticOrder order, {
  String? reasonContains,
  OrderEngine? engine,
}) {
  final result = vedSubmit(game, order, engine: engine);
  expect(result.status, OrderValidationStatus.rejected);
  if (reasonContains != null) {
    expect(result.reason, contains(reasonContains));
  }
}

void vedExpectAccepted(
  Game game,
  DiplomaticOrder order, {
  OrderEngine? engine,
}) {
  final result = vedSubmit(game, order, engine: engine);
  expect(result.status, OrderValidationStatus.accepted);
}

void vedExpectSecondOrderRejected(
  Game game,
  DiplomaticOrder first,
  DiplomaticOrder second, {
  OrderEngine? engine,
  String? reasonContains,
}) {
  final activeEngine = engine ?? OrderEngine();
  vedExpectAccepted(game, first, engine: activeEngine);
  final result = vedSubmit(game, second, engine: activeEngine);
  expect(result.status, OrderValidationStatus.rejected);
  if (reasonContains != null) {
    expect(result.reason, contains(reasonContains));
  }
}

void vedExpectGrantAidThenSubsidyAccepted() {
  final game = vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 5000);
  final engine = OrderEngine();
  vedExpectAccepted(game, vedGrantAid(1000), engine: engine);
  vedExpectAccepted(game, vedSetSubsidy(10), engine: engine);
}

void vedExpectGrantAidRejectedAfterPrior({
  required DiplomaticOrder prior,
  int treasury = 5000,
}) {
  final game = vedGpMinor(overtureStage: OvertureStage.embassy, treasury: treasury);
  final engine = OrderEngine();
  vedSubmit(game, prior, engine: engine);
  final grant = vedSubmit(game, vedGrantAid(1000), engine: engine);
  expect(grant.status, OrderValidationStatus.rejected);
}

void vedExpectDeclareWarRejectedWhenAtWar() {
  vedExpectRejected(
    vedGpMinor(relationState: RelationState.atWar),
    vedDeclareWarMinor,
    reasonContains: 'Already at war',
  );
}

void vedExpectOfferPeaceRejectedWhenNotAtWar() {
  vedExpectRejected(
    vedGpMinor(),
    vedOfferPeaceMinor,
    reasonContains: 'not at war',
  );
}

void vedExpectOvertureRejectedAtWar() {
  vedExpectRejected(
    vedGpMinor(
      relationState: RelationState.atWar,
      treasury: overtureConsulateCost + 100,
    ),
    vedEstablishOverture(OvertureStage.tradeConsulate),
    reasonContains: 'at war',
  );
}

void vedExpectConsulateRejectedNoDiplomaticExpertise() {
  vedExpectRejected(
    vedGpMinor(
      treasury: overtureConsulateCost + 100,
      techUnlocked: const {},
    ),
    vedEstablishOverture(OvertureStage.tradeConsulate),
    reasonContains: 'Diplomatic Expertise',
  );
}

void vedExpectConsulateRejectedLowTreasury() {
  vedExpectRejected(
    vedGpMinor(treasury: overtureConsulateCost - 1),
    vedEstablishOverture(OvertureStage.tradeConsulate),
    reasonContains: 'Insufficient treasury',
  );
}

void vedExpectEmbassyRequiresConsulate() {
  vedExpectRejected(
    vedGpMinor(treasury: overtureEmbassyCost + 1000),
    vedEstablishOverture(OvertureStage.embassy),
    reasonContains: 'requires existing Trade Consulate',
  );
}

void vedExpectSubsidyEmbassyRequired() {
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

void vedExpectSubsidyAcceptedLowTreasury() {
  vedExpectAccepted(
    vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 10),
    vedSetSubsidy(20),
  );
}

void vedExpectSubsidyAcceptedValidPercent() {
  vedExpectAccepted(
    vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 5000),
    vedSetSubsidy(5),
  );
}

void vedExpectSubsidyRejectedInvalidPercent() {
  vedExpectRejected(
    vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 5000),
    vedSetSubsidy(7),
    reasonContains: 'steps of',
  );
}

void vedExpectDuplicateOvertureRejected() {
  final order = vedEstablishOverture(OvertureStage.tradeConsulate);
  vedExpectSecondOrderRejected(
    vedGpMinor(treasury: overtureConsulateCost * 3),
    order,
    order,
    reasonContains: 'Already have a diplomatic order for this faction this turn',
  );
}

void vedExpectGpAllianceDeclareWarConflictRejected() {
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

void vedExpectGrantAidEmbassyTreasuryRejected() {
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

void vedExpectGrantAidMultipleRejected() {
  vedExpectRejected(
    vedGpMinor(overtureStage: OvertureStage.embassy, treasury: 5000),
    vedGrantAid(1500),
    reasonContains: 'multiple',
  );
}

void vedExpectSecondGrantAidRejected() {
  vedExpectGrantAidRejectedAfterPrior(prior: vedGrantAid(1000));
}

void vedExpectDeclareWarThenGrantAidRejected() {
  vedExpectGrantAidRejectedAfterPrior(prior: vedDeclareWarMinor);
}
