// Seed-42 100-turn per-turn World-Market lock-recovery diagnostic
// (Refs #2924, SPEC/ai/treasury-planner.md
// § "Seed-42 100-turn per-turn World-Market lock-recovery diagnostic").
//
// #2924 (EXPAND geographic peer-war lock at `treasury == 0`) needs a
// per-link decomposition of the lock-recovery chain
// (`StrategicGoal.trade` floor F6 -> `runTreasuryPlanner` surplus / offers
// F1-F5/F8 -> `world_market_phase` matching -> treasury credited per
// `FilledDeal`) on seed 42 so the failing lever can be isolated before
// any Path F tuning code lands. The Step-0 baseline posted on #2924
// (2026-06-01) only captures the headline gate metrics
// (`gpOwGain`, `gpTreasuryUnderCheapestRegimentTurns`, turn-99 treasury)
// reused from the existing `seed42_observer_conquest_s7d_diagnostic_test.dart`
// S7-D rollup; it does not say whether gp3-gp6 emit zero offers
// (no surplus / no cargo) or emit offers that never match (no liquidity)
// or match offers that never raise treasury above the threshold (mis-tuned
// urgency / undersized credit per deal).
//
// This test runs the same 100-turn `generateOrdersForGameFullAI` +
// `validateOrdersAndResolveTurnFromTrustedOrders` loop as
// `seed42_observer_conquest_s7d_diagnostic_test.dart` (Refs #2847 S7-D)
// and records, **per Great Power per turn**, every link of the chain:
//
//   * Treasury at start and end of turn (delta attributable to filled
//     deals as seller / buyer that turn).
//   * Trade-cargo capacity (`cargoHoldsForHomeFleet`) and bid-type cap
//     (`worldMarketBidTypeCap`) -- the two suggester preconditions for
//     emitting offers and bids respectively.
//   * Trade orders emitted that turn from
//     `fullAi.orders.tradeOrdersByPlayerId[gpId]` (bid count, offer
//     count, total quantity).
//   * Carry-forward residuals at the start of the turn from
//     `game.worldMarketState.carryForwardOffersByFactionId[gpId]` /
//     `carryForwardBidsByFactionId[gpId]`.
//   * Filled deals from the resolved turn's
//     `game.worldMarketState.lastTurnActivity` -- counts and treasury
//     credited (`quantity * pricePerUnit`) attributed to `gpId` as seller,
//     and attributed to `gpId` as buyer.
//
// Aggregated per-GP rollups and a per-commodity top-5 rollup for the
// failing GPs (gp3-gp6) round out the trace so an analyst can spot the
// failing link at a glance without re-running the simulation.
//
// Skip semantics + runtime mirror `seed42_observer_conquest_s7d_diagnostic_test.dart`:
// the test is `skip`ped by default (long-running, ~4 min on the project
// reference host) and re-run manually with `dart test --run-skipped` when
// the diagnostic surface shifts after a Path F tuning slice lands. The
// lightweight assertion (per-GP record count equals turn count) mirrors
// the S7-D pattern so a regression that silently drops turns from the
// loop still fails the test without pinning any of the rollup numbers
// that the tuning work is allowed to move.
//
// ## Initial findings (captured 2026-06-01 against `dev` @ `d75d4f42d`)
//
// First run with the world-market phase active produced these per-GP
// 100-turn rollup numbers (treasury units; commodity quantities in
// stockpile units):
//
//   | GP  | offers | offerQty | bids | dealsSell | credSell | dealsBuy | zeroBidCap | turnsUnder |
//   |-----|--------|----------|------|-----------|----------|----------|------------|------------|
//   | gp1 |    100 |    6 256 |    0 |         0 |        0 |        0 |        100 |         98 |
//   | gp2 |    179 |    7 856 |    0 |         0 |        0 |        0 |        100 |         98 |
//   | gp3 |    100 |   15 762 |    0 |         0 |        0 |        0 |        100 |         98 |
//   | gp4 |    100 |   11 106 |    0 |         0 |        0 |        0 |        100 |         98 |
//   | gp5 |    100 |   16 104 |    0 |         0 |        0 |        0 |        100 |         98 |
//   | gp6 |    100 |   39 750 |    0 |         0 |        0 |        0 |        100 |         98 |
//
// Decomposition by chain link:
//
//   * **Goal bias F6** — fires correctly. `firstTurnTreasuryCrossesCheapest=1`
//     for every GP reflects the seeded starting treasury; from turn 2
//     onward treasury collapses below `cheapestRegimentBuildTreasuryCost`
//     (2000) and stays there for 98 / 100 turns per GP. `turnsZeroTradeCargo=0`
//     across the board, so the suggester precondition for offers is met.
//   * **TreasuryPlanner F1–F5 + F8 — offer emission works.** Every GP
//     emits at least one urgent offer every turn (gp2 emits 179 because
//     its starting stockpile holds two surplus commodities at once for
//     parts of the run). The top offer commodity for every failing GP is
//     `grain` (gp3 15 762, gp4 11 106, gp5 16 104, gp6 39 750).
//   * **TreasuryPlanner bid emission does not fire.** `cumulativeBidsEmitted=0`
//     for every GP because `worldMarketBidTypeCap == 0` on every turn
//     (`turnsZeroBidTypeCap=100` per GP). Per
//     `SPEC/ai/treasury-planner.md` § Priority and cargo and per the
//     `worldMarketBidTypeCap` implementation, the bid-side cap depends on
//     the GP having at least one embassy overture; the seed-42 campaign
//     under the current AI never establishes a GP↔GP embassy across the
//     100-turn EXPAND-phase horizon.
//   * **Deal matching collapses to zero.** With every GP submitting only
//     offers and nobody submitting bids, `cumulativeDealsAsSeller=0` and
//     `cumulativeDealsAsBuyer=0` for every GP. The carry-forward queue
//     fills with unfilled offers but never clears.
//   * **Treasury credited from world market sales = 0.** Path F never
//     puts a single treasury unit into any GP's account on seed 42 — the
//     chain breaks before treasury can recover. This is the same
//     bottom-line outcome as the Step-0 baseline, now decomposed to the
//     exact failing link.
//
// **Headline:** Path F is liquidity-starved on seed 42, not surplus-
// starved or cargo-starved. The failing link is not the TreasuryPlanner
// offer-side surplus / cargo logic; it is the **bid-side embassy gate**
// (`worldMarketBidTypeCap`) which is zero for every GP for the full
// 100-turn EXPAND-phase horizon, so no demand exists for the offers the
// planner aggressively emits. The next tuning slice should target the
// bid-side market liquidity gap (for example: AI diplomacy that opens
// embassies earlier under the lock predicate, a no-embassy fallback path
// for emergency lock-recovery bidding, or extending the world market to
// include minor / tribe auto-bids per #2991) rather than further tuning
// the urgent-offer threshold or the F8 fill-rate discount. Affordability
// is **not** bypassed anywhere in this finding.
//
// ## How to refresh
//
// Skipped by default (~4 min on the project reference host). Re-run with
//
// ```
// (cd packages/colonizethis_ai && dart test \
//     test/seed42_observer_world_market_diagnostic_test.dart \
//     --run-skipped)
// ```
//
// and copy the `WM2924_DIAGNOSTIC_JSON_BEGIN/END` block into a fresh
// comment on #2924 if the failing link shifts after a Path F tuning
// slice lands.

