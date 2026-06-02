import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../diplomacy/diplomacy_resolver.dart';
import '../world/player_view.dart';
import '../world/province_lookup.dart';
import '../world/sea_reachable_provinces.dart';
import '../world/tile_key_coordinates.dart';

/// Shared helpers for order suggestion. SPEC/ai/ai-architecture.md.
/// Used by order_suggestion and AI planners.

/// Faction ids the player may target with diplomatic suggestions.
/// SPEC/program/order-suggestions.md § Diplomatic orders (visibility).
Set<String> knownDiplomaticTargetFactionIds({
  required PlayerView view,
  required Game game,
  required MapTopology topology,
}) {
  final knownFactionIds = <String>{};
  final playerId = view.playerId;

  for (final rel in game.diplomacyRelations) {
    if (rel.factionId1 == playerId) {
      knownFactionIds.add(rel.factionId2);
    } else if (rel.factionId2 == playerId) {
      knownFactionIds.add(rel.factionId1);
    }
  }

  for (final entry in view.visibilityByTile.entries) {
    if (entry.value == VisibilityLevel.unknown) continue;
    final parsed = parseTileKeyCoordinates(entry.key);
    if (parsed == null) continue;
    final regionId = parsed.regionId;
    final provinceLocalId = parsed.provinceLocalId;
    final provinceId = ProvinceId.full(regionId, provinceLocalId);
    final province = view.provinceByRegionAndId(regionId, provinceId);
    final ownerId = province?.ownerId;
    if (ownerId != null && ownerId != playerId) {
      knownFactionIds.add(ownerId);
    }
  }

  final anchorProvinces = <String>{};
  for (final p in view.provincesById.entries) {
    if (p.value.ownerId == playerId) anchorProvinces.add(p.key);
  }
  for (final u in view.ownUnits) {
    if (u.locationProvinceId.isNotEmpty) {
      anchorProvinces.add(u.locationProvinceId);
    }
  }
  final seaReachableNw = reachableNonOwnedProvinceIdsViaSeas(
    topology,
    anchorProvinces,
    view,
    regionIdFilter: kRegionNewWorld,
  );
  for (final provId in seaReachableNw) {
    final ownerId = view.provincesById[provId]?.ownerId;
    if (ownerId == null || ownerId == playerId) continue;
    if (game.tribes.any((t) => t.id == ownerId)) {
      knownFactionIds.add(ownerId);
    }
  }

  return knownFactionIds;
}

/// Sea-reachable unowned New World provinces for colonial explore targeting.
/// SPEC/program/order-suggestions.md § GP↔Tribe colonial intel (Refs #2509).
List<String> colonialIntelExploreProvinceIdsSorted({
  required PlayerView view,
  required MapTopology topology,
}) {
  final anchorProvinces = <String>{};
  for (final p in view.provincesById.entries) {
    if (p.value.ownerId == view.playerId) anchorProvinces.add(p.key);
  }
  for (final u in view.ownUnits) {
    if (u.locationProvinceId.isNotEmpty) {
      anchorProvinces.add(u.locationProvinceId);
    }
  }
  final reachable = reachableNonOwnedProvinceIdsViaSeas(
    topology,
    anchorProvinces,
    view,
    regionIdFilter: kRegionNewWorld,
  );
  final sorted = reachable.toList()..sort();
  return sorted;
}

/// Deterministic sort rank for merchant [purchase_land] tile probes (lower = earlier).
/// NW tribe/minor tiles first to accelerate colonial acquisition (Refs #2509).
int merchantPurchaseLandCandidateSortRank({
  required Game game,
  required String tileKey,
}) {
  final provId = Unit.provinceIdFromTileKey(tileKey);
  if (provId == null || provId.isEmpty) return 90;
  final regionId = ProvinceId.regionIdFrom(provId);
  final ownerId = tryGetProvince(game.worldState, provId)?.ownerId;
  if (ownerId == null || ownerId.isEmpty) return 80;
  final playerIds = {for (final p in game.players) p.id};
  if (playerIds.contains(ownerId)) return 70;
  final isTribe = game.tribes.any((t) => t.id == ownerId);
  final isMinor = game.minorNations.any((m) => m.id == ownerId);
  if (regionId == kNewWorldRegionId) {
    if (isTribe) return 0;
    if (isMinor) return 1;
    return 2;
  }
  if (isTribe) return 3;
  if (isMinor) return 4;
  return 5;
}

