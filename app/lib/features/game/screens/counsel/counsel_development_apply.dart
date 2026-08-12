// Development Counsel Agree apply helpers. SPEC/ui/counsel-panel.md (Refs #4332).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/industry_counsel_api.dart'
    show DevelopmentCounselRecommendation;
import 'package:colonizethis_models/colonizethis_models.dart';
import 'package:colonizethis_orders/colonizethis_orders.dart';
import 'package:colonizethis_world/colonizethis_world.dart';

/// Returns a still-valid Engineer `build_port` [WorkOrder] for [recommendation].
WorkOrder? developmentCounselPortWorkOrderAfterAgree({
  required Game game,
  required String playerId,
  required Orders currentOrders,
  required MapTopology topology,
  required DevelopmentCounselRecommendation recommendation,
  Map<String, TileMapResult> tileMapByRegion = const {},
}) {
  final view = buildPlayerView(game, topology, playerId);
  final mapsOrNull = tileMapByRegion.isEmpty ? null : tileMapByRegion;
  final suggestions = suggestWorkOrders(
    view,
    game,
    topology,
    currentOrders,
    tileMapByRegion: mapsOrNull,
  );
  final matching = suggestions
      .where(
        (o) =>
            o.target == kWorkTargetBuildPort &&
            o.targetTileKey == recommendation.targetTileKey,
      )
      .toList()
    ..sort((a, b) => a.unitId.compareTo(b.unitId));
  if (matching.isEmpty) return null;
  final preferredUnitId = recommendation.unitId;
  if (preferredUnitId != null) {
    for (final order in matching) {
      if (order.unitId == preferredUnitId) return order;
    }
  }
  return matching.first;
}
