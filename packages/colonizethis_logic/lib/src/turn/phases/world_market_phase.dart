import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../../diplomacy/diplomacy_relation_lookup.dart'
    show ftpPairKeysFromGame, getRelation;
import '../../economy/sea_transport.dart';
import '../../economy/world_market/deal_matcher.dart';
import '../../economy/world_market/first_right_credits.dart';
import '../../economy/world_market/price_discovery.dart';
import '../../economy/world_market/purchased_tile_index.dart';
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
///    `carryForwardBidsByFactionId` (re-validation against current
///    stockpile/cargo per `SPEC/game/world-market.md` § Order persistence
///    will land in a follow-up commit alongside the validator's
///    re-entry hook).
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

  final mergedOffersByFactionId = _mergeOrdersByFaction(
    newOffersByFactionId,
    priorMarket.carryForwardOffersByFactionId,
  );
  final mergedBidsByFactionId = _mergeOrdersByFaction(
    newBidsByFactionId,
    priorMarket.carryForwardBidsByFactionId,
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
    final updatedMarket = priorMarket.copyWith(
      lastTurnActivity: Map<CommodityId, MarketActivity>.unmodifiable(activity),
      carryForwardOffersByFactionId: const <String, List<TradeOrder>>{},
      carryForwardBidsByFactionId: const <String, List<TradeOrder>>{},
    );
    return TurnPhaseStepContinue(
      acc.copyWith(game: game.copyWith(worldMarketState: updatedMarket)),
    );
  }

  final fleetsByIdStartOfPhase = fleetsByIdForWorld(game.worldState);
  final tradeCapacityByFactionId = <String, int>{};
  final extractionTonnageByPlayerId =
      acc.overseasExtractionShippedTonnageByPlayerId;
  for (final player in game.players) {
    final homeFleetHolds = cargoHoldsForHomeFleet(
      game,
      player.id,
      fleetsById: fleetsByIdStartOfPhase,
    );
    final shippedByExtraction =
        extractionTonnageByPlayerId[player.id] ?? 0;
    final tradeCapacity = homeFleetHolds - shippedByExtraction;
    tradeCapacityByFactionId[player.id] = tradeCapacity > 0 ? tradeCapacity : 0;
  }

  final ftpPairKeys = ftpPairKeysFromGame(game);
  final purchasedTileIndex = PurchasedTileIndex.fromGame(game);

  final matchInputs = (
    offersByFactionId: mergedOffersByFactionId,
    bidsByFactionId: mergedBidsByFactionId,
    tradeCapacityByFactionId: tradeCapacityByFactionId,
    pricesByCommodityId: priorMarket.prices,
    ftpPairKeys: ftpPairKeys,
    purchasedTileIndex: purchasedTileIndex,
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

  final newPrices = _computeNextPrices(
    priorPrices: priorMarket.prices,
    newQuantitiesByCommodity: newQuantitiesByCommodity,
  );

  final activity = _buildActivity(
    matchResult: matchResult,
    newQuantitiesByCommodity: newQuantitiesByCommodity,
    priorPrices: priorMarket.prices,
    newPrices: newPrices,
  );

  final updatedMarket = priorMarket.copyWith(
    prices: Map<CommodityId, double>.unmodifiable(newPrices),
    lastTurnActivity: Map<CommodityId, MarketActivity>.unmodifiable(activity),
    carryForwardOffersByFactionId: matchResult.unfilledOffersByFactionId,
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
  Map<String, List<TradeOrder>> carryByFaction,
) {
  if (newByFaction.isEmpty && carryByFaction.isEmpty) {
    return const <String, List<TradeOrder>>{};
  }
  final factionIds = <String>{...newByFaction.keys, ...carryByFaction.keys}
    ..removeWhere((id) => id.isEmpty);
  final result = <String, List<TradeOrder>>{};
  for (final factionId in factionIds) {
    final merged = <TradeOrder>[
      ...newByFaction[factionId] ?? const <TradeOrder>[],
      ...carryByFaction[factionId] ?? const <TradeOrder>[],
    ];
    if (merged.isNotEmpty) result[factionId] = merged;
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

Map<CommodityId, double> _computeNextPrices({
  required Map<CommodityId, double> priorPrices,
  required Map<CommodityId, _NewQuantityPair> newQuantitiesByCommodity,
}) {
  final out = <CommodityId, double>{...priorPrices};
  for (final entry in newQuantitiesByCommodity.entries) {
    final basePrice = _basePriceForCommodityId(entry.key);
    final oldPrice = priorPrices[entry.key] ?? basePrice.toDouble();
    final next = PriceDiscovery.computeNextPrice((
      oldPrice: oldPrice,
      basePrice: basePrice,
      newBidQuantity: entry.value.bid,
      newOfferQuantity: entry.value.offer,
    ));
    out[entry.key] = next;
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

Map<CommodityId, MarketActivity> _buildActivity({
  required DealMatchResult matchResult,
  required Map<CommodityId, _NewQuantityPair> newQuantitiesByCommodity,
  required Map<CommodityId, double> priorPrices,
  required Map<CommodityId, double> newPrices,
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
    final oldPrice = priorPrices[id] ?? 0.0;
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
