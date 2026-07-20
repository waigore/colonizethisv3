// Rollup types and helpers for `seed42_observer_world_market_diagnostic_test.dart`
// (Refs #2924). Keeps the diagnostic host focused on harness callbacks.

import 'package:colonizethis_ai/colonizethis_ai.dart';

/// Great Power factionIds the diagnostic scopes to (`gp1..gp6`). Mirrors
/// `kColonialPhaseEntryGreatPowerIds` in
/// `seed42_observer_colonial_phase_entry_budget_test.dart` and the
/// `gpIds` list in `seed42_observer_conquest_s7d_diagnostic_test.dart`
/// so the three seed-42 100-turn observer-tied surfaces agree on the
/// GP cohort.
const List<String> kSeed42WorldMarketDiagnosticGreatPowerIds = [
  'gp1',
  'gp2',
  'gp3',
  'gp4',
  'gp5',
  'gp6',
];

/// The subset of [kSeed42WorldMarketDiagnosticGreatPowerIds] that fails the
/// seed-42 turn-100 +3 OW gate (gp3, gp4, gp5, gp6 per the issue body's
/// "Current passing/failing state" table and the 2026-06-01 Step-0 baseline).
const Set<String> kSeed42WorldMarketDiagnosticFailingGreatPowerIds = {
  'gp3',
  'gp4',
  'gp5',
  'gp6',
};

/// Number of top commodities surfaced per failing GP in the per-commodity
/// rollup.
const int kSeed42WorldMarketDiagnosticPerCommodityTopN = 5;

/// One per-GP per-turn record. Stored on [Seed42WorldMarketTurnRow] then
/// encoded into the structured JSON output the test prints between
/// `WM2924_DIAGNOSTIC_JSON_BEGIN` / `WM2924_DIAGNOSTIC_JSON_END` markers.
class Seed42WorldMarketTurnRow {
  const Seed42WorldMarketTurnRow({
    required this.turn,
    required this.phase,
    required this.treasuryStart,
    required this.treasuryEnd,
    required this.tradeCargoCapacity,
    required this.bidTypeCap,
    required this.offersEmitted,
    required this.bidsEmitted,
    required this.offerQuantityTotal,
    required this.bidQuantityTotal,
    required this.carryForwardOffersCount,
    required this.carryForwardBidsCount,
    required this.dealsAsSeller,
    required this.treasuryCreditedAsSeller,
    required this.dealsAsBuyer,
    required this.treasurySpentAsBuyer,
  });

  final int turn;
  final ObserverGoalPhase phase;
  final int treasuryStart;
  final int treasuryEnd;
  final int tradeCargoCapacity;
  final int bidTypeCap;
  final int offersEmitted;
  final int bidsEmitted;
  final int offerQuantityTotal;
  final int bidQuantityTotal;
  final int carryForwardOffersCount;
  final int carryForwardBidsCount;
  final int dealsAsSeller;
  final int treasuryCreditedAsSeller;
  final int dealsAsBuyer;
  final int treasurySpentAsBuyer;

  Map<String, Object?> toJson() => <String, Object?>{
        'turn': turn,
        'phase': phase.name,
        'treasuryStart': treasuryStart,
        'treasuryEnd': treasuryEnd,
        'tradeCargoCapacity': tradeCargoCapacity,
        'bidTypeCap': bidTypeCap,
        'offersEmitted': offersEmitted,
        'bidsEmitted': bidsEmitted,
        'offerQuantityTotal': offerQuantityTotal,
        'bidQuantityTotal': bidQuantityTotal,
        'carryForwardOffersCount': carryForwardOffersCount,
        'carryForwardBidsCount': carryForwardBidsCount,
        'dealsAsSeller': dealsAsSeller,
        'treasuryCreditedAsSeller': treasuryCreditedAsSeller,
        'dealsAsBuyer': dealsAsBuyer,
        'treasurySpentAsBuyer': treasurySpentAsBuyer,
      };
}

