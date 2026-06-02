import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../diplomacy/diplomacy_relation_lookup.dart'
    show ftpPairKeysFromGame, getRelation;
import '../../economy/non_gp_extraction.dart';
import '../../economy/sea_transport.dart';
import '../../economy/world_market/deal_matcher.dart';
import '../../economy/world_market/first_right_credits.dart';
import '../../economy/world_market/price_discovery.dart';
import '../../economy/world_market/purchased_tile_index.dart';
import '../../world/connectivity_resolver.dart';
import '../../world/game_world_mutations.dart';
import '../turn_pipeline_state.dart';
import '../turn_resolver_config.dart';

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
  // implicitly by `_aggregateNewQuantitiesPerCommodity` keying on
  // `newOffersByFactionId` only — auto-offers live in their own map).
  final autoOffersByFactionId = _computeMinorTribeAutoOffers(
    game: game,
    config: config,
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
  // Per-buyer treasury budget passed to the deal matcher (Refs #3115).
  // Uses `Player.treasury` at phase 13 start clamped at `0` for negative
  // balances. Phase 13 runs after phase 12 Build/Work so this value
  // already reflects earlier-phase debits per
  // `SPEC/program/world-market-resolution.md` § Step C.
  final treasuryBudgetByBuyerFactionId = <String, int>{};
  final extractionTonnageByPlayerId =
      acc.overseasExtractionShippedTonnageByPlayerId;
  for (final player in game.players) {
    stockpileByFactionId[player.id] = player.stockpile;
    final homeFleetHolds = cargoHoldsForHomeFleet(
      game,
      player.id,
      fleetsById: fleetsByIdStartOfPhase,
    );
    final shippedByExtraction =
        extractionTonnageByPlayerId[player.id] ?? 0;
    final tradeCapacity = homeFleetHolds - shippedByExtraction;
    tradeCapacityByFactionId[player.id] = tradeCapacity > 0 ? tradeCapacity : 0;
    treasuryBudgetByBuyerFactionId[player.id] =
        player.treasury > 0 ? player.treasury : 0;
  }

  final carryForwardValidation = _validateCarryForwards(
    carryForwardOffersByFactionId: priorMarket.carryForwardOffersByFactionId,
    carryForwardBidsByFactionId: priorMarket.carryForwardBidsByFactionId,
    stockpileByFactionId: stockpileByFactionId,
    tradeCapacityByFactionId: tradeCapacityByFactionId,
  );

  final mergedOffersByFactionId = _mergeOrdersByFaction(
    newOffersByFactionId,
    carryForwardValidation.validOffersByFactionId,
    autoOffersByFactionId,
  );
  final mergedBidsByFactionId = _mergeOrdersByFaction(
    newBidsByFactionId,
    carryForwardValidation.validBidsByFactionId,
  );

  final hasAnyOrders =
      mergedOffersByFactionId.isNotEmpty || mergedBidsByFactionId.isNotEmpty;

  final newQuantitiesByCommodity = _aggregateNewQuantitiesPerCommodity(
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
    _attachDropNotes(
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
  final regimentBuildThreshold = cheapestRegimentBuildTreasuryCost();
  final treasuryByFactionId = <String, int>{
    for (final player in game.players) player.id: player.treasury,
  };
  final lockRecoverySellerPriorityIds = <String>{
    for (final entry in treasuryByFactionId.entries)
      if (entry.value < regimentBuildThreshold) entry.key,
  };

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

  final updatedPlayers = _applyDealsToPlayers(
    players: game.players,
    filledDeals: matchResult.filledDeals,
    firstRightTreasuryCreditByGpId: firstRightCredits.treasuryCreditByGpId,
  );

  // Price-discovery bid-side cap (Refs #3115): aggregate `totalBid_new[c]`
  // from the filled portion of newly-submitted bids only (not from
  // submitted quantity). The newly-submitted bids appear at the head of
  // each faction's merged bid list per `_mergeOrdersByFaction`, so Step C
  // consumes them before any carry-forward residuals; the per-(faction,
  // commodity) `min` below allocates filled units to newly-submitted bids
  // first. See SPEC/program/world-market-resolution.md § Step E.
  final filledNewBidsByCommodity = _aggregateFilledNewBidsByCommodity(
    newBidsByFactionId: newBidsByFactionId,
    filledDeals: matchResult.filledDeals,
  );
  final priceDiscoveryByCommodity = _buildPriceDiscoveryPairs(
    newQuantitiesByCommodity: newQuantitiesByCommodity,
    filledNewBidsByCommodity: filledNewBidsByCommodity,
  );

  final newPrices = _computeNextPrices(
    priorPrices: priorMarket.prices,
    newQuantitiesByCommodity: priceDiscoveryByCommodity,
  );

  final activity = _buildActivity(
    matchResult: matchResult,
    newQuantitiesByCommodity: priceDiscoveryByCommodity,
    priorPrices: priorMarket.prices,
    newPrices: newPrices,
  );
  _attachMatcherNotes(
    activity: activity,
    matchResult: matchResult,
  );
  _attachDropNotes(
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
    carryForwardOffersByFactionId: _restrictToFactions(
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

class _NewQuantityPair {
  const _NewQuantityPair({required this.bid, required this.offer});
  final int bid;
  final int offer;
}

Map<String, List<TradeOrder>> _mergeOrdersByFaction(
  Map<String, List<TradeOrder>> newByFaction,
  Map<String, List<TradeOrder>> carryByFaction, [
  Map<String, List<TradeOrder>> autoByFaction = const <String, List<TradeOrder>>{},
]) {
  if (newByFaction.isEmpty &&
      carryByFaction.isEmpty &&
      autoByFaction.isEmpty) {
    return const <String, List<TradeOrder>>{};
  }
  final factionIds = <String>{
    ...newByFaction.keys,
    ...carryByFaction.keys,
    ...autoByFaction.keys,
  }..removeWhere((id) => id.isEmpty);
  final result = <String, List<TradeOrder>>{};
  for (final factionId in factionIds) {
    final merged = <TradeOrder>[
      ...newByFaction[factionId] ?? const <TradeOrder>[],
      ...carryByFaction[factionId] ?? const <TradeOrder>[],
      ...autoByFaction[factionId] ?? const <TradeOrder>[],
    ];
    if (merged.isNotEmpty) result[factionId] = merged;
  }
  return result;
}

/// Returns a copy of [map] containing only entries keyed by ids in
/// [allowedFactionIds]. Used to filter carry-forwards to GP-only per
/// `SPEC/program/world-market-resolution.md` § Step E (minor/tribe
/// auto-offers do not carry forward).
Map<String, List<TradeOrder>> _restrictToFactions(
  Map<String, List<TradeOrder>> map,
  Set<String> allowedFactionIds,
) {
  if (map.isEmpty) return const <String, List<TradeOrder>>{};
  final filtered = <String, List<TradeOrder>>{};
  for (final entry in map.entries) {
    if (!allowedFactionIds.contains(entry.key)) continue;
    if (entry.value.isEmpty) continue;
    filtered[entry.key] = entry.value;
  }
  if (filtered.isEmpty) return const <String, List<TradeOrder>>{};
  return Map<String, List<TradeOrder>>.unmodifiable(filtered);
}

/// Computes non-Great-Power auto-offers for the current turn per
/// `SPEC/program/world-market-resolution.md` § Step A Gather (Step A.2) and
/// `SPEC/game/world-market.md` § Minor and tribe auto-sell. Returns an empty
/// map when [TurnResolverConfig.tileMapByRegion] is absent (legacy direct-
/// handler tests bypass the auto-transport / tile-map plumbing and rely on
/// `extractedByPlayerId` instead; in that mode there is no upstream tile data
/// to walk and the minor/tribe pool is intentionally empty so existing tests
/// continue to exercise the GP-only matching path).
Map<String, List<TradeOrder>> _computeMinorTribeAutoOffers({
  required Game game,
  required TurnResolverConfig config,
}) {
  final tileMaps = config.tileMapByRegion;
  if (tileMaps == null || tileMaps.isEmpty) {
    return const <String, List<TradeOrder>>{};
  }
  if (game.minorNations.isEmpty && game.tribes.isEmpty) {
    return const <String, List<TradeOrder>>{};
  }
  final connectivity = resolveNonGreatPowerConnectivity(
    game: game,
    tileMapByRegion: tileMaps,
    topology: config.topology,
  );
  if (connectivity.isEmpty) {
    return const <String, List<TradeOrder>>{};
  }
  return computeNonGreatPowerAutoOffers(
    game: game,
    tileMapByRegion: tileMaps,
    connectivityByFactionId: connectivity,
  );
}

/// Aggregates per-commodity the filled portion of this turn's
/// newly-submitted bids attributable to each faction (Refs #3115). The
/// matcher consumes newly-submitted bids at the head of each faction's
/// merged bid list (see `_mergeOrdersByFaction`), so the filled units
/// served to any given faction are allocated to its newly-submitted bids
/// first; carry-forward bids only receive fills once newly-submitted
/// bids are exhausted. Therefore:
///
///     filledNewBids[f, c] = min(submittedNewBids[f, c], filledTotal[f, c])
///
/// where `filledTotal[f, c]` is the sum of `FilledDeal.quantity` whose
/// `buyerFactionId == f` and `commodityId == c`. Summing across factions
/// yields `totalBid_new[c]` per
/// `SPEC/program/world-market-resolution.md` § Step E.
Map<CommodityId, int> _aggregateFilledNewBidsByCommodity({
  required Map<String, List<TradeOrder>> newBidsByFactionId,
  required List<FilledDeal> filledDeals,
}) {
  if (newBidsByFactionId.isEmpty || filledDeals.isEmpty) {
    return const <CommodityId, int>{};
  }
  final submittedNewByBuyerCommodity = <String, Map<CommodityId, int>>{};
  for (final entry in newBidsByFactionId.entries) {
    final byCommodity = <CommodityId, int>{};
    for (final order in entry.value) {
      byCommodity[order.commodityId] =
          (byCommodity[order.commodityId] ?? 0) + order.quantity;
    }
    if (byCommodity.isNotEmpty) {
      submittedNewByBuyerCommodity[entry.key] = byCommodity;
    }
  }
  if (submittedNewByBuyerCommodity.isEmpty) {
    return const <CommodityId, int>{};
  }
  final filledByBuyerCommodity = <String, Map<CommodityId, int>>{};
  for (final deal in filledDeals) {
    final byCommodity = filledByBuyerCommodity.putIfAbsent(
      deal.buyerFactionId,
      () => <CommodityId, int>{},
    );
    byCommodity[deal.commodityId] =
        (byCommodity[deal.commodityId] ?? 0) + deal.quantity;
  }
  final result = <CommodityId, int>{};
  for (final entry in submittedNewByBuyerCommodity.entries) {
    final buyerFilled = filledByBuyerCommodity[entry.key];
    if (buyerFilled == null) continue;
    for (final commodityEntry in entry.value.entries) {
      final submitted = commodityEntry.value;
      final filled = buyerFilled[commodityEntry.key] ?? 0;
      final attributable = filled <= submitted ? filled : submitted;
      if (attributable <= 0) continue;
      result[commodityEntry.key] =
          (result[commodityEntry.key] ?? 0) + attributable;
    }
  }
  return result;
}

/// Builds the per-commodity price-discovery aggregation pair used by
/// `_computeNextPrices` and `_buildActivity` (Refs #3115). Offers report
/// the submitted quantity unchanged; bids report only the filled portion
/// of newly-submitted bids per
/// `SPEC/program/world-market-resolution.md` § Step E.
Map<CommodityId, _NewQuantityPair> _buildPriceDiscoveryPairs({
  required Map<CommodityId, _NewQuantityPair> newQuantitiesByCommodity,
  required Map<CommodityId, int> filledNewBidsByCommodity,
}) {
  if (newQuantitiesByCommodity.isEmpty) {
    return const <CommodityId, _NewQuantityPair>{};
  }
  final result = <CommodityId, _NewQuantityPair>{};
  for (final entry in newQuantitiesByCommodity.entries) {
    final filledBid = filledNewBidsByCommodity[entry.key] ?? 0;
    result[entry.key] = _NewQuantityPair(
      bid: filledBid,
      offer: entry.value.offer,
    );
  }
  return result;
}

Map<CommodityId, _NewQuantityPair> _aggregateNewQuantitiesPerCommodity({
  required Map<String, List<TradeOrder>> newOffersByFactionId,
  required Map<String, List<TradeOrder>> newBidsByFactionId,
}) {
  final bid = <CommodityId, int>{};
  final offer = <CommodityId, int>{};
  for (final list in newOffersByFactionId.values) {
    for (final order in list) {
      offer[order.commodityId] =
          (offer[order.commodityId] ?? 0) + order.quantity;
    }
  }
  for (final list in newBidsByFactionId.values) {
    for (final order in list) {
      bid[order.commodityId] = (bid[order.commodityId] ?? 0) + order.quantity;
    }
  }
  final all = <CommodityId>{...offer.keys, ...bid.keys};
  final result = <CommodityId, _NewQuantityPair>{};
  for (final id in all) {
    result[id] = _NewQuantityPair(bid: bid[id] ?? 0, offer: offer[id] ?? 0);
  }
  return result;
}

List<Player> _applyDealsToPlayers({
  required List<Player> players,
  required List<FilledDeal> filledDeals,
  Map<String, double> firstRightTreasuryCreditByGpId = const <String, double>{},
}) {
  if (filledDeals.isEmpty && firstRightTreasuryCreditByGpId.isEmpty) {
    return players;
  }
  final treasuryById = <String, int>{};
  final stockpileById = <String, Stockpile>{};
  for (final p in players) {
    treasuryById[p.id] = p.treasury;
    stockpileById[p.id] = p.stockpile;
  }
  final knownPlayerIds = treasuryById.keys.toSet();
  for (final deal in filledDeals) {
    final notional = (deal.quantity * deal.pricePerUnit).round();
    final isGpBuyer = knownPlayerIds.contains(deal.buyerFactionId);
    final isGpSeller = knownPlayerIds.contains(deal.sellerFactionId);
    if (isGpBuyer) {
      treasuryById[deal.buyerFactionId] =
          (treasuryById[deal.buyerFactionId] ?? 0) - notional;
      stockpileById[deal.buyerFactionId] =
          (stockpileById[deal.buyerFactionId] ?? Stockpile.empty).applyDelta(
            deal.commodityId,
            deal.quantity,
          );
    }
    if (isGpSeller) {
      treasuryById[deal.sellerFactionId] =
          (treasuryById[deal.sellerFactionId] ?? 0) + notional;
      stockpileById[deal.sellerFactionId] =
          (stockpileById[deal.sellerFactionId] ?? Stockpile.empty).applyDelta(
            deal.commodityId,
            -deal.quantity,
          );
    }
  }
  // FRR D4: credit owning GPs the overseas-profit cut for minor/tribe
  // sales triggered when another GP buys from a purchased-tile offer.
  // The credit is additive on top of any GP-seller credit already applied
  // (the D4 path is only emitted when buyer != owning GP, so it never
  // double-credits the matcher's D2 path).
  if (firstRightTreasuryCreditByGpId.isNotEmpty) {
    for (final entry in firstRightTreasuryCreditByGpId.entries) {
      if (!knownPlayerIds.contains(entry.key)) continue;
      final credit = entry.value;
      if (credit <= 0.0) continue;
      treasuryById[entry.key] = (treasuryById[entry.key] ?? 0) + credit.round();
    }
  }
  return [
    for (final p in players)
      p.copyWith(
        treasury: treasuryById[p.id] ?? p.treasury,
        stockpile: stockpileById[p.id] ?? p.stockpile,
      ),
  ];
}

/// Computes the next-turn integer prices for every commodity with newly-
/// submitted activity this turn. Carries the prior integer price forward
/// for any commodity that did not see activity (preserves the existing
/// behavior of `_computeNextPrices` that returned a full prices map).
///
/// `SPEC/game/world-market.md` § Price discovery requires the persisted
/// price to be the integer floor of `PriceDiscovery.computeNextPrice`; the
/// floating-point math is retained internally for the supply/demand delta
/// but the world-market phase floors the result before storing it on
/// `WorldMarketState.prices`. Floor is non-negative because
/// `PriceDiscovery.computeNextPrice` returns a non-negative double (the
/// price floor of `basePrice * 0.30` is non-negative).
Map<CommodityId, int> _computeNextPrices({
  required Map<CommodityId, int> priorPrices,
  required Map<CommodityId, _NewQuantityPair> newQuantitiesByCommodity,
}) {
  final out = <CommodityId, int>{...priorPrices};
  for (final entry in newQuantitiesByCommodity.entries) {
    final basePrice = _basePriceForCommodityId(entry.key);
    final oldPrice = priorPrices[entry.key]?.toDouble() ?? basePrice.toDouble();
    final next = PriceDiscovery.computeNextPrice((
      oldPrice: oldPrice,
      basePrice: basePrice,
      newBidQuantity: entry.value.bid,
      newOfferQuantity: entry.value.offer,
    ));
    out[entry.key] = next.floor();
  }
  return out;
}

/// Resolves a commodity's integer base price from `ResourceRules.defaultRules`.
///
/// The price floor (`basePrice * priceFloorRatio`) anchors at the original
/// starting price per `SPEC/game/world-market.md` § Price discovery.
/// Manufactured commodities are not yet enumerated in
/// `ResourceRules.defaultMarketPrice` (raw resources only); for those, the
/// prior `WorldMarketState.prices` entry already encodes the seed value, so
/// returning `0` keeps the floor inert without re-clamping mid-game prices.
int _basePriceForCommodityId(CommodityId id) {
  final priceMap = ResourceRules.defaultRules.defaultMarketPrice;
  for (final entry in priceMap.entries) {
    if (entry.key.name == id) return entry.value;
  }
  return 0;
}

/// Result of [_validateCarryForwards]: surviving carry-forward orders that
/// pass the start-of-phase stockpile (offers) and trade cargo capacity
/// (bids) re-checks, plus the [MarketActivityNote] entries the phase
/// should attach to per-commodity `MarketActivity` for dropped orders.
class _CarryForwardValidationResult {
  const _CarryForwardValidationResult({
    required this.validOffersByFactionId,
    required this.validBidsByFactionId,
    required this.dropNotesByCommodity,
  });

  final Map<String, List<TradeOrder>> validOffersByFactionId;
  final Map<String, List<TradeOrder>> validBidsByFactionId;
  final Map<CommodityId, List<MarketActivityNote>> dropNotesByCommodity;
}

/// Re-validates carry-forward orders against the submitter's current
/// stockpile (offers) and trade cargo capacity (bids), implementing the
/// drop branch of `SPEC/game/world-market.md` § Order persistence and
/// `SPEC/program/world-market-resolution.md` § Step A Gather (A.3).
///
/// Per faction the carry-forwards are walked in original list order so
/// that earlier orders (higher submission priority) consume the available
/// stockpile/capacity first; later orders that would push the cumulative
/// kept total above the constraint are dropped and recorded as a
/// [MarketActivityNote]. Factions that are not present in
/// [stockpileByFactionId] / [tradeCapacityByFactionId] (e.g. minor/tribe
/// sellers whose offers persist through purchased-tile plumbing) keep all
/// their carry-forward orders unchanged — there is no GP-side constraint
/// to enforce on them in this slice.
_CarryForwardValidationResult _validateCarryForwards({
  required Map<String, List<TradeOrder>> carryForwardOffersByFactionId,
  required Map<String, List<TradeOrder>> carryForwardBidsByFactionId,
  required Map<String, Stockpile> stockpileByFactionId,
  required Map<String, int> tradeCapacityByFactionId,
}) {
  final validOffers = <String, List<TradeOrder>>{};
  final validBids = <String, List<TradeOrder>>{};
  final notesByCommodity = <CommodityId, List<MarketActivityNote>>{};

  void recordNote(MarketActivityNote note) {
    final list = notesByCommodity.putIfAbsent(
      note.commodityId,
      () => <MarketActivityNote>[],
    );
    list.add(note);
  }

  for (final entry in carryForwardOffersByFactionId.entries) {
    final factionId = entry.key;
    final orders = entry.value;
    if (orders.isEmpty) continue;
    final stockpile = stockpileByFactionId[factionId];
    if (stockpile == null) {
      validOffers[factionId] = List<TradeOrder>.from(orders);
      continue;
    }
    final cumulativeByCommodity = <CommodityId, int>{};
    final kept = <TradeOrder>[];
    for (final order in orders) {
      final available = stockpile.quantityOf(order.commodityId);
      final alreadyKept = cumulativeByCommodity[order.commodityId] ?? 0;
      if (alreadyKept + order.quantity <= available) {
        cumulativeByCommodity[order.commodityId] = alreadyKept + order.quantity;
        kept.add(order);
      } else {
        recordNote(
          MarketActivityNote(
            kind: MarketActivityNoteKind
                .carryForwardDroppedStockpileInsufficient,
            factionId: factionId,
            commodityId: order.commodityId,
            quantity: order.quantity,
          ),
        );
      }
    }
    if (kept.isNotEmpty) validOffers[factionId] = kept;
  }

  for (final entry in carryForwardBidsByFactionId.entries) {
    final factionId = entry.key;
    final orders = entry.value;
    if (orders.isEmpty) continue;
    final capacity = tradeCapacityByFactionId[factionId];
    if (capacity == null) {
      validBids[factionId] = List<TradeOrder>.from(orders);
      continue;
    }
    int cumulative = 0;
    final kept = <TradeOrder>[];
    for (final order in orders) {
      if (cumulative + order.quantity <= capacity) {
        cumulative += order.quantity;
        kept.add(order);
      } else {
        recordNote(
          MarketActivityNote(
            kind:
                MarketActivityNoteKind.carryForwardDroppedCargoInsufficient,
            factionId: factionId,
            commodityId: order.commodityId,
            quantity: order.quantity,
          ),
        );
      }
    }
    if (kept.isNotEmpty) validBids[factionId] = kept;
  }

  return _CarryForwardValidationResult(
    validOffersByFactionId: validOffers,
    validBidsByFactionId: validBids,
    dropNotesByCommodity: notesByCommodity,
  );
}

/// Forwards the matcher's per-commodity `MarketActivity.notes` (currently
/// `bidPartialFillTreasuryInsufficient` entries from the treasury-clamp
/// pass per Refs #3115) onto the phase-built `activity` map. The matcher
/// runs in isolation, so it carries its own notes inside
/// `DealMatchResult.activityByCommodityId`; the phase handler's
/// `_buildActivity` reassembles `MarketActivity` from filled deals and
/// submitted quantities and would otherwise drop these notes. We merge
/// them in by appending. Carry-forward drop notes from `_attachDropNotes`
/// continue to coexist on the same `MarketActivity` (drop notes are
/// added later in the pipeline and replace the list, so this helper
/// runs **before** `_attachDropNotes` and uses replacement-with-existing
/// semantics to preserve any prior notes when the drop-notes attacher
/// later appends).
void _attachMatcherNotes({
  required Map<CommodityId, MarketActivity> activity,
  required DealMatchResult matchResult,
}) {
  if (matchResult.activityByCommodityId.isEmpty) return;
  for (final entry in matchResult.activityByCommodityId.entries) {
    final matcherActivity = entry.value;
    if (matcherActivity.notes.isEmpty) continue;
    final commodity = entry.key;
    final existing = activity[commodity];
    if (existing == null) {
      activity[commodity] = MarketActivity(
        notes: List<MarketActivityNote>.unmodifiable(matcherActivity.notes),
      );
    } else {
      final combined = <MarketActivityNote>[
        ...existing.notes,
        ...matcherActivity.notes,
      ];
      activity[commodity] = MarketActivity(
        totalBidQuantity: existing.totalBidQuantity,
        totalOfferQuantity: existing.totalOfferQuantity,
        filledQuantity: existing.filledQuantity,
        priceChangePercent: existing.priceChangePercent,
        deals: existing.deals,
        notes: List<MarketActivityNote>.unmodifiable(combined),
      );
    }
  }
}

/// Merges carry-forward drop notes into `activity` per commodity by
/// **appending** to any notes already attached (matcher-emitted notes
/// such as `bidPartialFillTreasuryInsufficient` are preserved per Refs
/// #3115; prior-turn notes are not re-emitted). The final list is
/// unmodifiable to keep `MarketActivity` immutable. Any `deals` already
/// attached for the commodity (from `_buildActivity`) are preserved
/// verbatim — drop notes and ledger entries coexist on the same
/// `MarketActivity` per `SPEC/program/world-market-resolution.md` § Step F
/// Activity rollup.
void _attachDropNotes({
  required Map<CommodityId, MarketActivity> activity,
  required Map<CommodityId, List<MarketActivityNote>> notesByCommodity,
}) {
  if (notesByCommodity.isEmpty) return;
  for (final entry in notesByCommodity.entries) {
    if (entry.value.isEmpty) continue;
    final commodity = entry.key;
    final existing = activity[commodity];
    if (existing == null) {
      activity[commodity] = MarketActivity(
        notes: List<MarketActivityNote>.unmodifiable(entry.value),
      );
    } else {
      final combined = <MarketActivityNote>[
        ...existing.notes,
        ...entry.value,
      ];
      activity[commodity] = MarketActivity(
        totalBidQuantity: existing.totalBidQuantity,
        totalOfferQuantity: existing.totalOfferQuantity,
        filledQuantity: existing.filledQuantity,
        priceChangePercent: existing.priceChangePercent,
        deals: existing.deals,
        notes: List<MarketActivityNote>.unmodifiable(combined),
      );
    }
  }
}

Map<CommodityId, MarketActivity> _buildActivity({
  required DealMatchResult matchResult,
  required Map<CommodityId, _NewQuantityPair> newQuantitiesByCommodity,
  required Map<CommodityId, int> priorPrices,
  required Map<CommodityId, int> newPrices,
}) {
  final filledByCommodity = <CommodityId, int>{};
  final dealsByCommodity = <CommodityId, List<FilledDeal>>{};
  for (final deal in matchResult.filledDeals) {
    filledByCommodity[deal.commodityId] =
        (filledByCommodity[deal.commodityId] ?? 0) + deal.quantity;
    (dealsByCommodity[deal.commodityId] ??= <FilledDeal>[]).add(deal);
  }
  final commodityIds = <CommodityId>{
    ...newQuantitiesByCommodity.keys,
    ...filledByCommodity.keys,
  };
  final activity = <CommodityId, MarketActivity>{};
  for (final id in commodityIds) {
    final pair =
        newQuantitiesByCommodity[id] ??
        const _NewQuantityPair(bid: 0, offer: 0);
    final filled = filledByCommodity[id] ?? 0;
    final oldPrice = priorPrices[id] ?? 0;
    final newPrice = newPrices[id] ?? oldPrice;
    final percent = oldPrice > 0 ? (newPrice / oldPrice) - 1.0 : 0.0;
    final deals = dealsByCommodity[id];
    activity[id] = MarketActivity(
      totalBidQuantity: pair.bid,
      totalOfferQuantity: pair.offer,
      filledQuantity: filled,
      priceChangePercent: percent,
      deals: deals == null
          ? const <FilledDeal>[]
          : List<FilledDeal>.unmodifiable(deals),
    );
  }
  return activity;
}
