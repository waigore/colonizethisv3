import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_diplomacy/colonizethis_diplomacy.dart'
    show ftpPairKeysFromGame, getRelation;
import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_world/colonizethis_world.dart';
import '../turn_pipeline_state.dart';
import '../turn_resolver_config.dart';
import 'world_market_phase_orders.dart';
import 'world_market_phase_price_discovery.dart';
import 'world_market_phase_deals.dart';
import 'world_market_phase_carry_forward.dart';
import 'world_market_phase_activity.dart';

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
///    `SPEC/game/world-market.md` Requirement 9; the **owning GP
///    overseas-profit credit** (Refs #2992 D4) is applied additively
///    afterward via [computeFirstRightCredits], using the per-GP relation
///    score with the source minor/tribe (clamped 0–100) and the
///    `(relationScore / 100) * 0.40` rate per
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

  final newOffersByFactionId = <String, List<TradeOrder>>{};
  final newBidsByFactionId = <String, List<TradeOrder>>{};
  for (final entry in config.orders.tradeOrdersByPlayerId.entries) {
    final offers = <TradeOrder>[];
    final bids = <TradeOrder>[];
    for (final order in entry.value) {
      if (order.quantity <= 0) continue;
      if (order.type == TradeOrderType.offer) {
        offers.add(order);
      } else {
        bids.add(order);
      }
    }
    if (offers.isNotEmpty) newOffersByFactionId[entry.key] = offers;
    if (bids.isNotEmpty) newBidsByFactionId[entry.key] = bids;
  }

  // Minor/tribe auto-offers (Refs #2991 C4) — `SPEC/program/world-market-resolution.md`
  // § Step A Gather (Step A.2) and `SPEC/game/world-market.md` § Minor and
  // tribe auto-sell. Each connected non-GP tile producing a non-riches
  // commodity contributes one `TradeOrder(type: offer, priority: 1,
  // originTileKey: tileKey)`. These auto-offers feed the matcher alongside
  // GP-submitted orders; they are intentionally **not** stored as
  // carry-forwards (per § Step E "Minor/Tribe auto-offers do not carry
  // forward") and are excluded from price discovery aggregation (handled
  // implicitly by `aggregateNewQuantitiesPerCommodity` keying on
  // `newOffersByFactionId` only — auto-offers live in their own map).
  final autoOffersByFactionId = computeMinorTribeAutoOffers(
    game: game,
    config: config,
  );

  // Lock-recovery minor auto-bids (Refs #2924 F15): when any GP is below the
  // regiment-build treasury band, each Minor Nation submits a synthetic bid for
  // the liquidity food commodity. Synthetic treasury/cargo budgets are injected
  // below so the matcher can clear broke GP urgent offers without debiting a GP
  // wallet. Bids are not carry-forwarded (same as minor auto-offers).
  final lockRecoveryMinorBidsByFactionId = computeLockRecoveryMinorAutoBids(
    game: game,
    worldMarketState: priorMarket,
  );

  final regimentBuildThreshold = cheapestRegimentBuildTreasuryCost();
  final lockRecoverySellerPriorityIds = <String>{
    for (final player in game.players)
      if (player.treasury < regimentBuildThreshold) player.id,
  };
  // F15 (Refs #2924; SPEC/program/world-market-resolution.md § Step A 3.1):
  // build a phase-13-only view where any broke GP (negative treasury and
  // below the regiment-build band) is treated as having `treasury = 0`.
  // The clamped view feeds the matcher's seller-priority sort and the
  // per-buyer treasury budget so seller credits from urgent offers are
  // not consumed servicing phase-1–12 debt. Player.treasury is **not**
  // mutated here — post-phase persistence is computed from original
  // values plus deal-applied deltas (see `applyDealsToPlayers`), which
  // preserves AC#3 (a broke buyer with no fills exits phase 13 with
  // their original negative balance unchanged). Not an affordability
  // bypass — regiment builds still require
  // `treasury >= cheapestRegimentBuildTreasuryCost()` after phase 13.
  final gameForMarket = lockRecoverySellerPriorityIds.isEmpty
      ? game
      : game.copyWith(
          players: [
            for (final p in game.players)
              lockRecoverySellerPriorityIds.contains(p.id) && p.treasury < 0
                  ? p.copyWith(treasury: 0)
                  : p,
          ],
        );

  // Compute start-of-phase trade cargo capacity and stockpile per GP. These
  // values gate (a) carry-forward re-validation per
  // `SPEC/program/world-market-resolution.md` § Step A.3 and (b) the
  // matcher's downstream cargo cap. Minor/tribe sellers are not GPs and
  // are absent from these maps, which is intentional — carry-forwards are
  // only re-validated for known GP factions; unknown faction ids fall
  // through unchanged for now (no upstream owner to re-check), matching
  // the matcher's GP-only validation surface.
  final fleetsByIdStartOfPhase = fleetsByIdForWorld(game.worldState);
  final tradeCapacityByFactionId = <String, int>{};
  final stockpileByFactionId = <String, Stockpile>{};
  // Raw per-GP treasury (unclamped) fed to the deal matcher's settlement.
  // Built in the same player pass as the maps above to avoid a second full
  // iteration (Refs #3565). Minor/tribe sellers are intentionally absent —
  // only GP factions carry a settlement treasury here.
  final treasuryByFactionId = <String, int>{};
  // Per-buyer treasury budget passed to the deal matcher (Refs #3115).
  // Uses `Player.treasury` at phase 13 start clamped at `0` for negative
  // balances. Phase 13 runs after phase 12 Build/Work so this value
  // already reflects earlier-phase debits per
  // `SPEC/program/world-market-resolution.md` § Step C.
  final treasuryBudgetByBuyerFactionId = <String, int>{};
  final extractionTonnageByPlayerId =
      acc.overseasExtractionShippedTonnageByPlayerId;
  for (final player in gameForMarket.players) {
    stockpileByFactionId[player.id] = player.stockpile;
    final homeFleetHolds = cargoHoldsForHomeFleet(
      gameForMarket,
      player.id,
      fleetsById: fleetsByIdStartOfPhase,
    );
    final shippedByExtraction = extractionTonnageByPlayerId[player.id] ?? 0;
    final tradeCapacity = homeFleetHolds - shippedByExtraction;
    tradeCapacityByFactionId[player.id] = tradeCapacity > 0 ? tradeCapacity : 0;
    treasuryBudgetByBuyerFactionId[player.id] = player.treasury > 0
        ? player.treasury
        : 0;
    treasuryByFactionId[player.id] = player.treasury;
  }
  for (final minorId in lockRecoveryMinorBidsByFactionId.keys) {
    tradeCapacityByFactionId[minorId] = kLockRecoveryMinorBidCargoCapacity;
    treasuryBudgetByBuyerFactionId[minorId] =
        kLockRecoveryMinorSyntheticTreasuryBudget;
  }

  final carryForwardValidation = validateCarryForwards(
    carryForwardOffersByFactionId: priorMarket.carryForwardOffersByFactionId,
    carryForwardBidsByFactionId: priorMarket.carryForwardBidsByFactionId,
    stockpileByFactionId: stockpileByFactionId,
    tradeCapacityByFactionId: tradeCapacityByFactionId,
  );

  final mergedOffersByFactionId = mergeOrdersByFaction(
    newOffersByFactionId,
    carryForwardValidation.validOffersByFactionId,
    autoOffersByFactionId,
  );
  final mergedBidsByFactionId = mergeOrdersByFaction(
    newBidsByFactionId,
    carryForwardValidation.validBidsByFactionId,
    lockRecoveryMinorBidsByFactionId,
  );

  final hasAnyOrders =
      mergedOffersByFactionId.isNotEmpty || mergedBidsByFactionId.isNotEmpty;

  final newQuantitiesByCommodity = aggregateNewQuantitiesPerCommodity(
    newOffersByFactionId: newOffersByFactionId,
    newBidsByFactionId: newBidsByFactionId,
  );

  if (!hasAnyOrders) {
    final activity = <CommodityId, MarketActivity>{};
    for (final entry in newQuantitiesByCommodity.entries) {
      if (entry.value.bid == 0 && entry.value.offer == 0) continue;
      activity[entry.key] = MarketActivity(
        totalBidQuantity: entry.value.bid,
        totalOfferQuantity: entry.value.offer,
      );
    }
    // Attach any drop notes even when no surviving orders remain — the
    // Deal Book / observer trace still needs to see the dropped
    // carry-forwards for the resolved turn.
    attachDropNotes(
      activity: activity,
      notesByCommodity: carryForwardValidation.dropNotesByCommodity,
    );
    final updatedMarket = priorMarket.copyWith(
      lastTurnActivity: Map<CommodityId, MarketActivity>.unmodifiable(activity),
      carryForwardOffersByFactionId: const <String, List<TradeOrder>>{},
      carryForwardBidsByFactionId: const <String, List<TradeOrder>>{},
    );
    return TurnPhaseStepContinue(
      acc.copyWith(game: game.copyWith(worldMarketState: updatedMarket)),
    );
  }

  final ftpPairKeys = ftpPairKeysFromGame(game);
  final purchasedTileIndex = PurchasedTileIndex.fromGame(game);

  final matchInputs = (
    offersByFactionId: mergedOffersByFactionId,
    bidsByFactionId: mergedBidsByFactionId,
    tradeCapacityByFactionId: tradeCapacityByFactionId,
    treasuryBudgetByBuyerFactionId: treasuryBudgetByBuyerFactionId,
    pricesByCommodityId: <CommodityId, double>{
      for (final entry in priorMarket.prices.entries)
        entry.key: entry.value.toDouble(),
    },
    ftpPairKeys: ftpPairKeys,
    purchasedTileIndex: purchasedTileIndex,
    lockRecoverySellerPriorityIds: lockRecoverySellerPriorityIds,
    treasuryByFactionId: treasuryByFactionId,
  );
  final matchResult = DealMatcher.matchDeals(matchInputs);

  final firstRightCredits = computeFirstRightCredits(
    filledDeals: matchResult.filledDeals,
    purchasedTileIndex: purchasedTileIndex,
    relationScoreFor: (owningGpId, sourceFactionId) =>
        getRelation(game, owningGpId, sourceFactionId)?.score ?? 0,
  );

  final lockRecoveryLiquidityCommodityId =
      lockRecoveryMinorBidsByFactionId.isEmpty
      ? null
      : lockRecoveryMinorBidsByFactionId.values.first.first.commodityId;

  final updatedPlayers = applyDealsToPlayers(
    players: game.players,
    filledDeals: matchResult.filledDeals,
    firstRightTreasuryCreditByGpId: firstRightCredits.treasuryCreditByGpId,
    lockRecoverySellerPriorityIds: lockRecoverySellerPriorityIds,
    lockRecoveryLiquidityCommodityId: lockRecoveryLiquidityCommodityId,
  );

  // Price-discovery bid-side cap (Refs #3115): aggregate `totalBid_new[c]`
  // from the filled portion of newly-submitted bids only (not from
  // submitted quantity). The newly-submitted bids appear at the head of
  // each faction's merged bid list per `mergeOrdersByFaction`, so Step C
  // consumes them before any carry-forward residuals; the per-(faction,
  // commodity) `min` below allocates filled units to newly-submitted bids
  // first. See SPEC/program/world-market-resolution.md § Step E.
  final filledNewBidsByCommodity = aggregateFilledNewBidsByCommodity(
    newBidsByFactionId: newBidsByFactionId,
    filledDeals: matchResult.filledDeals,
  );
  final priceDiscoveryByCommodity = buildPriceDiscoveryPairs(
    newQuantitiesByCommodity: newQuantitiesByCommodity,
    filledNewBidsByCommodity: filledNewBidsByCommodity,
  );

  final newPrices = computeNextPrices(
    priorPrices: priorMarket.prices,
    newQuantitiesByCommodity: priceDiscoveryByCommodity,
  );

  final activity = buildActivity(
    matchResult: matchResult,
    newQuantitiesByCommodity: priceDiscoveryByCommodity,
    priorPrices: priorMarket.prices,
    newPrices: newPrices,
  );
  attachMatcherNotes(activity: activity, matchResult: matchResult);
  attachDropNotes(
    activity: activity,
    notesByCommodity: carryForwardValidation.dropNotesByCommodity,
  );

  // Minor/tribe auto-offers never carry forward (Refs #2991 C4) per
  // `SPEC/program/world-market-resolution.md` § Step E: each turn re-emits
  // them based on that turn's extraction. Restrict carry-forwards to known
  // Great-Power faction ids; unknown ids (auto-offer minors/tribes and any
  // other non-GP submitter) are dropped from the persisted map.
  final gpFactionIds = <String>{for (final p in game.players) p.id};
  final updatedMarket = priorMarket.copyWith(
    prices: Map<CommodityId, int>.unmodifiable(newPrices),
    lastTurnActivity: Map<CommodityId, MarketActivity>.unmodifiable(activity),
    carryForwardOffersByFactionId: restrictToFactions(
      matchResult.unfilledOffersByFactionId,
      gpFactionIds,
    ),
    carryForwardBidsByFactionId: matchResult.unfilledBidsByFactionId,
  );

  final nextGame = game
      .withPlayers(updatedPlayers)
      .copyWith(worldMarketState: updatedMarket);
  return TurnPhaseStepContinue(acc.copyWith(game: nextGame));
}
