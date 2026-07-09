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
