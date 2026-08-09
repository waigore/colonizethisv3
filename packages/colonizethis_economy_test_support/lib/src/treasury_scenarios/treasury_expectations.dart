// dart format off
// Compact treasury UI composition and GP-credit assertions (Refs #3939 phase 3 slice 13).
import 'package:colonizethis_data/colonizethis_data.dart' as data;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
/// Pins for [TreasuryUiCompositionExpectation.maxAffordableQty].
typedef MaxAffordableQtyPin = ({String commodityId, int qty});
/// Pins for [TreasuryUiCompositionExpectation.spendIncrementExceedsBudget].
typedef SpendIncrementExceedsBudgetPin = ({String commodityId, int delta});
/// Data-driven expectations for [TreasuryUiCompositionScenario] rows.
class TreasuryUiCompositionExpectation {
  const TreasuryUiCompositionExpectation({this.budget, this.commodityPrices, this.headroom, this.maxAffordableQty, this.headroomLessThanCommodity, this.spendIncrementExceedsBudget, this.budgetLessThanCommodity});
  final int? budget;
  final Map<CommodityId, int>? commodityPrices;
  final int? headroom;
  final MaxAffordableQtyPin? maxAffordableQty;
  final CommodityId? headroomLessThanCommodity;
  final SpendIncrementExceedsBudgetPin? spendIncrementExceedsBudget;
  final CommodityId? budgetLessThanCommodity;
}
void assertTreasuryUiCompositionExpectation({required Game game, required data.ResourceRules rules, required int budget, required int currentSpend, required TreasuryUiCompositionExpectation expectation}) {
  if (expectation.budget != null) {
    expect(budget, expectation.budget);
  }
  if (expectation.commodityPrices != null) {
    for (final entry in expectation.commodityPrices!.entries) {
      expect(effectiveMarketPriceForCommodityId(commodityId: entry.key, worldMarket: game.worldMarketState, resourceRules: rules), entry.value);
    }
  }
  final int resolvedHeadroom = expectation.headroom ?? budget - currentSpend;
  if (expectation.headroom != null) {
    expect(resolvedHeadroom, expectation.headroom);
  }
  if (expectation.maxAffordableQty != null) {
    final pin = expectation.maxAffordableQty!;
    final int? rowPrice = effectiveMarketPriceForCommodityId(commodityId: pin.commodityId, worldMarket: game.worldMarketState, resourceRules: rules);
    expect(resolvedHeadroom ~/ rowPrice!, pin.qty);
  }
  if (expectation.headroomLessThanCommodity != null) {
    final int? price = effectiveMarketPriceForCommodityId(commodityId: expectation.headroomLessThanCommodity!, worldMarket: game.worldMarketState, resourceRules: rules);
    expect(resolvedHeadroom < price!, isTrue);
  }
  if (expectation.spendIncrementExceedsBudget != null) {
    final pin = expectation.spendIncrementExceedsBudget!;
    final int? rowPrice = effectiveMarketPriceForCommodityId(commodityId: pin.commodityId, worldMarket: game.worldMarketState, resourceRules: rules);
    expect(currentSpend + pin.delta * rowPrice! > budget, isTrue);
  }
  if (expectation.budgetLessThanCommodity != null) {
    final int? rowPrice = effectiveMarketPriceForCommodityId(commodityId: expectation.budgetLessThanCommodity!, worldMarket: game.worldMarketState, resourceRules: rules);
    expect(budget < rowPrice!, isTrue);
  }
}
/// Optional extra assertions for [TreasuryAvailableScenario] rows.
class TreasuryAvailableExpectation {
  const TreasuryAvailableExpectation({this.omitProjectedDeltaAlias = false, this.ignoredProjectedDeltaWhenTreasuryZero});
  /// When true, calling with `projectedNonBidTreasuryDelta: 0` matches omitting
  /// the parameter (legacy raw-treasury contract).
  final bool omitProjectedDeltaAlias;
  /// When set, asserts that this projected delta is ignored when treasury is 0.
  final int? ignoredProjectedDeltaWhenTreasuryZero;
}
void assertTreasuryAvailableExpectation({required Game game, required String playerId, required TreasuryAvailableExpectation expectation}) {
  if (expectation.omitProjectedDeltaAlias) {
    expect(treasuryAvailableForBidsByPlayer(game: game, playerId: playerId, projectedNonBidTreasuryDelta: 0), treasuryAvailableForBidsByPlayer(game: game, playerId: playerId));
  }
  if (expectation.ignoredProjectedDeltaWhenTreasuryZero != null) {
    expect(treasuryAvailableForBidsByPlayer(game: game, playerId: playerId, projectedNonBidTreasuryDelta: expectation.ignoredProjectedDeltaWhenTreasuryZero!), 0);
  }
}
/// Data-driven expectations for carry-forward bid-notional rows.
class CarryForwardBidNotionalExpectation {
  const CarryForwardBidNotionalExpectation({this.catalogCommodity, this.quantity, this.expectedNotional}) : assert((expectedNotional != null) || (catalogCommodity != null && quantity != null), 'Provide expectedNotional or catalogCommodity+quantity');
  final CommodityId? catalogCommodity;
  final int? quantity;
  final int? expectedNotional;
}
void assertCarryForwardBidNotionalExpectation({required int notional, required data.ResourceRules rules, required CarryForwardBidNotionalExpectation expectation}) {
  if (expectation.expectedNotional != null) { expect(notional, expectation.expectedNotional); return; }
  final catalogPrice = rules.defaultMarketPriceForCommodityId(expectation.catalogCommodity!) ?? 0;
  expect(catalogPrice, greaterThan(0));
  expect(notional, expectation.quantity! * catalogPrice);
}
/// Data-driven expectations for [GpTreasuryCreditAccumulator] scenario rows.
class GpTreasuryCreditExpectation<T extends num> {
  const GpTreasuryCreditExpectation({this.isEmpty, this.total, this.totalCloseTo, this.view, this.viewCloseTo, this.viewKeyOrder, this.viewUnmodifiable = false, this.totalEqualsNaiveViewSum = false});
  final bool? isEmpty;
  final T? total;
  final T? totalCloseTo;
  final Map<String, T>? view;
  final Map<String, T>? viewCloseTo;
  final List<String>? viewKeyOrder;
  final bool viewUnmodifiable;
  final bool totalEqualsNaiveViewSum;
}
void assertGpTreasuryCreditExpectation<T extends num>(GpTreasuryCreditAccumulator<T> acc, GpTreasuryCreditExpectation<T> expectation) {
  if (expectation.isEmpty != null) {
    expect(acc.isEmpty, expectation.isEmpty);
  }
  if (expectation.total != null) {
    expect(acc.total, expectation.total);
  }
  if (expectation.totalCloseTo != null) {
    expect(acc.total, closeTo(expectation.totalCloseTo!, 1e-12));
  }
  if (expectation.view != null) {
    expect(acc.view, expectation.view);
  }
  if (expectation.viewCloseTo != null) {
    for (final entry in expectation.viewCloseTo!.entries) {
      expect(acc.view[entry.key], closeTo(entry.value, 1e-12));
    }
  }
  if (expectation.viewKeyOrder != null) {
    expect(acc.view.keys.toList(), expectation.viewKeyOrder);
  }
  if (expectation.viewUnmodifiable) {
    expect(() => acc.view['gpB'] = (0 as T), throwsUnsupportedError);
  }
  if (expectation.totalEqualsNaiveViewSum) {
    if (acc is GpTreasuryCreditAccumulator<double>) {
      final naive = acc.view.values.fold<double>(0.0, (a, b) => a + b);
      expect(acc.total, closeTo(naive, 1e-12));
    } else {
      final naive = acc.view.values.fold<int>(0, (a, b) => a + b.toInt());
      expect(acc.total, naive);
    }
  }
}
/// Pins for per-order [bidTreasurySpendForOrder] parity rows.
typedef BidTreasurySpendPin = ({TradeOrder order, int expected, String? reason});
/// Data-driven expectations for staged vs carry-forward bid-spend parity rows.
class BidSpendParityExpectation {
  const BidSpendParityExpectation({this.stagedSpend, this.carryForwardEqualsStaged = true, this.bidTreasurySpendPins});
  final int? stagedSpend;
  final bool carryForwardEqualsStaged;
  final List<BidTreasurySpendPin>? bidTreasurySpendPins;
}
void assertBidSpendParityExpectation({required int staged, required int carryForward, required Game game, required data.ResourceRules rules, required BidSpendParityExpectation expectation}) {
  if (expectation.stagedSpend != null) {
    expect(staged, expectation.stagedSpend);
  }
  if (expectation.carryForwardEqualsStaged) {
    expect(carryForward, staged, reason: 'both entry points must delegate to the same summation core');
  }
  if (expectation.bidTreasurySpendPins != null) {
    for (final pin in expectation.bidTreasurySpendPins!) {
      expect(
        bidTreasurySpendForOrder(order: pin.order, worldMarket: game.worldMarketState, resourceRules: rules),
        pin.expected,
        reason: pin.reason,
      );
    }
  }
}
// dart format on
