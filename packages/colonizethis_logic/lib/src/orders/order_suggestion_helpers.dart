import 'package:colonizethis_models/colonizethis_models.dart';

import '../diplomacy/diplomacy_resolver.dart';

/// Shared helpers for order suggestion. SPEC/ai/ai-architecture.md.
/// Used by order_suggestion and AI planners.

/// Builds a map from full province id (regionId|localId) to owner faction id.
/// Used by AI to filter move orders by diplomacy.
Map<String, String> getProvinceOwnerMap(Game game) {
  final out = <String, String>{};
  for (final p in game.worldState.oldWorld.provinces) {
    if (p.ownerId != null && p.ownerId!.isNotEmpty) {
      final key = ProvinceId.full(p.regionId, ProvinceId.localIdFrom(p.id));
      out[key] = p.ownerId!;
    }
  }
  for (final p in game.worldState.newWorld.provinces) {
    if (p.ownerId != null && p.ownerId!.isNotEmpty) {
      final key = ProvinceId.full(p.regionId, ProvinceId.localIdFrom(p.id));
      out[key] = p.ownerId!;
    }
  }
  return out;
}

/// Filters move orders to those allowed by diplomacy: no move into province of
/// a faction at peace with [playerId], or into Minor territory without war.
List<MoveOrder> filterMoveOrdersByDiplomacy(
  Game game,
  String playerId,
  List<MoveOrder> orders,
) {
  final provinceOwner = getProvinceOwnerMap(game);
  final filtered = <MoveOrder>[];
  for (final m in orders) {
    final destOwner = provinceOwner[m.destinationProvinceId];
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
