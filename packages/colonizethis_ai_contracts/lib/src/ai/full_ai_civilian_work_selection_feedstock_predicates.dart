// Old World feedstock-tile ownership predicates shared by build/purchase
// reservation and explore/prospect scoring. Extracted from the former
// `full_ai_civilian_work_selection` `part` cluster (Refs #4084 Slice A).

import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'package:colonizethis_world/colonizethis_world.dart';

import '../constants.dart';

/// True iff [playerId] owns at least one **Old World** province tile hosting a
/// resource in [feedstockIds] that is still unimproved (`improvementLevel < 1`)
/// — the `build_improvement` target a supplier (or seller) must keep an idle
/// Builder in the Old World to extract (Refs #2847 § H8-extraction supplier
/// Old World feedstock unit reservation). Old World is every region that is not
/// [kNewWorldRegionId], derived from the tile key alone so the scan works from
/// `WorldState.resourceByTileKey`. Read-only and deterministic.
bool ownsUnimprovedOldWorldFeedstockTile(
  Game game,
  String playerId,
  Set<String> feedstockIds,
) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  for (final entry in ws.resourceByTileKey.entries) {
    if (!feedstockIds.contains(entry.value)) continue;
    if (Unit.regionIdFromTileKey(entry.key) == kNewWorldRegionId) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (provinceId == null) continue;
    final province = ws.tryGetProvince(provinceId);
    if (province == null || province.ownerId != playerId) continue;
    if (ws.tileState.improvementLevel(entry.key) < 1) return true;
  }
  return false;
}

/// True when [tileKey] hosts a **mineral** resource in [feedstockIds] that
/// [playerId] has **not** prospected — the Explorer prospect target the H8
/// feedstock-extraction gate must route a unit onto before the Builder can
/// improve it. Read-only and deterministic over `(game, playerId, tileKey)`.
bool isUnprospectedMineralFeedstockTile(
  Game game,
  String playerId,
  String tileKey,
  Set<String> feedstockIds,
) {
  if (feedstockIds.isEmpty) return false;
  final resourceId = game.worldState.resourceByTileKey[tileKey];
  if (resourceId == null || !feedstockIds.contains(resourceId)) return false;
  if (!kMineralResourceIds.contains(resourceId)) return false;
  final prospected =
      game.worldState.playerProspectedTiles[playerId] ?? const <String>{};
  return !prospected.contains(tileKey);
}

/// True iff [playerId] owns at least one **Old World** province tile hosting an
/// **unprospected mineral** feedstock resource in [feedstockIds] — the
/// `prospect` target a supplier (or seller) must keep an idle Explorer in the
/// Old World to expose before the Builder can improve it (Refs #2847
/// § H8-extraction supplier Old World feedstock unit reservation). Read-only
/// and deterministic.
bool ownsUnprospectedOldWorldMineralFeedstockTile(
  Game game,
  String playerId,
  Set<String> feedstockIds,
) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  for (final entry in ws.resourceByTileKey.entries) {
    if (!feedstockIds.contains(entry.value)) continue;
    if (Unit.regionIdFromTileKey(entry.key) == kNewWorldRegionId) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (provinceId == null) continue;
    final province = ws.tryGetProvince(provinceId);
    if (province == null || province.ownerId != playerId) continue;
    if (isUnprospectedMineralFeedstockTile(
      game,
      playerId,
      entry.key,
      feedstockIds,
    )) {
      return true;
    }
  }
  return false;
}