/// Aggregate the per-turn rows for a single Great Power into a flat rollup
/// the JSON consumer can read without iterating every per-turn entry.
Map<String, Object?> buildSeed42WorldMarketGpRollup({
  required List<Seed42WorldMarketTurnRow> rows,
  required Map<String, int> offerQuantityByCommodity,
  required Map<String, int> sellerDealQuantityByCommodity,
  required int cheapestRegimentBuildTreasuryCost,
}) {
  var cumulativeOffersEmitted = 0;
  var cumulativeBidsEmitted = 0;
  var cumulativeOfferQuantity = 0;
  var cumulativeBidQuantity = 0;
  var cumulativeDealsAsSeller = 0;
  var cumulativeTreasuryCreditedAsSeller = 0;
  var cumulativeDealsAsBuyer = 0;
  var cumulativeTreasurySpentAsBuyer = 0;
  var turnsZeroTradeCargo = 0;
  var turnsZeroBidTypeCap = 0;
  var turnsTreasuryUnderCheapestRegiment = 0;
  int? firstTurnTreasuryCrossesCheapest;

  for (final r in rows) {
    cumulativeOffersEmitted += r.offersEmitted;
    cumulativeBidsEmitted += r.bidsEmitted;
    cumulativeOfferQuantity += r.offerQuantityTotal;
    cumulativeBidQuantity += r.bidQuantityTotal;
    cumulativeDealsAsSeller += r.dealsAsSeller;
    cumulativeTreasuryCreditedAsSeller += r.treasuryCreditedAsSeller;
    cumulativeDealsAsBuyer += r.dealsAsBuyer;
    cumulativeTreasurySpentAsBuyer += r.treasurySpentAsBuyer;
    if (r.tradeCargoCapacity <= 0) turnsZeroTradeCargo += 1;
    if (r.bidTypeCap <= 0) turnsZeroBidTypeCap += 1;
    if (r.treasuryEnd < cheapestRegimentBuildTreasuryCost) {
      turnsTreasuryUnderCheapestRegiment += 1;
    }
    if (firstTurnTreasuryCrossesCheapest == null &&
        r.treasuryEnd >= cheapestRegimentBuildTreasuryCost) {
      firstTurnTreasuryCrossesCheapest = r.turn + 1;
    }
  }

  return <String, Object?>{
    'cumulativeOffersEmitted': cumulativeOffersEmitted,
    'cumulativeBidsEmitted': cumulativeBidsEmitted,
    'cumulativeOfferQuantity': cumulativeOfferQuantity,
    'cumulativeBidQuantity': cumulativeBidQuantity,
    'cumulativeDealsAsSeller': cumulativeDealsAsSeller,
    'cumulativeTreasuryCreditedAsSeller': cumulativeTreasuryCreditedAsSeller,
    'cumulativeDealsAsBuyer': cumulativeDealsAsBuyer,
    'cumulativeTreasurySpentAsBuyer': cumulativeTreasurySpentAsBuyer,
    'turnsZeroTradeCargo': turnsZeroTradeCargo,
    'turnsZeroBidTypeCap': turnsZeroBidTypeCap,
    'turnsTreasuryUnderCheapestRegiment': turnsTreasuryUnderCheapestRegiment,
    'firstTurnTreasuryCrossesCheapest': firstTurnTreasuryCrossesCheapest,
    'topOfferCommodities': seed42WorldMarketTopNByQuantity(
      offerQuantityByCommodity,
      kSeed42WorldMarketDiagnosticPerCommodityTopN,
    ),
    'topSellerDealCommodities': seed42WorldMarketTopNByQuantity(
      sellerDealQuantityByCommodity,
      kSeed42WorldMarketDiagnosticPerCommodityTopN,
    ),
  };
}

/// Deterministic top-N projection of `quantitiesByCommodity` sorted by
/// descending quantity then ascending commodity id.
List<Map<String, Object?>> seed42WorldMarketTopNByQuantity(
  Map<String, int> quantitiesByCommodity,
  int n,
) {
  final entries = quantitiesByCommodity.entries
      .where((e) => e.value > 0)
      .toList(growable: false)
    ..sort((a, b) {
      final byQty = b.value.compareTo(a.value);
      if (byQty != 0) return byQty;
      return a.key.compareTo(b.key);
    });
  final limit = entries.length < n ? entries.length : n;
  return [
    for (var i = 0; i < limit; i++)
      <String, Object?>{
        'commodityId': entries[i].key,
        'quantity': entries[i].value,
      },
  ];
}

/// Per-turn pre-resolve state stashed between harness callbacks.
class Seed42PendingWorldMarketTurn {
  const Seed42PendingWorldMarketTurn({
    required this.preTurnSnapshot,
    required this.emittedThisTurn,
  });

  final Map<String,
      ({
        int treasuryStart,
        int cargo,
        int bidTypeCap,
        int cfOffers,
        int cfBids,
        ObserverGoalPhase phase,
      })> preTurnSnapshot;
  final Map<String, ({int offers, int bids, int offerQty, int bidQty})>
      emittedThisTurn;
}
