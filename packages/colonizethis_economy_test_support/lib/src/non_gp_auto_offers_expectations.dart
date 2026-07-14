// dart format off
// Compact non-GP auto-offer result assertions (Refs #3939 phase 3 slice 12).
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
/// Pins purchased-tile index attribution resolved from an auto-offer origin tile.
class PurchasedTileFrrAttributionExpectation {
  const PurchasedTileFrrAttributionExpectation({required this.factionId, required this.owningGpId, required this.sourceFactionId});
  final String factionId;
  final String owningGpId;
  final String sourceFactionId;
}
/// Per-faction offer list pins for [NonGpAutoOffersExpectation].
class FactionAutoOffersExpectation {
  const FactionAutoOffersExpectation({this.length, this.commodityIds, this.originTileKeys, this.singleCommodityId, this.singleOriginTileKey, this.standardPriorityOneOffers = false, this.excludeCommodity});
  final int? length;
  final List<CommodityId>? commodityIds;
  final List<String>? originTileKeys;
  final CommodityId? singleCommodityId;
  final String? singleOriginTileKey;
  final bool standardPriorityOneOffers;
  final CommodityId? excludeCommodity;
}
/// Data-driven expectations for `computeNonGreatPowerAutoOffers` scenario rows.
class NonGpAutoOffersExpectation {
  const NonGpAutoOffersExpectation({this.empty = false, this.factionKeys, this.factionKeysUnordered, this.offersByFaction, this.purchasedTileFrrAttribution, this.custom});
  final bool empty;
  final Set<String>? factionKeys;
  final Iterable<String>? factionKeysUnordered;
  final Map<String, FactionAutoOffersExpectation>? offersByFaction;
  final PurchasedTileFrrAttributionExpectation? purchasedTileFrrAttribution;
  final void Function(Map<String, List<TradeOrder>> result)? custom;
}
/// Compact `m1` offer-list pin (Refs #3939 slice 62).
NonGpAutoOffersExpectation nonGpM1OffersExpect({int? length, List<CommodityId>? commodityIds, List<String>? originTileKeys, CommodityId? singleCommodityId, String? singleOriginTileKey, bool standardPriorityOneOffers = false, CommodityId? excludeCommodity, Set<String>? factionKeys = const {'m1'}}) => NonGpAutoOffersExpectation(
  factionKeys: factionKeys,
  offersByFaction: {'m1': FactionAutoOffersExpectation(length: length, commodityIds: commodityIds, originTileKeys: originTileKeys, singleCommodityId: singleCommodityId, singleOriginTileKey: singleOriginTileKey, standardPriorityOneOffers: standardPriorityOneOffers, excludeCommodity: excludeCommodity)},
);
/// Dual-faction offer pins (Refs #3939 slice 62).
NonGpAutoOffersExpectation nonGpDualFactionOffersExpect({required FactionAutoOffersExpectation m1, required FactionAutoOffersExpectation t1, Iterable<String>? factionKeysUnordered = const ['m1', 't1']}) => NonGpAutoOffersExpectation(factionKeysUnordered: factionKeysUnordered, offersByFaction: {'m1': m1, 't1': t1});
void _assertStandardPriorityOneOffer(TradeOrder order) {
  expect(order.type, equals(TradeOrderType.offer));
  expect(order.priority, equals(1));
  expect(order.quantity, equals(1));
  expect(order.originTileKey, isNotNull);
  expect(order.isFtp, isFalse);
}
void _assertFactionAutoOffersExpectation(List<TradeOrder>? orders, FactionAutoOffersExpectation factionExpectation) {
  if (factionExpectation.length != null) {
    expect(orders, hasLength(factionExpectation.length));
  }
  if (factionExpectation.standardPriorityOneOffers) {
    for (final order in orders!) {
      _assertStandardPriorityOneOffer(order);
    }
  }
  if (factionExpectation.commodityIds != null) {
    expect(orders!.map((o) => o.commodityId).toList(), equals(factionExpectation.commodityIds));
  }
  if (factionExpectation.originTileKeys != null) {
    expect(orders!.map((o) => o.originTileKey).toList(), equals(factionExpectation.originTileKeys));
  }
  if (factionExpectation.singleCommodityId != null) {
    expect(orders!.first.commodityId, equals(factionExpectation.singleCommodityId));
  }
  if (factionExpectation.singleOriginTileKey != null) {
    expect(orders!.first.originTileKey, equals(factionExpectation.singleOriginTileKey));
  }
  if (factionExpectation.excludeCommodity != null) {
    for (final order in orders!) {
      expect(order.commodityId, isNot(equals(factionExpectation.excludeCommodity)));
    }
  }
}
void assertNonGpAutoOffersExpectation(Map<String, List<TradeOrder>> result, NonGpAutoOffersExpectation expectation, {Game? game}) {
  if (expectation.empty) {
    expect(result, isEmpty);
  }
  if (expectation.factionKeys != null) {
    expect(result.keys, equals(expectation.factionKeys));
  }
  if (expectation.factionKeysUnordered != null) {
    expect(result.keys, unorderedEquals(expectation.factionKeysUnordered!.toList()));
  }
  if (expectation.offersByFaction != null) {
    for (final entry in expectation.offersByFaction!.entries) {
      _assertFactionAutoOffersExpectation(result[entry.key], entry.value);
    }
  }
  if (expectation.purchasedTileFrrAttribution != null) {
    final pin = expectation.purchasedTileFrrAttribution!;
    expect(game, isNotNull, reason: 'game required for FRR index attribution');
    final index = PurchasedTileIndex.fromGame(game!);
    final order = result[pin.factionId]!.single;
    expect(order.originTileKey, isNotNull);
    final attribution = index.attributionForTileKey(order.originTileKey!);
    expect(attribution, isNotNull);
    expect(attribution!.owningGpId, equals(pin.owningGpId));
    expect(attribution.sourceFactionId, equals(pin.sourceFactionId));
  }
  expectation.custom?.call(result);
}
// dart format on
