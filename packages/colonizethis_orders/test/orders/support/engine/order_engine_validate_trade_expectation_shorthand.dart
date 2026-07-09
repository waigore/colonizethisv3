// Compact order-engine validateTrade expectation shorthands (Refs #3949).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

const vetRegionId = 'oldWorld';

final vetTopology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'P1',
      regionId: vetRegionId,
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

const vetEmbassyOverture = [
  OvertureState(
    gpId: 'gp1',
    targetId: 'minor1',
    stage: OvertureStage.embassy,
    sinceTurn: 0,
  ),
];

Game vetGameWith({
  required Player player,
  List<OvertureState> overtures = const [],
}) =>
    Game(
      id: 'g',
      worldState: WorldState(
        turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
        oldWorld: const RegionData(),
        newWorld: const RegionData(),
      ),
      players: [player],
      overtureStates: overtures,
    );

Player vetGp1({
  Stockpile? stockpile,
  int treasury = 0,
  bool isHuman = true,
}) =>
    Player(
      id: 'gp1',
      displayName: 'GP1',
      isHuman: isHuman,
      stockpile: stockpile ?? Stockpile.empty,
      treasury: treasury,
    );

OrderEngine vetTradeEngine() => OrderEngine(projector: projectOrderEffects);

List<OrderValidationResult> vetValidate(Game game, OrderEngine engine) =>
    engine.validatePlayerOrdersWithContext(game, vetTopology, 'gp1');

OrderValidationResult vetAddTrade(
  Game game,
  OrderEngine engine,
  TradeOrder order,
) =>
    engine.addTradeOrderWithContext(game, vetTopology, 'gp1', order);

void vetExpectAccepted(OrderValidationResult result, {String? reason}) {
  expect(result.isAccepted, isTrue, reason: reason);
}

void vetExpectRejected(
  OrderValidationResult result, {
  String? reason,
}) {
  expect(result.isAccepted, isFalse);
  if (reason != null) {
    expect(result.reason, reason);
  }
}

void vetExpectAllRejected(
  List<OrderValidationResult> results, {
  Set<String>? reasons,
}) {
  expect(results.every((r) => !r.isAccepted), isTrue);
  if (reasons != null) {
    expect(results.map((r) => r.reason).toSet(), reasons);
  }
}

void vetExpectValidOfferAccepted() {
  final game = vetGameWith(
    player: vetGp1(
      stockpile: Stockpile(quantities: {CommodityCatalog.timber.id: 10}),
    ),
  );
  final engine = vetTradeEngine()
    ..addTradeOrderWithContext(
      game,
      vetTopology,
      'gp1',
      validatorOffer(CommodityCatalog.timber.id, 5),
    );
  final results = vetValidate(game, engine);
  expect(results, hasLength(1));
  vetExpectAccepted(results.single);
}

void vetExpectMutualExclusionRejected() {
  final game = vetGameWith(
    player: vetGp1(
      stockpile: Stockpile(quantities: {CommodityCatalog.timber.id: 20}),
    ),
    overtures: vetEmbassyOverture,
  );
  final engine = vetTradeEngine()
    ..addTradeOrderWithContext(
      game,
      vetTopology,
      'gp1',
      validatorOffer(CommodityCatalog.timber.id, 5),
    )
    ..addTradeOrderWithContext(
      game,
      vetTopology,
      'gp1',
      validatorBid(CommodityCatalog.timber.id, 3),
    );
  vetExpectAllRejected(
    vetValidate(game, engine),
    reasons: {TradeOrderRejectionReasons.mutualExclusion},
  );
}

void vetExpectOfferExceedsStockpileRejected() {
  final game = vetGameWith(
    player: vetGp1(
      stockpile: Stockpile(quantities: {CommodityCatalog.timber.id: 3}),
    ),
  );
  vetExpectRejected(
    vetAddTrade(
      game,
      vetTradeEngine(),
      validatorOffer(CommodityCatalog.timber.id, 10),
    ),
    reason: TradeOrderRejectionReasons.offerExceedsStockpile,
  );
}

void vetExpectFirstBidAcceptedNoEmbassy() {
  final game = vetGameWith(
    player: vetGp1(treasury: 500),
  );
  vetExpectAccepted(
    vetAddTrade(
      game,
      vetTradeEngine(),
      validatorBid(CommodityCatalog.timber.id, 1),
    ),
    reason:
        'Baseline kWorldMarketBaselineBidTypeCap == 1 admits exactly '
        'one bid even for a no-embassy GP.',
  );
}

void vetExpectSecondBidRejectedNoEmbassy() {
  final game = vetGameWith(
    player: vetGp1(treasury: 500),
  );
  final engine = vetTradeEngine()
    ..addTradeOrderWithContext(
      game,
      vetTopology,
      'gp1',
      validatorBid(CommodityCatalog.timber.id, 1),
    );
  vetExpectRejected(
    vetAddTrade(game, engine, validatorBid(CommodityCatalog.iron.id, 1)),
    reason: TradeOrderRejectionReasons.bidTypeCapExceeded,
  );
}
