import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../world/province_lookup.dart';
import '../world/unit_lookup.dart';

/// True iff [playerId] owns at least one **Old World** province tile hosting a
/// **mineral** feedstock resource in [feedstockIds] that the player **has**
/// prospected (`playerProspectedTiles` contains the tile) — the localization
/// complement to the unprospected predicate in
/// `full_ai_civilian_work_selection.dart`
/// (Refs #2847 § H8-extraction Old World mineral feedstock prospect
/// localization).
///
/// Splits the supplier `iron`-extraction break: the H8 castIron supplier owns
/// an unimproved Old World `iron` mineral tile every gate-active turn yet never
/// holds `iron`, so either the Explorer never **prospects** the tile (this
/// predicate stays false) or the tile is prospected but the Builder never
/// **improves** it (this predicate is true while `iron` held stays `0`). A
/// `prospect` is required before `build_improvement` accepts a mineral tile
/// (`work_order_target_prechecks.dart` § "Mineral tile must be prospected
/// first"), so the two outcomes localize the residual to the Explorer-prospect
/// stage versus the Builder-improvement stage respectively. Read-only and
/// deterministic over `(game, playerId, feedstockIds)`.
bool ownsProspectedOldWorldMineralFeedstockTile(
  Game game,
  String playerId,
  Set<String> feedstockIds,
) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  final prospected = ws.playerProspectedTiles[playerId] ?? const <String>{};
  if (prospected.isEmpty) return false;
  for (final entry in ws.resourceByTileKey.entries) {
    if (!feedstockIds.contains(entry.value)) continue;
    if (!kMineralResourceIds.contains(entry.value)) continue;
    if (Unit.regionIdFromTileKey(entry.key) == kNewWorldRegionId) continue;
    if (!prospected.contains(entry.key)) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (provinceId == null) continue;
    final province = tryGetProvince(ws, provinceId);
    if (province == null || province.ownerId != playerId) continue;
    return true;
  }
  return false;
}

/// True iff [playerId] owns at least one **idle** Explorer unit
/// (`currentWork == null`) — i.e. an Explorer the Full-AI civilian work
/// selection could reserve this turn to prospect an Old World mineral feedstock
/// tile (Refs #2847 § H8-extraction Old World mineral feedstock prospect
/// localization).
///
/// The Old World feedstock unit reservation only holds back an **idle**
/// Explorer; a supplier whose Explorers are all busy (for example dispatched to
/// multi-turn New World exploration) has none to reserve, so its Old World
/// `iron` mineral tile is never prospected and `castIron` never becomes
/// feasible. A near-zero count on gate-active turns therefore localizes the
/// residual to Explorer availability rather than to candidate generation or
/// improvement. Read-only scan over the player's units; deterministic over
/// `(game, playerId)`.
bool hasIdleExplorerUnit(Game game, String playerId) {
  for (final unit in allUnitsFromWorld(game.worldState)) {
    if (unit.ownerId != playerId) continue;
    if (!isExplorerUnit(unit.type)) continue;
    if (unit.currentWork == null) return true;
  }
  return false;
}
