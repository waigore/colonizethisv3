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
}) => gpMinorGame(
  relationState: relationState,
  overtureStage: overtureStage,
  treasury: treasury ?? gpMinorOrderEngineTreasury,
  techUnlocked: techUnlocked,
);

OrderValidationResult vedSubmit(
  Game game,
  DiplomaticOrder order, {
  OrderEngine? engine,
}) => (engine ?? OrderEngine()).addDiplomaticOrderWithContext(
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
