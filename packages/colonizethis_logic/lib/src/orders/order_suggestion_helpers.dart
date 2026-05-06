import 'package:colonizethis_models/colonizethis_models.dart';

import '../diplomacy/diplomacy_resolver.dart';
import '../world/province_lookup.dart';

/// Shared helpers for order suggestion. SPEC/ai/ai-architecture.md.
/// Used by order_suggestion and AI planners.

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
List<T> filterOrdersByDiplomacy<T>(
  Game game,
  String playerId,
  List<T> orders,
  String Function(T order) destinationProvinceId,
) {
  final provinceOwner = getProvinceOwnerMap(game);
  final filtered = <T>[];
  for (final m in orders) {
    final destOwner = provinceOwner[destinationProvinceId(m)];
    if (destOwner == null || destOwner == playerId) {
      filtered.add(m);
      continue;
    }
    final rel = getRelation(game, playerId, destOwner);
    if (rel != null && rel.atPeace) continue;
    if (rel == null) {
      if (game.minorNations.any((mn) => mn.id == destOwner)) continue;
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
  List<ArmyMoveOrder> orders,
) => filterOrdersByDiplomacy(
  game,
  playerId,
  orders,
  (ArmyMoveOrder o) => o.destinationProvinceId,
);
