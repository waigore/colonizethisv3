import 'package:colonizethis_models/colonizethis_models.dart';

import '../turn_pipeline_state.dart';
import '../turn_resolver_config.dart';
import 'world_market_phase_gather.dart';
import 'world_market_phase_settlement.dart';

/// World Market phase (phase 13) — gather submitted Great-Power trade orders,
/// merge previous-turn carry-forwards, run the deal-matching engine, apply
/// commodity / treasury / cargo transfers, recompute prices, and persist the
/// updated [WorldMarketState] (including the new carry-forward queues for the
/// next turn).
///
/// SPEC sources:
///
/// - `SPEC/program/turn-resolution-phases.md` § Phase 13 World Market.
/// - `SPEC/program/world-market-resolution.md` § Resolution algorithm
///   (Steps A–F).
/// - `SPEC/game/world-market.md` § Trade orders, Cargo, Price discovery,
///   Order persistence.
///
/// **Slice scope (Refs #2990 B3, GP↔GP path + #2992 D4 phase integration).**
/// This implementation covers the Great-Power side of Steps A, C, D, E, and
/// F end-to-end, and applies the First Right of Refusal overseas-profit
/// treasury credit from minor/tribe sales to owning GPs:
///
/// 1. Gathers Great-Power offers/bids from `Orders.tradeOrdersByPlayerId`.
/// 2. Merges previous-turn carry-forwards stored on
///    `WorldMarketState.carryForwardOffersByFactionId` /
///    `carryForwardBidsByFactionId`, re-validating each carry-forward
///    against the submitter's **start-of-phase** stockpile (for offers)
///    and trade cargo capacity (for bids) per
///    `SPEC/game/world-market.md` § Order persistence and
///    `SPEC/program/world-market-resolution.md` § Step A Gather.
///    Carry-forwards whose constraint can no longer be met are dropped
///    before matching and recorded as `MarketActivityNote` entries on
///    the affected commodity's `MarketActivity` so the Deal Book and
///    observer traces can explain the drop.
/// 3. Computes per-GP `tradeCargoCapacity` as
///    `max(0, cargoHoldsForHomeFleet − overseasExtractionShippedTonnage)`,
///    where the overseas tonnage signal is the per-player value the
///    extraction phase published onto
///    [TurnPipelineState.overseasExtractionShippedTonnageByPlayerId]
///    (post-cargo-cap, pre-interception). Implements the SPEC AC *Cargo
///    released by under-used extraction* in
///    `SPEC/game/world-market.md` § Cargo: any extraction holds reserved
///    but not consumed are released to trade. Missing entries are treated
///    as zero tonnage so the legacy direct-handler test path (no upstream
///    extraction phase) keeps using the full home-fleet capacity.
/// 4. Runs [DealMatcher.matchDeals] with FTP keys from
///    [ftpPairKeysFromGame].
/// 5. Applies transfers: buyer treasury debit + seller treasury credit (GP
///    sellers only) and stockpile delta on both sides. Minor/tribe sellers
///    remain a treasury sink (no faction credited) per
///    `SPEC/game/world-market.md` Requirement 9; the **two-tier overseas
///    profit-share** (Refs #2992 D4 + #3753 R8) is applied additively
///    afterward via [computeFirstRightCredits]: the tile-owning GP receives
///    the **full** relation-linear share (`relationScore / 100`, no 40% cap,
///    R8.2) and every other embassy-holding GP receives a 10% kickback of its
///    relation portion (R8.3) per
///    `SPEC/game/world-market-first-right-of-refusal.md` § Treasury
///    transfer (D4).
/// 6. Recomputes per-commodity prices via [PriceDiscovery.computeNextPrice]
///    using **only** newly-submitted current-turn quantities (carry-forwards
///    are excluded from price aggregation per
///    `SPEC/game/world-market.md` § Price discovery).
/// 7. Persists the new [WorldMarketState]: prices, per-commodity
///    [MarketActivity], and per-faction carry-forward queues for the next
///    turn's Step A.
///
/// The handler is silent on the no-orders happy path (no log spam in the hot
/// turn loop). Logging of resolver outcomes is deferred to a follow-up that
/// wires the canonical `logic: phase worldMarket …` lines per
/// `SPEC/program/world-market-resolution.md` § Logging.
TurnPhaseStepOutcome worldMarketTurnPhaseHandler(
  TurnPipelineState acc,
  TurnResolverConfig config,
  int turn,
) {
  final game = acc.game;
  final priorMarket = game.worldMarketState;

  final gather = gatherWorldMarketPhaseInputs(
    game: game,
    priorMarket: priorMarket,
    config: config,
    extractionTonnageByPlayerId: acc.overseasExtractionShippedTonnageByPlayerId,
  );

  if (!gather.hasAnyOrders) {
    return worldMarketNoOrdersOutcome(
      acc: acc,
      priorMarket: priorMarket,
      newQuantitiesByCommodity: gather.newQuantitiesByCommodity,
      carryForwardValidation: gather.carryForwardValidation,
    );
  }

  return settleWorldMarketMatch(
    acc: acc,
    gather: gather,
    priorMarket: priorMarket,
  );
}
