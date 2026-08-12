// Development Counsel Agree apply helpers. SPEC/ui/counsel-panel.md (Refs #4332).
// Uses per-unit work-tile candidacy (not broad suggestWorkOrders; Refs #2133).

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
  final engineers = idleEngineersForDevelopmentAssign(
    game: game,
    playerId: playerId,
    currentOrders: currentOrders,
  );
  if (engineers.isEmpty) return null;

  final view = buildPlayerView(game, topology, playerId);
  final mapsOrNull = tileMapByRegion.isEmpty ? null : tileMapByRegion;
  final tileKey = recommendation.targetTileKey;

  bool tileValidFor(String unitId) {
    final valid = getValidWorkOrderTileKeysWithVisibility(
      game: game,
      topology: topology,
      view: view,
      unitId: unitId,
      workTarget: kWorkTargetBuildPort,
      currentOrders: currentOrders,
      tileMapByRegion: mapsOrNull,
    );
    return valid.contains(tileKey);
  }

  WorkOrder orderFor(String unitId) => WorkOrder(
    unitId: unitId,
    target: kWorkTargetBuildPort,
    targetTileKey: tileKey,
  );

  final preferredUnitId = recommendation.unitId;
  if (preferredUnitId != null) {
    for (final engineer in engineers) {
      if (engineer.id == preferredUnitId && tileValidFor(preferredUnitId)) {
        return orderFor(preferredUnitId);
      }
    }
  }
  for (final engineer in engineers) {
    if (tileValidFor(engineer.id)) return orderFor(engineer.id);
  }
  return null;
}