/// True when [orders] contains a draft [WorkOrder] for [unitId] for [playerId].
/// SPEC/program/order-suggestions.md § Pre-assign gating (Refs #2133).
bool playerHasPendingWorkOrderForUnit(
  Orders orders,
  String playerId,
  String unitId,
) {
  for (final o in orders.workOrdersByPlayerId[playerId] ?? const []) {
    if (o.unitId == unitId) return true;
  }
  return false;
}

/// Builds a map from full province id (regionId|localId) to owner faction id.
/// Used by AI to filter move orders by diplomacy.
Map<String, String> getProvinceOwnerMap(Game game) {
  final out = <String, String>{};
  for (final p in allProvinces(game.worldState)) {
    if (p.ownerId != null && p.ownerId!.isNotEmpty) {
      final key = ProvinceId.isPrefixed(p.id)
          ? p.id
          : ProvinceId.full(p.regionId, p.id);
      out[key] = p.ownerId!;
    }
  }
  return out;
}

/// Filters orders to those allowed by diplomacy: no move into a province owned by
/// a faction at peace with [playerId], or into Minor territory without war.
///
/// [destinationProvinceId] returns the destination province id for each order
/// (full id: regionId|localId).
bool _hasPendingDeclareWarToward(
  Orders draftOrders,
  String playerId,
  String targetFactionId,
) {
  for (final o
      in draftOrders.diplomaticOrdersByPlayerId[playerId] ?? const []) {
    if (o.type == DiplomaticOrderType.declareWar &&
        o.targetFactionId == targetFactionId) {
      return true;
    }
  }
  return false;
}

List<T> filterOrdersByDiplomacy<T>(
  Game game,
  String playerId,
  List<T> orders,
  String Function(T order) destinationProvinceId, {
  Orders? draftOrders,
}) {
  final provinceOwner = getProvinceOwnerMap(game);
  // Single-pass minor ids (Refs #2394): avoid O(orders × minors) scans per row.
  final minorNationIds = <String>{for (final mn in game.minorNations) mn.id};
  final filtered = <T>[];
  for (final m in orders) {
    final destOwner = provinceOwner[destinationProvinceId(m)];
    if (destOwner == null || destOwner == playerId) {
      filtered.add(m);
      continue;
    }
    if (draftOrders != null &&
        _hasPendingDeclareWarToward(draftOrders, playerId, destOwner)) {
      filtered.add(m);
      continue;
    }
    final rel = getRelation(game, playerId, destOwner);
    if (rel != null && rel.atPeace) continue;
    if (rel == null && minorNationIds.contains(destOwner)) {
      continue;
    }
    filtered.add(m);
  }
  return filtered;
}

/// Filters move orders to those allowed by diplomacy: no move into province of
/// a faction at peace with [playerId], or into Minor territory without war.
/// Civilian [MoveOrder] legality is enforced by [MoveValidator] (tile occupancy,
/// visibility, etc.), not by diplomacy-based province filtering — e.g. Spy may
/// enter GP-controlled tiles without war. See issue #1877.
List<MoveOrder> filterMoveOrdersByDiplomacy(
  Game game,
  String playerId,
  List<MoveOrder> orders,
) => List<MoveOrder>.from(orders);

/// Same diplomacy filter as [filterMoveOrdersByDiplomacy] for [ArmyMoveOrder].
List<ArmyMoveOrder> filterArmyMoveOrdersByDiplomacy(
  Game game,
  String playerId,
  List<ArmyMoveOrder> orders, {
  Orders? draftOrders,
}) => filterOrdersByDiplomacy(
  game,
  playerId,
  orders,
  (ArmyMoveOrder o) => o.destinationProvinceId,
  draftOrders: draftOrders,
);
