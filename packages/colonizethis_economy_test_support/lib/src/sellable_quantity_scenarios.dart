// Table-driven sellable / offer-cap scenarios (Refs #3856).

import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';

import 'treasury_bid_budget_test_support.dart';

/// One row in [offerCapByCommodityIdScenarios].
typedef OfferCapByCommodityIdScenario = ({
  String label,
  Map<CommodityId, int> stockpile,
  String playerId,
  void Function(Map<CommodityId, int> cap) verify,
  String? refs,
});

/// Canonical scenarios for [offerCapByCommodityId].
List<OfferCapByCommodityIdScenario> offerCapByCommodityIdScenarios() => [
  (
    label: 'returns empty map for unknown player',
    stockpile: {'timber': 10},
    playerId: 'gp_ghost',
    verify: _verifyOfferCapEmpty,
    refs: '#3093',
  ),
  (
    label: 'returns each non-riches stockpile quantity as the offer cap',
    stockpile: {'timber': 10, 'iron': 7, 'fabric': 3},
    playerId: humanPlayerId,
    verify: _verifyOfferCapMultiCommodity,
    refs: '#3093',
  ),
  (
    label: 'excludes riches commodities (gold, silver, gems, diamonds, spices)',
    stockpile: {
      'timber': 10,
      'gold': 5,
      'silver': 4,
      'gems': 3,
      'diamonds': 2,
      'spices': 1,
    },
    playerId: humanPlayerId,
    verify: _verifyOfferCapExcludesRiches,
    refs: '#3093',
  ),
  (
    label: 'skips commodities with non-positive stockpile',
    stockpile: {'timber': 10},
    playerId: humanPlayerId,
    verify: _verifyOfferCapSkipsNonPositive,
    refs: '#3093',
  ),
];

void _verifyOfferCapEmpty(Map<CommodityId, int> cap) {
  expect(cap, isEmpty);
}

void _verifyOfferCapMultiCommodity(Map<CommodityId, int> cap) {
  expect(cap['timber'], 10);
  expect(cap['iron'], 7);
  expect(cap['fabric'], 3);
  expect(cap.length, 3);
}

void _verifyOfferCapExcludesRiches(Map<CommodityId, int> cap) {
  expect(cap['timber'], 10);
  expect(cap.containsKey('gold'), isFalse);
  expect(cap.containsKey('silver'), isFalse);
  expect(cap.containsKey('gems'), isFalse);
  expect(cap.containsKey('diamonds'), isFalse);
  expect(cap.containsKey('spices'), isFalse);
}

void _verifyOfferCapSkipsNonPositive(Map<CommodityId, int> cap) {
  expect(cap['iron'], isNull);
}

/// One row in [stagedOfferQuantitiesByCommodityIdScenarios].
typedef StagedOfferQuantitiesScenario = ({
  String label,
  List<TradeOrder> orders,
  void Function(Map<CommodityId, int> staged) verify,
  String? refs,
});

/// Canonical scenarios for [stagedOfferQuantitiesByCommodityId].
List<StagedOfferQuantitiesScenario> stagedOfferQuantitiesByCommodityIdScenarios() {
  return [
    (
      label: 'returns empty map when no trade orders are staged',
      orders: const <TradeOrder>[],
      verify: _verifyStagedOffersEmpty,
      refs: '#3093',
    ),
    (
      label: 'sums quantities per commodity for offer-typed orders',
      orders: [
        offerOrder('timber', 5),
        offerOrder('iron', 3),
      ],
      verify: _verifyStagedOffersSum,
      refs: '#3093',
    ),
    (
      label: 'excludes bid-typed orders',
      orders: [
        bidOrder('timber', 4),
        offerOrder('iron', 3),
      ],
      verify: _verifyStagedOffersExcludeBids,
      refs: '#3093',
    ),
    (
      label: 'excludes non-positive quantities',
      orders: [
        offerOrder('timber', 0),
      ],
      verify: _verifyStagedOffersExcludeNonPositive,
      refs: '#3093',
    ),
  ];
}

void _verifyStagedOffersEmpty(Map<CommodityId, int> staged) {
  expect(staged, isEmpty);
}

