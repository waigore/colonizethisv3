// dart format off
// Table-driven town manufacturing bonus scenarios (Refs #3939 phase 3, #4410).
import 'package:colonizethis_data/colonizethis_data.dart';
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
/// One row in [townManufacturingBonusProvinceScenarios].
typedef TownManufacturingBonusProvinceScenario = ({String label, int townDevelopmentLevel, Map<CommodityId, int> townConnectedDeliveredRawByCommodity, Map<String, bool>? techUnlocked, void Function(Map<CommodityId, int> bonus) verify, String? refs});
/// Compact province-bonus row (Refs #3939 slice 47 / 57).
TownManufacturingBonusProvinceScenario townBonusProvinceRow({required String label, required int townDevelopmentLevel, required Map<CommodityId, int> townConnectedDeliveredRawByCommodity, required TownManufacturingBonusProvinceExpectation expect, Map<String, bool> techUnlocked = const {}, String? refs = '#3872'}) => (label: label, townDevelopmentLevel: townDevelopmentLevel, townConnectedDeliveredRawByCommodity: townConnectedDeliveredRawByCommodity, techUnlocked: techUnlocked, refs: refs, verify: (bonus) => assertTownManufacturingBonusProvinceExpectation(bonus, expect, townDevelopmentLevel: townDevelopmentLevel, townConnectedDeliveredRawByCommodity: townConnectedDeliveredRawByCommodity));
/// Canonical scenarios for [computeTownManufacturingBonusForProvince].
List<TownManufacturingBonusProvinceScenario> townManufacturingBonusProvinceScenarios() => [
  townBonusProvinceRow(
    label: 'floor(7/4)*1 = 1 lumber at level 2',
    townDevelopmentLevel: 2,
    townConnectedDeliveredRawByCommodity: {'timber': 7},
    expect: TownManufacturingBonusProvinceExpectation(commodityAmounts: {'lumber': 1}),
  ),
  townBonusProvinceRow(
    label: 'level 4 with 4 timber → 2 lumber (replacement multiplier)',
    townDevelopmentLevel: 4,
    townConnectedDeliveredRawByCommodity: {'timber': 4},
    expect: TownManufacturingBonusProvinceExpectation(commodityAmounts: {'lumber': 2}),
  ),
  townBonusProvinceRow(label: 'level 3 grants zero bonus', townDevelopmentLevel: 3, townConnectedDeliveredRawByCommodity: {'timber': 8}, expect: const TownManufacturingBonusProvinceExpectation(isEmpty: true)),
  townBonusProvinceRow(
    label: 'bronze limiting input min(8,2)=2 → floor(2/4)=0',
    townDevelopmentLevel: 2,
    townConnectedDeliveredRawByCommodity: {'copper': 8, 'tin': 2},
    expect: TownManufacturingBonusProvinceExpectation(absentCommodities: ['bronze']),
  ),
  townBonusProvinceRow(
    label: 'cotton fabric requires cotton_weaving tech',
    townDevelopmentLevel: 2,
    townConnectedDeliveredRawByCommodity: {'cotton': 8},
    expect: TownManufacturingBonusProvinceExpectation(absentCommodities: ['fabric'], techGated: (techUnlocked: {kTechIdCottonWeaving: true}, withTechCommodityAmounts: {'fabric': 2}, withTechAbsentCommodities: <CommodityId>[])),
  ),
];
void runTownManufacturingBonusProvinceScenario(TownManufacturingBonusProvinceScenario scenario) {
  final bonus = computeTownManufacturingBonusForProvince(townDevelopmentLevel: scenario.townDevelopmentLevel, townConnectedDeliveredRawByCommodity: scenario.townConnectedDeliveredRawByCommodity, techUnlocked: scenario.techUnlocked);
  scenario.verify(bonus);
}
/// Fixture-backed game-level scenario pins (Refs #3939 phase 3 slice 32).
enum TownManufacturingBonusGamePin { gpTownTimberBonus, minorDeliveredRaw, autoOffersMinor, previewMatchesLive, previewEmpty }
/// One row in [townManufacturingBonusGameScenarios] (Refs #3939 slice 63).
typedef TownManufacturingBonusGameScenario = ({String label, TownManufacturingBonusGamePin pin, TownManufacturingBonusGameExpectation expect, String? refs});
const _ow = 'oldWorld';
const _gpProvinceId = '$_ow|p1';
/// Canonical fixture-backed scenarios for game-level town manufacturing bonus.
List<TownManufacturingBonusGameScenario> townManufacturingBonusGameScenarios() => [
  (
    label: 'GP town-connected timber yields lumber bonus in bonusByFactionId',
    pin: TownManufacturingBonusGamePin.gpTownTimberBonus,
    expect: TownManufacturingBonusGameExpectation(
      factionBonus: {
        'pl1': {'lumber': 2},
      },
      deliveredRawGreaterThanZero: {_gpProvinceId: 'timber'},
    ),
    refs: '#3872',
  ),
  (label: 'minor town-connected timber accumulates delivered raw extraction', pin: TownManufacturingBonusGamePin.minorDeliveredRaw, expect: TownManufacturingBonusGameExpectation(deliveredRawGreaterThanZero: {'oldWorld|m1': 'timber'}), refs: '#3872'),
  (
    label: 'townManufacturingBonusToAutoOffers emits priority-1 offers for minors',
    pin: TownManufacturingBonusGamePin.autoOffersMinor,
    expect: TownManufacturingBonusGameExpectation(
      autoOffers: {'m1': TownManufacturingAutoOfferExpectation(commodityId: 'lumber', type: TradeOrderType.offer, priority: 1, quantity: 2)},
    ),
    refs: '#3872',
  ),
  (label: 'previewTownManufacturingBonusByProvince matches live bonusByProvinceId when connectivity resolves', pin: TownManufacturingBonusGamePin.previewMatchesLive, expect: TownManufacturingBonusGameExpectation(previewMatchesLive: true, previewProvinceMatchesFactionCommodity: (provinceId: _gpProvinceId, factionId: 'pl1', commodityId: 'lumber')), refs: '#3872'),
  (label: 'previewTownManufacturingBonusByProvince returns empty without tile maps', pin: TownManufacturingBonusGamePin.previewEmpty, expect: const TownManufacturingBonusGameExpectation(previewEmpty: true), refs: '#3872'),
];
// dart format on
