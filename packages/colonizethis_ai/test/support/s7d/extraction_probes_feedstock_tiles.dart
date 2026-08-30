// Feedstock tile ownership / build-improvement probes (Refs #2847 / #4602 Slice E).
// Split from `extraction_probes.dart`.

import 'package:colonizethis_ai/src/planning/planning_imports.dart'
    show ownsFeedstockResourceTile;
import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_logic/colonizethis_logic.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

/// True iff [playerId] owns at least one province tile hosting one of
/// [feedstockIds] at **any** improvement level (improved or unimproved).
bool ownsFeedstockResourceTileAnyLevel(
  Game game,
  String playerId,
  Set<String> feedstockIds,
) => ownsFeedstockResourceTile(game, playerId, feedstockIds);

bool hasValidBuildImprovementOnUnimprovedFeedstockTile(
  Game game,
  MapTopology topology,
  String playerId,
  Set<String> feedstockIds, {
  Map<String, TileMapResult>? tileMapByRegion,
}) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  for (final unit in allUnitsFromWorld(ws)) {
    if (unit.ownerId != playerId) continue;
    if (unit.type != kUnitTypeBuilder) continue;
    if (unit.currentWork != null) continue;
    final valid = getValidWorkOrderTileKeys(
      game,
      topology,
      playerId,
      unit.id,
      kWorkTargetBuildImprovement,
      const Orders(),
      tileMapByRegion: tileMapByRegion,
    );
    for (final tileKey in valid) {
      final resourceId = ws.resourceByTileKey[tileKey];
      if (resourceId == null || !feedstockIds.contains(resourceId)) continue;
      if (ws.tileState.improvementLevel(tileKey) < 1) return true;
    }
  }
  return false;
}