import 'dart:convert';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

/// Great Power factionIds the diagnostic scopes to (`gp1..gp6`). Mirrors
/// `kColonialPhaseEntryGreatPowerIds` in
/// `seed42_observer_colonial_phase_entry_budget_test.dart` and the
/// `gpIds` list in `seed42_observer_conquest_s7d_diagnostic_test.dart`
/// so the three seed-42 100-turn observer-tied surfaces agree on the
/// GP cohort.
const List<String> _kGreatPowerIds = [
  'gp1',
  'gp2',
  'gp3',
  'gp4',
  'gp5',
  'gp6',
];

/// The subset of `_kGreatPowerIds` that fails the seed-42 turn-100 +3 OW
/// gate (gp3, gp4, gp5, gp6 per the issue body's "Current passing/failing
/// state" table and the 2026-06-01 Step-0 baseline). Per-commodity top-5
/// rollups are emitted only for this subset so the diagnostic JSON stays
/// readable while still surfacing the failing-GP commodity mix that
/// matters for tuning.
const Set<String> _kFailingGreatPowerIds = {'gp3', 'gp4', 'gp5', 'gp6'};

/// Number of top commodities surfaced per failing GP in the per-commodity
/// rollup. Small enough that the JSON stays compact, large enough that the
/// most common stockpile surplus (timber, stone, etc.) and the most common
/// matched-deal commodity surface on the same page.
const int _kPerCommodityTopN = 5;