void _verifyStagedOffersSum(Map<CommodityId, int> staged) {
  expect(staged['timber'], 5);
  expect(staged['iron'], 3);
}

void _verifyStagedOffersExcludeBids(Map<CommodityId, int> staged) {
  expect(staged.containsKey('timber'), isFalse);
  expect(staged['iron'], 3);
}

void _verifyStagedOffersExcludeNonPositive(Map<CommodityId, int> staged) {
  expect(staged.containsKey('timber'), isFalse);
}

/// One row in [sellableHeadroomByCommodityIdScenarios].
typedef SellableHeadroomScenario = ({
  String label,
  Map<CommodityId, int> stockpile,
  List<TradeOrder> orders,
  Map<CommodityId, int>? productionInputConsumptionByCommodityId,
  bool useEmptyProductionMap,
  void Function(Map<CommodityId, int> sellable) verify,
  String? refs,
});

/// Canonical scenarios for [sellableHeadroomByCommodityId].
List<SellableHeadroomScenario> sellableHeadroomByCommodityIdScenarios() {
  return [
    (
      label: 'returns the offer cap when no offers are staged',
      stockpile: {'timber': 10, 'iron': 7},
      orders: const <TradeOrder>[],
      productionInputConsumptionByCommodityId: null,
      useEmptyProductionMap: false,
      verify: _verifySellableHeadroomNoStagedOffers,
      refs: '#3093',
    ),
    (
      label: 'subtracts staged offer quantity from the cap to produce the '
          '`(N)` display headroom (default: industry allocation = 0)',
      stockpile: {'timber': 10},
      orders: [offerOrder('timber', 2)],
      productionInputConsumptionByCommodityId: null,
      useEmptyProductionMap: false,
      verify: _verifySellableHeadroomSubtractsStaged,
      refs: '#3093',
    ),
    (
      label: 'industry-allocation reservation: stockpile 10 timber, '
          'production consumes 3 timber, staged offer 2 → sellable 5 '
          '(canonical AC for Refs #3093 sellable definition)',
      stockpile: {'timber': 10},
      orders: [offerOrder('timber', 2)],
      productionInputConsumptionByCommodityId: {'timber': 3},
      useEmptyProductionMap: false,
      verify: _verifySellableHeadroomIndustryReservation,
      refs: '#3093',
    ),
    (
      label: 'industry-allocation reservation: when consumption equals '
          'stockpile, cap is 0 → key omitted (Offer chip disabled)',
      stockpile: {'timber': 10},
      orders: const <TradeOrder>[],
      productionInputConsumptionByCommodityId: {'timber': 10},
      useEmptyProductionMap: false,
      verify: _verifySellableHeadroomFullReservation,
      refs: '#3093',
    ),
    (
      label: 'industry-allocation reservation: negative consumption entries '
          'are clamped at 0 (defensive — caller cannot inflate the cap)',
      stockpile: {'timber': 10},
      orders: const <TradeOrder>[],
      productionInputConsumptionByCommodityId: {'timber': -100},
      useEmptyProductionMap: false,
      verify: _verifySellableHeadroomNegativeConsumptionClamped,
      refs: '#3093',
    ),
    (
      label: 'industry-allocation reservation: empty map matches null '
          '(both fall back to raw stockpile)',
      stockpile: {'timber': 10},
      orders: const <TradeOrder>[],
      productionInputConsumptionByCommodityId: null,
      useEmptyProductionMap: true,
      verify: _verifySellableHeadroomEmptyMapMatchesNull,
      refs: '#3093',
    ),
    (
      label: 'industry-allocation reservation: consumption on one commodity '
          'does not affect another commodity\'s cap',
      stockpile: {'timber': 10, 'iron': 7},
      orders: const <TradeOrder>[],
      productionInputConsumptionByCommodityId: {'timber': 4},
      useEmptyProductionMap: false,
      verify: _verifySellableHeadroomIsolatedCommodities,
      refs: '#3093',
    ),
    (
      label: 'clamps headroom at 0 (drops the commodity) when staged offer '
          'reaches or exceeds the cap',
      stockpile: {'timber': 5},
      orders: [offerOrder('timber', 5)],
      productionInputConsumptionByCommodityId: null,
      useEmptyProductionMap: false,
      verify: _verifySellableHeadroomClampsAtZero,
      refs: '#3093',
    ),
    (
      label: 'bids do not consume the offer headroom',
      stockpile: {'timber': 10},
      orders: [bidOrder('timber', 4)],
      productionInputConsumptionByCommodityId: null,
      useEmptyProductionMap: false,
      verify: _verifySellableHeadroomBidsIgnored,
      refs: '#3093',
    ),
    (
      label: 'riches commodities are excluded even when staged offers exist',
      stockpile: {'timber': 10, 'gold': 4},
      orders: [offerOrder('gold', 2)],
      productionInputConsumptionByCommodityId: null,
      useEmptyProductionMap: false,
      verify: _verifySellableHeadroomExcludesRiches,
      refs: '#3093',
    ),
  ];
}

