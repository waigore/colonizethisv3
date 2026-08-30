import 'package:colonizethis_data/colonizethis_data.dart';
import 'package:colonizethis_models/colonizethis_models.dart';

import 'player_view_core.dart';
import 'province_lookup.dart';

/// Resources that require prospecting before the player "knows" them.
/// SPEC/game/fog-and-exploration.md: iron, copper, tin, coal, silver, gold, gems, diamonds.
const Set<String> kProspectRequiredResourceIds = {
  'iron',
  'copper',
  'tin',
  'coal',
  'silver',
  'gold',
  'gems',
  'diamonds',
};

/// Resource commodity id to show in UI for the given visibility and
/// prospection state, or null to show no resource.
///
/// [authoritativeResourceId] is ground truth from the tile map /
/// [WorldState.resourceByTileKey]. SPEC/game/fog-and-exploration.md.
String? resourceIdVisibleToPlayer({
  required String? authoritativeResourceId,
  required VisibilityLevel visibility,
  required bool tileProspectedByPlayer,
}) {
  final id = authoritativeResourceId;
  if (id == null || id.isEmpty) return null;

  switch (visibility) {
    case VisibilityLevel.unknown:
      return null;
    case VisibilityLevel.fogged:
      if (kProspectRequiredResourceIds.contains(id)) {
        return tileProspectedByPlayer ? id : null;
      }
      return id;
    case VisibilityLevel.fullyVisible:
      if (kProspectRequiredResourceIds.contains(id)) {
        return tileProspectedByPlayer ? id : null;
      }
      return id;
  }
}

/// Convenience wrapper using [PlayerView] visibility and prospected-tile set.
String? resourceIdVisibleInPlayerView(
  PlayerView view,
  String tileKey,
  String? authoritativeResourceId,
) {
  return resourceIdVisibleToPlayer(
    authoritativeResourceId: authoritativeResourceId,
    visibility: view.visibilityForTile(tileKey),
    tileProspectedByPlayer: view.tileIsProspected(tileKey),
  );
}

/// True if [playerId] has at least one non-unknown tile containing [resourceId].
/// For prospect-required
/// resources (gold, silver, gems, diamonds, etc.), the tile must also be
/// prospected by that player. SPEC/game/tech-tree.md Discovery prerequisites.
bool hasRevealedResourceForPlayer(
  Game game,
  String playerId,
  String resourceId,
) {
  final ws = game.worldState;
  final visibility = ws.playerVisibilityByTile[playerId] ?? const {};
  final prospected = ws.playerProspectedTiles[playerId] ?? const <String>{};
  final needProspect = kProspectRequiredResourceIds.contains(resourceId);

  for (final e in ws.resourceByTileKey.entries) {
    if (e.value != resourceId) continue;
    final tileKey = e.key;
    final levelName = visibility[tileKey];
    if (levelName == null || levelName == 'unknown') continue;
    if (needProspect && !prospected.contains(tileKey)) continue;
    return true;
  }
  return false;
}

/// Whether [unit] should appear in another player's province UI for civilians.
///
/// The owner's units always count. Enemy [Spy] units never count. Other factions'
/// units require a [Unit.tileKey] and tile visibility other than [VisibilityLevel.unknown].
bool foreignCivilianVisibleToPlayer({
  required Unit unit,
  required String viewerPlayerId,
  required PlayerView view,
}) {
  if (unit.ownerId == viewerPlayerId) return true;
  if (isSpyUnit(unit.type)) return false;
  final tk = unit.tileKey;
  if (tk == null || tk.isEmpty) return false;
  return view.visibilityForTile(tk) != VisibilityLevel.unknown;
}

/// True when province panel may show tile-derived full-intel sections.
///
/// Sections gated by this predicate are Economic, Military, Civilian, and Naval.
/// Political ownership remains authoritative UI data.
///
/// Rules:
/// - Own province: always true.
/// - Foreign province + own Spy present: true.
/// - Foreign province + active Spy fog-decay timer (> 0): true.
/// - Otherwise: every tile in the province must be fully visible in [view].
bool provincePanelShowsFullTileDerivedIntel({
  required Game game,
  required PlayerView view,
  required String humanPlayerId,
  required String provinceId,
  Iterable<String>? provinceTileKeys,
}) {
  final province =
      view.provincesById[provinceId] ??
      game.worldState.tryGetProvince(provinceId);
  final ownerId = province?.ownerId;
  if (ownerId == humanPlayerId) {
    return true;
  }

  final isForeignProvince =
      ownerId != null && ownerId.isNotEmpty && ownerId != humanPlayerId;
  if (isForeignProvince &&
      _hasOwnSpyInProvince(view, humanPlayerId, provinceId)) {
    return true;
  }
  if (isForeignProvince) {
    final turnsLeft =
        game.worldState.spyRevealTurnsByPlayer[humanPlayerId]?[provinceId] ?? 0;
    if (turnsLeft > 0) {
      return true;
    }
  }

  final regionId = ProvinceId.regionIdFrom(provinceId);
  final tileKeys =
      (provinceTileKeys ??
              game
                  .worldState
                  .tileKeysByRegionAndProvince[regionId]?[provinceId] ??
              const <String>[])
          .toList();
  if (tileKeys.isEmpty) {
    return false;
  }
  for (final tk in tileKeys) {
    if (view.visibilityForTile(tk) != VisibilityLevel.fullyVisible) {
      return false;
    }
  }
  return true;
}

bool _hasOwnSpyInProvince(
  PlayerView view,
  String humanPlayerId,
  String provinceId,
) {
  for (final unit in view.ownUnits) {
    if (unit.ownerId != humanPlayerId) continue;
    if (!isSpyUnit(unit.type)) continue;
    if (unit.locationProvinceId == provinceId) return true;
  }
  return false;
}
