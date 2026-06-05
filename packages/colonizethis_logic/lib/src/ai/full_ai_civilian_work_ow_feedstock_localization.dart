import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import '../constants.dart';
import '../orders/orders_application_helpers.dart' show isMineralEligibleTile;
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

/// True iff [playerId] owns at least one **idle** Explorer unit
/// (`currentWork == null`) standing in the **same Old World province** as one
/// of the player's owned **unprospected mineral** feedstock tiles in
/// [feedstockIds] (Refs #2847 § H8-extraction Old World mineral feedstock
/// prospect localization).
///
/// Localizes the residual `iron`-extraction break one step further than
/// [hasIdleExplorerUnit]: the prior counter proved a supplier holds an idle
/// Explorer on every gate-active turn yet never prospects its Old World `iron`
/// tile. A `prospect` work order is only generated for an Explorer that can
/// reach the feedstock tile — the supplier's own province (`prospect`
/// candidate generation in `order_suggestion_work_explorer.dart` requires the
/// unit's province / single-hop reach) — and the Old World feedstock
/// reservation (`full_ai_civilian_work_selection.dart`) reserves the
/// lexicographically-smallest idle Explorer **without repositioning it**. This
/// predicate therefore splits the break:
///
///   * **true on gate turns** → an idle Explorer is already co-located with the
///     unprospected feedstock province, so a `prospect` candidate *should*
///     generate; the residual is the candidate-generation gate (mineral-tile
///     eligibility / validator) or selection ranking, not positioning.
///   * **false while [hasIdleExplorerUnit] is true** → the player's idle
///     Explorers are never positioned on the feedstock province, so no
///     `prospect` candidate generates and the reserved Explorer idles; the
///     residual is reservation positioning (the reservation never moves an
///     Explorer onto the Old World feedstock province).
///
/// Read-only and deterministic over `(game, playerId, feedstockIds)`.
bool ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile(
  Game game,
  String playerId,
  Set<String> feedstockIds,
) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  final prospected = ws.playerProspectedTiles[playerId] ?? const <String>{};
  final feedstockProvinceIds = <String>{};
  for (final entry in ws.resourceByTileKey.entries) {
    if (!feedstockIds.contains(entry.value)) continue;
    if (!kMineralResourceIds.contains(entry.value)) continue;
    if (Unit.regionIdFromTileKey(entry.key) == kNewWorldRegionId) continue;
    if (prospected.contains(entry.key)) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (provinceId == null) continue;
    final province = tryGetProvince(ws, provinceId);
    if (province == null || province.ownerId != playerId) continue;
    feedstockProvinceIds.add(provinceId);
  }
  if (feedstockProvinceIds.isEmpty) return false;
  for (final unit in allUnitsFromWorld(ws)) {
    if (unit.ownerId != playerId) continue;
    if (!isExplorerUnit(unit.type)) continue;
    if (unit.currentWork != null) continue;
    if (feedstockProvinceIds.contains(unit.locationProvinceId)) return true;
  }
  return false;
}

/// True iff [playerId] owns at least one **idle** Explorer
/// (`currentWork == null`) standing in the **same Old World province** as one
/// of the player's owned **unprospected mineral** feedstock tiles in
/// [feedstockIds] that **also** passes the live mineral-eligibility terrain
/// check ([isMineralEligibleTile] under [tileMapByRegion]) (Refs #2847
/// § H8-extraction Old World mineral feedstock prospect localization).
///
/// Splits the residual one gate finer than
/// [ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile]:
/// that predicate proved an idle Explorer is already co-located with an owned,
/// unprospected Old World mineral feedstock province on the gate-active turns,
/// yet the supplier still never prospects (`prospect` candidate generation
/// returns no candidate). The next gate the `prospect` candidate must clear in
/// `order_suggestion_work_explorer.dart` (`_allAcceptedProspectTilesInProvince`)
/// is [isMineralEligibleTile], which — unlike the resource-only feedstock scan
/// in the prior predicate — additionally requires the tile's **live terrain**
/// (from [tileMapByRegion]) to be prospectable. This predicate therefore
/// distinguishes:
///
///   * **true on gate turns** → the co-located feedstock tile passes the
///     mineral-eligibility terrain check, so a `prospect` candidate *should*
///     generate; the residual is **downstream** of eligibility (validator
///     material cost / visibility precheck or selection ranking).
///   * **false while
///     [ownsIdleExplorerColocatedWithUnprospectedOldWorldMineralFeedstockTile]
///     is true** → the co-located feedstock tile fails [isMineralEligibleTile]
///     under the live terrain map (for example the owned `iron` resource sits
///     on non-prospectable terrain), so no `prospect` candidate ever generates;
///     the residual is **terrain mineral-eligibility** at candidate generation,
///     not budget, positioning, or the validator.
///
/// Read-only and deterministic over
/// `(game, playerId, feedstockIds, tileMapByRegion)`.
bool ownsIdleExplorerColocatedWithMineralEligibleUnprospectedOldWorldFeedstockTile(
  Game game,
  String playerId,
  Set<String> feedstockIds,
  Map<String, TileMapResult>? tileMapByRegion,
) {
  if (feedstockIds.isEmpty) return false;
  final ws = game.worldState;
  final prospected = ws.playerProspectedTiles[playerId] ?? const <String>{};
  final feedstockProvinceIds = <String>{};
  for (final entry in ws.resourceByTileKey.entries) {
    if (!feedstockIds.contains(entry.value)) continue;
    if (!kMineralResourceIds.contains(entry.value)) continue;
    if (Unit.regionIdFromTileKey(entry.key) == kNewWorldRegionId) continue;
    if (prospected.contains(entry.key)) continue;
    if (!isMineralEligibleTile(game, tileMapByRegion, entry.key)) continue;
    final provinceId = Unit.provinceIdFromTileKey(entry.key);
    if (provinceId == null) continue;
    final province = tryGetProvince(ws, provinceId);
    if (province == null || province.ownerId != playerId) continue;
    feedstockProvinceIds.add(provinceId);
  }
  if (feedstockProvinceIds.isEmpty) return false;
  for (final unit in allUnitsFromWorld(ws)) {
    if (unit.ownerId != playerId) continue;
    if (!isExplorerUnit(unit.type)) continue;
    if (unit.currentWork != null) continue;
    if (feedstockProvinceIds.contains(unit.locationProvinceId)) return true;
  }
  return false;
}
