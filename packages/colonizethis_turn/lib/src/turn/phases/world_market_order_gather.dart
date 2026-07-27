import 'package:colonizethis_economy/colonizethis_economy.dart';
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

import '../turn_resolver_config.dart';

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

/// Splits submitted trade orders into offer vs bid maps, dropping non-positive
/// quantities (Refs #4039). Shared Step A gather logic for the phase handler.
({
  Map<String, List<TradeOrder>> offersByFactionId,
  Map<String, List<TradeOrder>> bidsByFactionId,
}) splitTradeOrdersByType(
  Map<String, List<TradeOrder>> tradeOrdersByPlayerId,
) {
  final offersByFactionId = <String, List<TradeOrder>>{};
  final bidsByFactionId = <String, List<TradeOrder>>{};
  for (final entry in tradeOrdersByPlayerId.entries) {
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
    if (offers.isNotEmpty) offersByFactionId[entry.key] = offers;
    if (bids.isNotEmpty) bidsByFactionId[entry.key] = bids;
  }
  return (
    offersByFactionId: offersByFactionId,
    bidsByFactionId: bidsByFactionId,
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

Map<String, List<TradeOrder>> computeMinorTribeTownManufacturingAutoOffers({
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
  final gpConnectivity = resolveConnectivity(
    game: game,
    tileMapByRegion: tileMaps,
    topology: config.topology,
  );
  final nonGpConnectivity = resolveNonGreatPowerConnectivity(
    game: game,
    tileMapByRegion: tileMaps,
    topology: config.topology,
  );
  final bonus = computeTownManufacturingBonusForGame(
    game: game,
    tileMapByRegion: tileMaps,
    gpConnectivityByPlayerId: gpConnectivity,
    nonGpConnectivityByFactionId: nonGpConnectivity,
  );
  return townManufacturingBonusToAutoOffers(
    game: game,
    bonusByFactionId: bonus.bonusByFactionId,
  );
}
