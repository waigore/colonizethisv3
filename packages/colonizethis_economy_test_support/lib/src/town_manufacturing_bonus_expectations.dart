// Compact town manufacturing bonus assertions (Refs #3939 phase 3 slice 16).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Data-driven expectations for province-level town manufacturing bonus rows.
class TownManufacturingBonusProvinceExpectation {
  const TownManufacturingBonusProvinceExpectation({
    this.isEmpty = false,
    this.commodityAmounts = const {},
    this.absentCommodities = const [],
    this.techGated,
  });

  final bool isEmpty;
  final Map<CommodityId, int> commodityAmounts;
  final List<CommodityId> absentCommodities;

  /// When set, re-runs [computeTownManufacturingBonusForProvince] with [techUnlocked]
  /// and asserts [withTechCommodityAmounts] / [withTechAbsentCommodities].
  final ({
    Map<String, bool> techUnlocked,
    Map<CommodityId, int> withTechCommodityAmounts,
    List<CommodityId> withTechAbsentCommodities,
    int townDevelopmentLevel,
    Map<CommodityId, int> townConnectedDeliveredRawByCommodity,
  })? techGated;
}

void assertTownManufacturingBonusProvinceExpectation(
  Map<CommodityId, int> bonus,
  TownManufacturingBonusProvinceExpectation expectation,
) {
  if (expectation.isEmpty) {
    expect(bonus, isEmpty);
  }
  for (final commodity in expectation.absentCommodities) {
    expect(bonus[commodity], isNull);
  }
  for (final entry in expectation.commodityAmounts.entries) {
    expect(bonus[entry.key], entry.value);
  }
  final techGated = expectation.techGated;
  if (techGated != null) {
    final withTech = computeTownManufacturingBonusForProvince(
      townDevelopmentLevel: techGated.townDevelopmentLevel,
      townConnectedDeliveredRawByCommodity:
          techGated.townConnectedDeliveredRawByCommodity,
      techUnlocked: techGated.techUnlocked,
    );
    for (final commodity in techGated.withTechAbsentCommodities) {
      expect(withTech[commodity], isNull);
    }
    for (final entry in techGated.withTechCommodityAmounts.entries) {
      expect(withTech[entry.key], entry.value);
    }
  }
}

/// One auto-offer row expectation for [townManufacturingBonusToAutoOffers].
class TownManufacturingAutoOfferExpectation {
  const TownManufacturingAutoOfferExpectation({
    required this.commodityId,
    required this.type,
    required this.priority,
    required this.quantity,
  });

  final CommodityId commodityId;
  final TradeOrderType type;
  final int priority;
  final int quantity;
}

/// Data-driven expectations for game-level town manufacturing bonus rows.
class TownManufacturingBonusGameExpectation {
  const TownManufacturingBonusGameExpectation({
    this.factionBonus,
    this.deliveredRawGreaterThanZero,
    this.autoOffers,
    this.previewMatchesLive = false,
    this.previewEmpty = false,
    this.custom,
  });

  final Map<String, Map<CommodityId, int>>? factionBonus;
  final Map<String, CommodityId>? deliveredRawGreaterThanZero;
  final Map<String, TownManufacturingAutoOfferExpectation>? autoOffers;
  final bool previewMatchesLive;
  final bool previewEmpty;
  final void Function()? custom;
}

void assertTownManufacturingBonusGameExpectation({
  required TownManufacturingBonusGameExpectation expectation,
  Map<String, Map<CommodityId, int>>? bonusByFactionId,
  Map<String, Map<CommodityId, int>>? bonusByProvinceId,
  Map<String, Map<CommodityId, int>>? deliveredRawByProvince,
  Map<String, List<TradeOrder>>? autoOffers,
  Map<String, Map<CommodityId, int>>? previewByProvince,
}) {
  if (expectation.factionBonus != null) {
    for (final entry in expectation.factionBonus!.entries) {
      for (final commodityEntry in entry.value.entries) {
        expect(
          bonusByFactionId![entry.key]?[commodityEntry.key],
          commodityEntry.value,
        );
      }
    }
  }
  if (expectation.deliveredRawGreaterThanZero != null) {
    for (final entry in expectation.deliveredRawGreaterThanZero!.entries) {
      expect(
        deliveredRawByProvince![entry.key]?[entry.value],
        greaterThan(0),
      );
    }
  }
  if (expectation.autoOffers != null) {
    expect(autoOffers!.keys, equals(expectation.autoOffers!.keys.toList()));
    for (final entry in expectation.autoOffers!.entries) {
      final offer = autoOffers[entry.key]!.single;
      expect(offer.commodityId, entry.value.commodityId);
      expect(offer.type, entry.value.type);
      expect(offer.priority, entry.value.priority);
      expect(offer.quantity, entry.value.quantity);
    }
  }
  if (expectation.previewMatchesLive) {
    expect(previewByProvince, bonusByProvinceId);
  }
  if (expectation.previewEmpty) {
    expect(previewByProvince, isEmpty);
  }
  expectation.custom?.call();
}
