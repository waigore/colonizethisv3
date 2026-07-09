// Compact OrderEngine validateTrade assertions (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Pins for [orderEngineValidateTradeScenarios] rows.
enum OrderEngineValidateTradeTarget {
  acceptsAValidOfferWhenStockpileCoversQuantity,
  rejectsMutualExclusionWhenBidAndOfferShareACommodity,
  rejectsOfferExceedingAvailableStockpile,
  acceptsFirstBidWhenPlayerHasNoEmbassy,
  rejectsSecondDistinctCommodityBidWhenNoEmbassy,
}

const _regionId = 'oldWorld';

final _topology = MapTopology(
  nodes: const [
    TopologyNode(
      id: 'P1',
      regionId: _regionId,
      type: TopologyNodeType.province,
    ),
  ],
  edges: const [],
);

Game _gameWith({
  required Player player,
  List<OvertureState> overtures = const [],
}) {
  return Game(
    id: 'g',
    worldState: WorldState(
      turnState: const TurnState(phase: TurnPhase.orders, turnNumber: 0),
      oldWorld: const RegionData(),
      newWorld: const RegionData(),
    ),
    players: [player],
    overtureStates: overtures,
  );
}

void runOrderEngineValidateTradeExpectation(
  OrderEngineValidateTradeTarget target,
) {
  switch (target) {
    case OrderEngineValidateTradeTarget
        .acceptsAValidOfferWhenStockpileCoversQuantity:
      _acceptsAValidOfferWhenStockpileCoversQuantity();
    case OrderEngineValidateTradeTarget
        .rejectsMutualExclusionWhenBidAndOfferShareACommodity:
      _rejectsMutualExclusionWhenBidAndOfferShareACommodity();
    case OrderEngineValidateTradeTarget.rejectsOfferExceedingAvailableStockpile:
      _rejectsOfferExceedingAvailableStockpile();
    case OrderEngineValidateTradeTarget.acceptsFirstBidWhenPlayerHasNoEmbassy:
      _acceptsFirstBidWhenPlayerHasNoEmbassy();
    case OrderEngineValidateTradeTarget
        .rejectsSecondDistinctCommodityBidWhenNoEmbassy:
      _rejectsSecondDistinctCommodityBidWhenNoEmbassy();
  }
}

void _acceptsAValidOfferWhenStockpileCoversQuantity() {
  final game = _gameWith(
    player: Player(
      id: 'gp1',
      displayName: 'GP1',
      isHuman: true,
      stockpile: Stockpile(quantities: {CommodityCatalog.timber.id: 10}),
    ),
  );
  final engine = OrderEngine(projector: projectOrderEffects)
    ..addTradeOrderWithContext(
      game,
      _topology,
      'gp1',
      validatorOffer(CommodityCatalog.timber.id, 5),
    );

  final results = engine.validatePlayerOrdersWithContext(
    game,
    _topology,
    'gp1',
  );

  expect(results, hasLength(1));
  expect(results.single.isAccepted, isTrue);
}

void _rejectsMutualExclusionWhenBidAndOfferShareACommodity() {
  final game = _gameWith(
    player: Player(
      id: 'gp1',
      displayName: 'GP1',
      isHuman: true,
      stockpile: Stockpile(quantities: {CommodityCatalog.timber.id: 20}),
    ),
    overtures: const [
      OvertureState(
        gpId: 'gp1',
        targetId: 'minor1',
        stage: OvertureStage.embassy,
        sinceTurn: 0,
      ),
    ],
  );
  final engine = OrderEngine(projector: projectOrderEffects)
    ..addTradeOrderWithContext(
      game,
      _topology,
      'gp1',
      validatorOffer(CommodityCatalog.timber.id, 5),
    )
    ..addTradeOrderWithContext(
      game,
      _topology,
      'gp1',
      validatorBid(CommodityCatalog.timber.id, 3),
    );

  final results = engine.validatePlayerOrdersWithContext(
    game,
    _topology,
    'gp1',
  );

  expect(results, hasLength(2));
  expect(results.every((r) => !r.isAccepted), isTrue);
  expect(results.map((r) => r.reason).toSet(), {
    TradeOrderRejectionReasons.mutualExclusion,
  });
}

void _rejectsOfferExceedingAvailableStockpile() {
  final game = _gameWith(
    player: Player(
      id: 'gp1',
      displayName: 'GP1',
      isHuman: true,
      stockpile: Stockpile(quantities: {CommodityCatalog.timber.id: 3}),
    ),
  );
  final result = OrderEngine(projector: projectOrderEffects)
      .addTradeOrderWithContext(
        game,
        _topology,
        'gp1',
        validatorOffer(CommodityCatalog.timber.id, 10),
      );

  expect(result.isAccepted, isFalse);
  expect(result.reason, TradeOrderRejectionReasons.offerExceedsStockpile);
}

void _acceptsFirstBidWhenPlayerHasNoEmbassy() {
  final game = _gameWith(
    player: Player(
      id: 'gp1',
      displayName: 'GP1',
      isHuman: true,
      treasury: 500,
      stockpile: Stockpile.empty,
    ),
  );
  final engine = OrderEngine(projector: projectOrderEffects);
  final firstResult = engine.addTradeOrderWithContext(
    game,
    _topology,
    'gp1',
    validatorBid(CommodityCatalog.timber.id, 1),
  );

  expect(
    firstResult.isAccepted,
    isTrue,
    reason:
        'Baseline kWorldMarketBaselineBidTypeCap == 1 admits exactly '
        'one bid even for a no-embassy GP.',
  );
}

void _rejectsSecondDistinctCommodityBidWhenNoEmbassy() {
  final game = _gameWith(
    player: Player(
      id: 'gp1',
      displayName: 'GP1',
      isHuman: true,
      treasury: 500,
      stockpile: Stockpile.empty,
    ),
  );
  final engine = OrderEngine(projector: projectOrderEffects);
  engine.addTradeOrderWithContext(
    game,
    _topology,
    'gp1',
    validatorBid(CommodityCatalog.timber.id, 1),
  );
  final secondResult = engine.addTradeOrderWithContext(
    game,
    _topology,
    'gp1',
    validatorBid(CommodityCatalog.iron.id, 1),
  );

  expect(secondResult.isAccepted, isFalse);
  expect(secondResult.reason, TradeOrderRejectionReasons.bidTypeCapExceeded);
}
