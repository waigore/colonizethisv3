// Table-driven OrderEngine validateTrade scenarios (Refs #3949 wave 3).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy_test_support/colonizethis_economy_test_support.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import '../scenario_runner.dart';

import 'order_engine_validate_trade_expectation_shorthand.dart';

void vetRunAcceptsValidOfferWhenStockpileCoversQuantity() {
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
  expect(results.single.isAccepted, isTrue);
}

void vetRunRejectsMutualExclusionWhenBidAndOfferShareACommodity() {
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
  final results = vetValidate(game, engine);
  expect(results.every((r) => !r.isAccepted), isTrue);
  expect(results.map((r) => r.reason).toSet(), {
    TradeOrderRejectionReasons.mutualExclusion,
  });
}

void vetRunRejectsOfferExceedingAvailableStockpile() {
  final game = vetGameWith(
    player: vetGp1(
      stockpile: Stockpile(quantities: {CommodityCatalog.timber.id: 3}),
    ),
  );
  final result = vetAddTrade(
    game,
    vetTradeEngine(),
    validatorOffer(CommodityCatalog.timber.id, 10),
  );
  expect(result.isAccepted, isFalse);
  expect(result.reason, TradeOrderRejectionReasons.offerExceedsStockpile);
}

void vetRunAcceptsFirstBidWhenPlayerHasNoEmbassy() {
  final game = vetGameWith(player: vetGp1(treasury: 500));
  final result = vetAddTrade(
    game,
    vetTradeEngine(),
    validatorBid(CommodityCatalog.timber.id, 1),
  );
  expect(
    result.isAccepted,
    isTrue,
    reason:
        'Baseline kWorldMarketBaselineBidTypeCap == 1 admits exactly '
        'one bid even for a no-embassy GP.',
  );
}

void vetRunRejectsSecondDistinctCommodityBidWhenNoEmbassy() {
  final game = vetGameWith(player: vetGp1(treasury: 500));
  final engine = vetTradeEngine()
    ..addTradeOrderWithContext(
      game,
      vetTopology,
      'gp1',
      validatorBid(CommodityCatalog.timber.id, 1),
    );
  final result = vetAddTrade(
    game,
    engine,
    validatorBid(CommodityCatalog.iron.id, 1),
  );
  expect(result.isAccepted, isFalse);
  expect(result.reason, TradeOrderRejectionReasons.bidTypeCapExceeded);
}

List<RunnableScenario> orderEngineValidateTradeScenarios() => const [
  // dart format off
      RunnableScenario(
        label: 'accepts a valid offer when stockpile covers quantity',
        run: vetRunAcceptsValidOfferWhenStockpileCoversQuantity,
      ),
      RunnableScenario(
        label: 'rejects mutual exclusion when bid and offer share a commodity',
        run: vetRunRejectsMutualExclusionWhenBidAndOfferShareACommodity,
      ),
      RunnableScenario(
        label: 'rejects offer exceeding available stockpile',
        run: vetRunRejectsOfferExceedingAvailableStockpile,
      ),
      RunnableScenario(
        label: 'accepts first bid when player has no embassy (baseline bid type cap 1 per Refs #2924; SPEC/game/world-market.md § Bid type cap)',
        run: vetRunAcceptsFirstBidWhenPlayerHasNoEmbassy,
      ),
      RunnableScenario(
        label: 'rejects second distinct-commodity bid when no embassy (baseline bid type cap == 1 exhausted; Refs #2924)',
        run: vetRunRejectsSecondDistinctCommodityBidWhenNoEmbassy,
      ),
      // dart format on
];
