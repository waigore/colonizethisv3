// Compact non-GP auto-offer result assertions (Refs #3939 phase 3 slice 12).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

/// Per-faction offer list pins for [NonGpAutoOffersExpectation].
class FactionAutoOffersExpectation {
  const FactionAutoOffersExpectation({
    this.length,
    this.commodityIds,
    this.originTileKeys,
    this.singleCommodityId,
    this.singleOriginTileKey,
    this.standardPriorityOneOffers = false,
    this.excludeCommodity,
  });

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
  const NonGpAutoOffersExpectation({
    this.empty = false,
    this.factionKeys,
    this.factionKeysUnordered,
    this.offersByFaction,
    this.custom,
  });

  final bool empty;
  final Set<String>? factionKeys;
  final Iterable<String>? factionKeysUnordered;
  final Map<String, FactionAutoOffersExpectation>? offersByFaction;
  final void Function(Map<String, List<TradeOrder>> result)? custom;
}

void _assertStandardPriorityOneOffer(TradeOrder order) {
  expect(order.type, equals(TradeOrderType.offer));
  expect(order.priority, equals(1));
  expect(order.quantity, equals(1));
  expect(order.originTileKey, isNotNull);
  expect(order.isFtp, isFalse);
}

void assertNonGpAutoOffersExpectation(
  Map<String, List<TradeOrder>> result,
  NonGpAutoOffersExpectation expectation,
) {
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
      final orders = result[entry.key];
      final factionExpectation = entry.value;
      if (factionExpectation.length != null) {
        expect(orders, hasLength(factionExpectation.length));
      }
      if (factionExpectation.standardPriorityOneOffers) {
        for (final order in orders!) {
          _assertStandardPriorityOneOffer(order);
        }
      }
      if (factionExpectation.commodityIds != null) {
        expect(
          orders!.map((o) => o.commodityId).toList(),
          equals(factionExpectation.commodityIds),
        );
      }
      if (factionExpectation.originTileKeys != null) {
        expect(
          orders!.map((o) => o.originTileKey).toList(),
          equals(factionExpectation.originTileKeys),
        );
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
  }
  expectation.custom?.call(result);
}
