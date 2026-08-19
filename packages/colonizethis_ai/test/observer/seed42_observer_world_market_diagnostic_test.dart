// Seed-42 100-turn per-turn World-Market lock-recovery diagnostic
// (Refs #2924, SPEC/ai/treasury-planner.md
// § "Seed-42 100-turn per-turn World-Market lock-recovery diagnostic").
//
// Migrated to the shared [runSeed42ObserverCampaign] harness (Refs #3749
// step 2): the init / handoff / 100-turn resolve loop is owned by
// `test/support/seed42_observer_campaign.dart`; this test contributes only
// its per-turn `onBeforeResolve` / `onAfterResolve` observations.
//
// Initial / refreshed findings (2026-06-01 and 2026-06-03 baselines) live in
// `test/support/seed42_observer_world_market_diagnostic_findings.md`.
//
// Skip semantics + runtime mirror `seed42_observer_conquest_s7d_diagnostic_test.dart`:
// the test is `skip`ped by default (long-running, ~4 min on the project
// reference host) and re-run manually with `dart test --run-skipped` when
// the diagnostic surface shifts after a Path F tuning slice lands.

import 'dart:convert';

import 'package:colonizethis_ai/colonizethis_ai.dart';
import 'package:colonizethis_ai/src/planning/expand_phase_planner.dart'
    show cheapestRegimentBuildTreasuryCost;
import 'package:colonizethis_logger/colonizethis_logger.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_test/test.dart';
import 'package:logger/logger.dart';

import 'support/seed42_observer_campaign.dart';
import 'support/seed42_observer_world_market_diagnostic_support.dart';

void main() {
  setUpAll(() {
    CtLogger.level = Level.off;
  });

  test(
    'seed 42 turn 100 World-Market lock-recovery per-turn diagnostic '
    '(Refs #2924)',
    () {
      final cheapest = cheapestRegimentBuildTreasuryCost();

      final perTurnRows = <String, List<Seed42WorldMarketTurnRow>>{
        for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds)
          gpId: <Seed42WorldMarketTurnRow>[],
      };
      final offerQuantityByCommodityByGp = <String, Map<String, int>>{
        for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds)
          gpId: <String, int>{},
      };
      final sellerDealQuantityByCommodityByGp = <String, Map<String, int>>{
        for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds)
          gpId: <String, int>{},
      };

      final pendingByTurn = <int, Seed42PendingWorldMarketTurn>{};

      runSeed42ObserverCampaign(
        turns: 100,
        onBeforeResolve: (turn, fullAi, game, topo, tileMap) {
          // Snapshot inputs *before* the turn resolves so the diagnostic
          // reflects what the planner saw entering turn t+1: carry-forward
          // residuals, cargo / bid-type cap, and the treasury the suggester
          // gated on.
          final preTurnSnapshot = <String,
              ({
                int treasuryStart,
                int cargo,
                int bidTypeCap,
                int cfOffers,
                int cfBids,
                ObserverGoalPhase phase,
              })>{};
          for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds) {
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

          // Capture trade-order emission per GP from the orders the
          // orchestrator produced this turn (F7-wired
          // `tradeOrdersByPlayerId`).
          final emittedThisTurn = <String,
              ({int offers, int bids, int offerQty, int bidQty})>{};
          for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds) {
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
                      (offerQuantityByCommodityByGp[gpId]![o.commodityId] ??
                              0) +
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

          // Stash per-turn pre-resolve + emission state for onAfterResolve.
          pendingByTurn[turn] = Seed42PendingWorldMarketTurn(
            preTurnSnapshot: preTurnSnapshot,
            emittedThisTurn: emittedThisTurn,
          );
        },
        onAfterResolve: (turn, resolved) {
          final pending = pendingByTurn.remove(turn);
          if (pending == null) {
            fail(
              'Refs #2924 per-turn diagnostic: missing pre-resolve snapshot '
              'for turn $turn.',
            );
          }

          // Walk this turn's `lastTurnActivity` deals and attribute
          // credit / debit to seller / buyer GP. `lastTurnActivity` is
          // keyed by commodity id; each `MarketActivity.deals` carries
          // every `FilledDeal` the matcher produced for that commodity
          // this turn.
          final dealCountsAsSeller = <String, int>{
            for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds)
              gpId: 0,
          };
          final treasuryCreditedAsSeller = <String, int>{
            for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds)
              gpId: 0,
          };
          final dealCountsAsBuyer = <String, int>{
            for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds)
              gpId: 0,
          };
          final treasurySpentAsBuyer = <String, int>{
            for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds)
              gpId: 0,
          };
          for (final activity
              in resolved.worldMarketState.lastTurnActivity.values) {
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
                    (treasurySpentAsBuyer[deal.buyerFactionId] ?? 0) +
                        dealValue;
              }
            }
          }

          for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds) {
            final pre = pending.preTurnSnapshot[gpId]!;
            final emit = pending.emittedThisTurn[gpId]!;
            final treasuryEnd = resolved.playerById(gpId)?.treasury ?? 0;
            perTurnRows[gpId]!.add(
              Seed42WorldMarketTurnRow(
                turn: turn,
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
        },
      );

      // Build the structured rollup. Per-GP rollups consume only the
      // failing-GP commodity tables for top-5 commodity reporting; this
      // keeps the JSON readable while still surfacing the failing-GP
      // surplus / matched-deal mix that matters for tuning.
      final gpRollup = <String, Object?>{
        for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds)
          gpId: buildSeed42WorldMarketGpRollup(
            rows: perTurnRows[gpId]!,
            offerQuantityByCommodity: kSeed42WorldMarketDiagnosticFailingGreatPowerIds
                    .contains(gpId)
                ? offerQuantityByCommodityByGp[gpId]!
                : const <String, int>{},
            sellerDealQuantityByCommodity:
                kSeed42WorldMarketDiagnosticFailingGreatPowerIds.contains(gpId)
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
        'failingGreatPowerIds':
            kSeed42WorldMarketDiagnosticFailingGreatPowerIds.toList()..sort(),
        'perCommodityTopN': kSeed42WorldMarketDiagnosticPerCommodityTopN,
        'gpRollup': gpRollup,
        'gpPerTurnRows': {
          for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds)
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

      for (final gpId in kSeed42WorldMarketDiagnosticGreatPowerIds) {
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
