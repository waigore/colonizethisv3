// dart format off
// Compact town manufacturing bonus assertions (Refs #3939 phase 3 slice 16).
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
/// Data-driven expectations for province-level town manufacturing bonus rows.
class TownManufacturingBonusProvinceExpectation {
  const TownManufacturingBonusProvinceExpectation({this.isEmpty = false, this.commodityAmounts = const {}, this.absentCommodities = const [], this.techGated});
  final bool isEmpty;
  final Map<CommodityId, int> commodityAmounts;
  final List<CommodityId> absentCommodities;
  /// When set, re-runs [computeTownManufacturingBonusForProvince] with
  /// [techUnlocked] using the parent row's level/delivered inputs
  /// (Refs #3939 slice 60).
  final ({Map<String, bool> techUnlocked, Map<CommodityId, int> withTechCommodityAmounts, List<CommodityId> withTechAbsentCommodities})? techGated;
}
void assertTownManufacturingBonusProvinceExpectation(Map<CommodityId, int> bonus, TownManufacturingBonusProvinceExpectation expectation, {int? townDevelopmentLevel, Map<CommodityId, int>? townConnectedDeliveredRawByCommodity}) {
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
    final withTech = computeTownManufacturingBonusForProvince(townDevelopmentLevel: townDevelopmentLevel!, townConnectedDeliveredRawByCommodity: townConnectedDeliveredRawByCommodity!, techUnlocked: techGated.techUnlocked);
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
  const TownManufacturingAutoOfferExpectation({required this.commodityId, required this.type, required this.priority, required this.quantity});
  final CommodityId commodityId;
  final TradeOrderType type;
  final int priority;
  final int quantity;
}
/// Data-driven expectations for game-level town manufacturing bonus rows.
class TownManufacturingBonusGameExpectation {
  const TownManufacturingBonusGameExpectation({this.factionBonus, this.deliveredRawGreaterThanZero, this.autoOffers, this.previewMatchesLive = false, this.previewEmpty = false, this.previewProvinceMatchesFactionCommodity});
  final Map<String, Map<CommodityId, int>>? factionBonus;
  final Map<String, CommodityId>? deliveredRawGreaterThanZero;
  final Map<String, TownManufacturingAutoOfferExpectation>? autoOffers;
  final bool previewMatchesLive;
  final bool previewEmpty;
  final ({String provinceId, String factionId, CommodityId commodityId})? previewProvinceMatchesFactionCommodity;
}
void assertTownManufacturingBonusGameExpectation({required TownManufacturingBonusGameExpectation expectation, Map<String, Map<CommodityId, int>>? bonusByFactionId, Map<String, Map<CommodityId, int>>? bonusByProvinceId, Map<String, Map<CommodityId, int>>? deliveredRawByProvince, Map<String, List<TradeOrder>>? autoOffers, Map<String, Map<CommodityId, int>>? previewByProvince}) {
  if (expectation.factionBonus != null) {
    for (final entry in expectation.factionBonus!.entries) {
      for (final commodityEntry in entry.value.entries) {
        expect(bonusByFactionId![entry.key]?[commodityEntry.key], commodityEntry.value);
      }
    }
  }
  if (expectation.deliveredRawGreaterThanZero != null) {
    for (final entry in expectation.deliveredRawGreaterThanZero!.entries) {
      expect(deliveredRawByProvince![entry.key]?[entry.value], greaterThan(0));
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
  final previewPin = expectation.previewProvinceMatchesFactionCommodity;
  if (previewPin != null) {
    expect(previewByProvince![previewPin.provinceId]?[previewPin.commodityId], bonusByFactionId![previewPin.factionId]?[previewPin.commodityId]);
  }
}
// dart format on
