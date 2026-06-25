/// Shared player-visibility tile-map mutation helpers (Refs #3710).
///
/// Centralizes the two idioms that were previously copy/pasted across the naval
/// and fog visibility paths: "set these tiles fully visible for a player" and
/// "downgrade fully-visible tiles to fogged for a player". Keeping them here
/// gives one source of truth for the [VisibilityLevel] strings written into the
/// per-player `Map<tileKey, VisibilityLevel.name>` maps and preserves the exact
/// set/downgrade asymmetry the fog ownership transfer relies on. None of these
/// are surfaced through the package barrel; they stay package-internal.
library;

import 'player_view.dart' show VisibilityLevel;

/// Sets every key in [tileKeys] to [VisibilityLevel.fullyVisible] inside the
/// single-player visibility map [playerVisibility] (mutated in place).
void setTilesFullyVisible(
  Map<String, String> playerVisibility,
  Iterable<String> tileKeys,
) {
  for (final tileKey in tileKeys) {
    playerVisibility[tileKey] = VisibilityLevel.fullyVisible.name;
  }
}

/// Downgrades only the keys in [tileKeys] that are currently
/// [VisibilityLevel.fullyVisible] to [VisibilityLevel.fogged] inside
/// [playerVisibility] (mutated in place). Unknown/other levels are left
/// untouched. Returns the number of tiles downgraded.
int downgradeFullyVisibleToFogged(
  Map<String, String> playerVisibility,
  Iterable<String> tileKeys,
) {
  var downgraded = 0;
  for (final tileKey in tileKeys) {
    if (playerVisibility[tileKey] == VisibilityLevel.fullyVisible.name) {
      playerVisibility[tileKey] = VisibilityLevel.fogged.name;
      downgraded++;
    }
  }
  return downgraded;
}

/// Returns a new outer visibility-by-player map with [tileKeys] set to
/// [VisibilityLevel.fullyVisible] for [playerId]. The player's inner map is
/// copied before mutation so [visibilityByTile] is never modified. When
/// [tileKeys] is empty the original [visibilityByTile] reference is returned
/// unchanged.
Map<String, Map<String, String>> setTilesFullyVisibleForPlayer(
  Map<String, Map<String, String>> visibilityByTile,
  String playerId,
  Iterable<String> tileKeys,
) {
  if (tileKeys.isEmpty) return visibilityByTile;
  final playerVisibility = Map<String, String>.from(
    visibilityByTile[playerId] ?? const <String, String>{},
  );
  setTilesFullyVisible(playerVisibility, tileKeys);
  return Map<String, Map<String, String>>.from(visibilityByTile)
    ..[playerId] = playerVisibility;
}