/// One per-GP per-turn record. Stored on `_TurnRow` then encoded into the
/// structured JSON output the test prints between `WM2924_DIAGNOSTIC_JSON_BEGIN`
/// / `WM2924_DIAGNOSTIC_JSON_END` markers.
class _TurnRow {
  const _TurnRow({
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
Map<String, Object?> _buildGpRollup({
  required List<_TurnRow> rows,
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
      // Report 1-based turn number for human readers (matches the issue
      // body / S7-D narrative). `r.turn` is the 0-based index used inside
      // the loop.
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
    'topOfferCommodities': _topNByQuantity(
      offerQuantityByCommodity,
      _kPerCommodityTopN,
    ),
    'topSellerDealCommodities': _topNByQuantity(
      sellerDealQuantityByCommodity,
      _kPerCommodityTopN,
    ),
  };
}

/// Deterministic top-N projection of `quantitiesByCommodity` sorted by
/// descending quantity then ascending commodity id (so equal-quantity
/// commodities print in a stable order across runs).
List<Map<String, Object?>> _topNByQuantity(
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

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test(
    'seed 42 turn 100 World-Market lock-recovery per-turn diagnostic '
    '(Refs #2924)',
    () {
      final init = runInitGame(
        config: GameSetupConfig(seed: 42),
        options: const InitGameOptions(
          cellSize: 24,
          renderPng: false,
          skipFillLakes: false,
        ),
      );
      var game = init.game.copyWith(
        aiControlByGpId: {for (final p in init.game.players) p.id: true},
      );
      final topo = init.combinedTopology;
      final tileMap = init.tileMapByRegion;

      final cheapest = cheapestRegimentBuildTreasuryCost();

      final perTurnRows = <String, List<_TurnRow>>{
        for (final gpId in _kGreatPowerIds) gpId: <_TurnRow>[],
      };
      final offerQuantityByCommodityByGp = <String, Map<String, int>>{
        for (final gpId in _kGreatPowerIds) gpId: <String, int>{},
      };
      final sellerDealQuantityByCommodityByGp = <String, Map<String, int>>{
        for (final gpId in _kGreatPowerIds) gpId: <String, int>{},
      };

      for (var t = 0; t < 100; t++) {
        // Snapshot inputs *before* the turn resolves so the diagnostic
        // reflects what the planner saw entering turn t+1: carry-forward
        // residuals, cargo / bid-type cap, and the treasury the suggester
        // gated on.
        final preTurnSnapshot = <String, ({int treasuryStart, int cargo, int bidTypeCap,
            int cfOffers, int cfBids, ObserverGoalPhase phase})>{};
        for (final gpId in _kGreatPowerIds) {
          final view = buildPlayerView(game, topo, gpId);
          final snap = AIWorldSnapshot.fromPlayerView(view, topology: topo);
          final outcome = runPhasePlanners(game: game, snapshot: snap);
          final player = game.playerById(gpId);
          final treasuryStart = player?.treasury ?? 0;
          final cargo = cargoHoldsForHomeFleet(game, gpId);
          final bidTypeCap = worldMarketBidTypeCap(game, gpId);
          final cfOffers = (game.worldMarketState
                  .carryForwardOffersByFactionId[gpId] ??
              const <TradeOrder>[]);
          final cfBids = (game
                  .worldMarketState.carryForwardBidsByFactionId[gpId] ??
              const <TradeOrder>[]);
          preTurnSnapshot[gpId] = (
            treasuryStart: treasuryStart,
            cargo: cargo < 0 ? 0 : cargo,
            bidTypeCap: bidTypeCap,
            cfOffers: cfOffers.length,
            cfBids: cfBids.length,
            phase: outcome.phase,
          );
        }

        final fullAi = generateOrdersForGameFullAI(
          game,
          topo,
          tileMapByRegion: tileMap,
        );

        // Capture trade-order emission per GP from the orders the
        // orchestrator produced this turn (F7-wired
        // `tradeOrdersByPlayerId`).
        final emittedThisTurn = <String, ({int offers, int bids,
            int offerQty, int bidQty})>{};
        for (final gpId in _kGreatPowerIds) {
          final orders = fullAi.orders.tradeOrdersByPlayerId[gpId] ??
              const <TradeOrder>[];
          var offers = 0;
          var bids = 0;
          var offerQty = 0;
          var bidQty = 0;
          for (final o in orders) {
            switch (o.type) {
              case TradeOrderType.offer:
                offers += 1;
                offerQty += o.quantity;
                offerQuantityByCommodityByGp[gpId]![o.commodityId] =
                    (offerQuantityByCommodityByGp[gpId]![o.commodityId] ?? 0) +
                        o.quantity;
              case TradeOrderType.bid:
                bids += 1;
                bidQty += o.quantity;
            }
          }
          emittedThisTurn[gpId] = (
            offers: offers,
            bids: bids,
            offerQty: offerQty,
            bidQty: bidQty,
          );
        }

        final merged = mergeOrderLists(
          humanOrders: const Orders(),
          aiOrders: fullAi.orders,
        );
        final assignments = fullAi.economyPlansByPlayerId.map(
          (pid, plan) => MapEntry(pid, plan.productionAssignments),
        );
        final result = validateOrdersAndResolveTurnFromTrustedOrders(
          game: fullAi.game,
          topology: topo,
          orders: merged,
          tileMapByRegion: tileMap,
          defaultAssignmentsByPlayerId: assignments,
        );
        expect(result, isA<TurnResolutionComplete>());
        final resolved = (result as TurnResolutionComplete).game;

        // Walk this turn's `lastTurnActivity` deals and attribute
        // credit / debit to seller / buyer GP. `lastTurnActivity` is
        // keyed by commodity id; each `MarketActivity.deals` carries
        // every `FilledDeal` the matcher produced for that commodity
        // this turn.
        final dealCountsAsSeller = <String, int>{
          for (final gpId in _kGreatPowerIds) gpId: 0,
        };
        final treasuryCreditedAsSeller = <String, int>{
          for (final gpId in _kGreatPowerIds) gpId: 0,
        };
        final dealCountsAsBuyer = <String, int>{
          for (final gpId in _kGreatPowerIds) gpId: 0,
        };
        final treasurySpentAsBuyer = <String, int>{
          for (final gpId in _kGreatPowerIds) gpId: 0,
        };
        for (final activity in resolved.worldMarketState.lastTurnActivity.values) {
          for (final deal in activity.deals) {
            final dealValue = (deal.quantity * deal.pricePerUnit).round();
            if (dealCountsAsSeller.containsKey(deal.sellerFactionId)) {
              dealCountsAsSeller[deal.sellerFactionId] =
                  (dealCountsAsSeller[deal.sellerFactionId] ?? 0) + 1;
              treasuryCreditedAsSeller[deal.sellerFactionId] =
                  (treasuryCreditedAsSeller[deal.sellerFactionId] ?? 0) +
                      dealValue;
              sellerDealQuantityByCommodityByGp[deal.sellerFactionId]![
                      deal.commodityId] =
                  (sellerDealQuantityByCommodityByGp[deal.sellerFactionId]![
                              deal.commodityId] ??
                          0) +
                      deal.quantity;
            }
            if (dealCountsAsBuyer.containsKey(deal.buyerFactionId)) {
              dealCountsAsBuyer[deal.buyerFactionId] =
                  (dealCountsAsBuyer[deal.buyerFactionId] ?? 0) + 1;
              treasurySpentAsBuyer[deal.buyerFactionId] =
                  (treasurySpentAsBuyer[deal.buyerFactionId] ?? 0) + dealValue;
            }
          }
        }

        for (final gpId in _kGreatPowerIds) {
          final pre = preTurnSnapshot[gpId]!;
          final emit = emittedThisTurn[gpId]!;
          final treasuryEnd = resolved.playerById(gpId)?.treasury ?? 0;
          perTurnRows[gpId]!.add(
            _TurnRow(
              turn: t,
              phase: pre.phase,
              treasuryStart: pre.treasuryStart,
              treasuryEnd: treasuryEnd,
              tradeCargoCapacity: pre.cargo,
              bidTypeCap: pre.bidTypeCap,
              offersEmitted: emit.offers,
              bidsEmitted: emit.bids,
              offerQuantityTotal: emit.offerQty,
              bidQuantityTotal: emit.bidQty,
              carryForwardOffersCount: pre.cfOffers,
              carryForwardBidsCount: pre.cfBids,
              dealsAsSeller: dealCountsAsSeller[gpId] ?? 0,
              treasuryCreditedAsSeller: treasuryCreditedAsSeller[gpId] ?? 0,
              dealsAsBuyer: dealCountsAsBuyer[gpId] ?? 0,
              treasurySpentAsBuyer: treasurySpentAsBuyer[gpId] ?? 0,
            ),
          );
        }

        game = resolved;
      }

      // Build the structured rollup. Per-GP rollups consume only the
      // failing-GP commodity tables for top-5 commodity reporting; this
      // keeps the JSON readable while still surfacing the failing-GP
      // surplus / matched-deal mix that matters for tuning.
      final gpRollup = <String, Object?>{
        for (final gpId in _kGreatPowerIds)
          gpId: _buildGpRollup(
            rows: perTurnRows[gpId]!,
            offerQuantityByCommodity: _kFailingGreatPowerIds.contains(gpId)
                ? offerQuantityByCommodityByGp[gpId]!
                : const <String, int>{},
            sellerDealQuantityByCommodity:
                _kFailingGreatPowerIds.contains(gpId)
                    ? sellerDealQuantityByCommodityByGp[gpId]!
                    : const <String, int>{},
            cheapestRegimentBuildTreasuryCost: cheapest,
          ),
      };

      final diagnostic = <String, Object?>{
        'issue': 2924,
        'subtask': 'world-market-per-turn-diagnostic',
        'seed': 42,
        'turns': 100,
        'cheapestRegimentBuildTreasuryCost': cheapest,
        'failingGreatPowerIds': _kFailingGreatPowerIds.toList()..sort(),
        'perCommodityTopN': _kPerCommodityTopN,
        'gpRollup': gpRollup,
        'gpPerTurnRows': {
          for (final gpId in _kGreatPowerIds)
            gpId: [for (final r in perTurnRows[gpId]!) r.toJson()],
        },
      };

      // Re-enable info-level logging so the structured diagnostic JSON
      // surfaces in stdout via the package logger (the simulation above
      // ran with logging off to suppress planner noise). Routing through
      // `aiLogger` keeps this test compliant with the disallowed-AST
      // `avoid_print_suppression` rule while preserving greppable
      // BEGIN/END markers for issue-comment transcription. Markers
      // mirror the S7-D pattern (`S7D_DIAGNOSTIC_JSON_BEGIN/END`).
      CtLogger.level = Level.info;
      final log = aiLogger('wm2924-diagnostic');
      log.i('WM2924_DIAGNOSTIC_JSON_BEGIN');
      log.i(const JsonEncoder.withIndent('  ').convert(diagnostic));
      log.i('WM2924_DIAGNOSTIC_JSON_END');

      for (final gpId in _kGreatPowerIds) {
        expect(
          perTurnRows[gpId]!.length,
          100,
          reason: 'Refs #2924 per-turn diagnostic: $gpId per-turn row '
              'count should equal 100 (one record per turn).',
        );
      }
    },
    skip:
        'Refs #2924 per-turn World-Market lock-recovery diagnostic: '
        'long-running (~4 min) per-GP per-turn trace mirroring the S7-D '
        'skip pattern. Re-run with `dart test --run-skipped` and '
        'transcribe the WM2924_DIAGNOSTIC_JSON_BEGIN/END block into a '
        'comment on #2924 when the diagnostic surface shifts after a '
        'Path F tuning slice lands.',
    timeout: const Timeout(Duration(minutes: 20)),
  );
}