void _verifySellableHeadroomNoStagedOffers(Map<CommodityId, int> sellable) {
  expect(sellable['timber'], 10);
  expect(sellable['iron'], 7);
}

void _verifySellableHeadroomSubtractsStaged(Map<CommodityId, int> sellable) {
  expect(sellable['timber'], 8);
}

void _verifySellableHeadroomIndustryReservation(Map<CommodityId, int> sellable) {
  expect(
    sellable['timber'],
    5,
    reason:
        'Canonical AC: max(0, 10 - 3) - 2 = 5. Offer chip / `+` '
        'stepper must clamp at this sellable headroom.',
  );
}

void _verifySellableHeadroomFullReservation(Map<CommodityId, int> sellable) {
  expect(
    sellable.containsKey('timber'),
    isFalse,
    reason: 'Full reservation collapses the cap to 0 → key dropped.',
  );
}

void _verifySellableHeadroomNegativeConsumptionClamped(
  Map<CommodityId, int> sellable,
) {
  expect(
    sellable['timber'],
    10,
    reason:
        'Negative consumption must not raise sellable above '
        'raw stockpile.',
  );
}

void _verifySellableHeadroomEmptyMapMatchesNull(Map<CommodityId, int> sellable) {
  expect(sellable['timber'], 10);
}

void _verifySellableHeadroomIsolatedCommodities(Map<CommodityId, int> sellable) {
  expect(sellable['timber'], 6);
  expect(
    sellable['iron'],
    7,
    reason: 'Iron has no reservation entry → raw stockpile.',
  );
}

void _verifySellableHeadroomClampsAtZero(Map<CommodityId, int> sellable) {
  expect(
    sellable.containsKey('timber'),
    isFalse,
    reason:
        'Cap=5 minus staged offer 5 = 0; missing key means `(0)` so '
        'the Trade Market tab shows no `(N)` and disables the Offer '
        'chip / `+` button.',
  );
}

void _verifySellableHeadroomBidsIgnored(Map<CommodityId, int> sellable) {
  expect(sellable['timber'], 10);
}

void _verifySellableHeadroomExcludesRiches(Map<CommodityId, int> sellable) {
  expect(sellable.containsKey('gold'), isFalse);
  expect(sellable['timber'], 10);
}

/// Runs [sellableHeadroomByCommodityId] for one [SellableHeadroomScenario].
Map<CommodityId, int> runSellableHeadroomScenario(SellableHeadroomScenario scenario) {
  final game = buildStockpilePlayerGame(stockpile: scenario.stockpile);
  final orders = humanOrdersWith(scenario.orders);
  if (scenario.useEmptyProductionMap) {
    final viaNull = sellableHeadroomByCommodityId(
      game: game,
      playerId: humanPlayerId,
      orders: orders,
    );
    final viaEmpty = sellableHeadroomByCommodityId(
      game: game,
      playerId: humanPlayerId,
      orders: orders,
      productionInputConsumptionByCommodityId: const <CommodityId, int>{},
    );
    expect(viaNull['timber'], viaEmpty['timber']);
    return viaEmpty;
  }
  return sellableHeadroomByCommodityId(
    game: game,
    playerId: humanPlayerId,
    orders: orders,
    productionInputConsumptionByCommodityId:
        scenario.productionInputConsumptionByCommodityId,
  );
}
