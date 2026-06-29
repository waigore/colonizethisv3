import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../turn_resolver_config.dart';

// World-market order gathering / merge / restriction helpers (Refs #2990,
// #3416 part-of -> explicit library). This is a proper library imported by
// `world_market_phase.dart`; the helpers below are package-visible (no `_`
// prefix) so the phase handler can reference them, and stay unexported from
// the package barrel so the public API is unchanged.

Map<String, List<TradeOrder>> mergeOrdersByFaction(
  Map<String, List<TradeOrder>> newByFaction,
  Map<String, List<TradeOrder>> carryByFaction, [
  Map<String, List<TradeOrder>> autoByFaction =
      const <String, List<TradeOrder>>{},
]) {
  if (newByFaction.isEmpty && carryByFaction.isEmpty && autoByFaction.isEmpty) {
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
Map<String, List<TradeOrder>> restrictToFactions(
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
/// Bundles the start-of-phase per-GP market inputs computed in a single
/// player pass: trade cargo capacity, stockpile, raw settlement treasury, and
/// the per-buyer (non-negative) treasury budget. See
/// [computeStartOfPhaseCapacities].
typedef StartOfPhaseCapacities = ({
  Map<String, int> tradeCapacityByFactionId,
  Map<String, Stockpile> stockpileByFactionId,
  Map<String, int> treasuryByFactionId,
  Map<String, int> treasuryBudgetByBuyerFactionId,
});

/// Computes the start-of-phase trade cargo capacity, stockpile, raw treasury,
/// and per-buyer treasury budget for each GP in [gameForMarket] in a single
/// player pass (Refs #3565), then injects the lock-recovery minor synthetic
/// cargo/treasury budgets (Refs #2924 F15). Trade capacity per GP is
/// `max(0, cargoHoldsForHomeFleet − overseasExtractionShippedTonnage)` per
/// `SPEC/game/world-market.md` § Cargo; the buyer budget clamps negative
/// treasuries to `0` per `SPEC/program/world-market-resolution.md` § Step C.
StartOfPhaseCapacities computeStartOfPhaseCapacities({
  required Game gameForMarket,
  required Map<String, int> extractionTonnageByPlayerId,
  required Map<String, List<TradeOrder>> lockRecoveryMinorBidsByFactionId,
}) {
  final fleetsByIdStartOfPhase = fleetsByIdForWorld(gameForMarket.worldState);
  final tradeCapacityByFactionId = <String, int>{};
  final stockpileByFactionId = <String, Stockpile>{};
  final treasuryByFactionId = <String, int>{};
  final treasuryBudgetByBuyerFactionId = <String, int>{};
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
  return (
    tradeCapacityByFactionId: tradeCapacityByFactionId,
    stockpileByFactionId: stockpileByFactionId,
    treasuryByFactionId: treasuryByFactionId,
    treasuryBudgetByBuyerFactionId: treasuryBudgetByBuyerFactionId,
  );
}

Map<String, List<TradeOrder>> computeMinorTribeAutoOffers({
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
